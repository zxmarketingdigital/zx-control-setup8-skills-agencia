"""
Shim que substitui `anthropic_client.messages.create` por invocações ao
binário `claude` (CLI Claude Code) usando a subscription do usuário.

Uso (dry run sem API key Anthropic):
    cd backend
    PYTHONPATH=. python -m uvicorn scripts.server_with_shim:app ...

NÃO usar em produção — overhead alto (5-15s por chamada via CLI vs 1-3s via SDK).
"""
from __future__ import annotations

import json
import logging
import re
import subprocess
from typing import Any

log = logging.getLogger("dry-run-shim")


# ─────────────────────────────────────────────────────────────
# Fake Message objects mimicking anthropic SDK shape
# ─────────────────────────────────────────────────────────────


class FakeBlock:
    """Mimics anthropic.types.TextBlock or ToolUseBlock."""

    def __init__(self, text: str | None = None, tool_use: dict | None = None):
        if tool_use is not None:
            self.type = "tool_use"
            self.name = tool_use["name"]
            self.input = tool_use["input"]
            self.id = tool_use.get("id", "shim_tu_1")
            self.text = None
        else:
            self.type = "text"
            self.text = text or ""
            self.name = None
            self.input = None


class FakeMessage:
    """Mimics anthropic.types.Message."""

    def __init__(self, blocks: list[FakeBlock]):
        self.content = blocks
        self.role = "assistant"
        self.stop_reason = "end_turn"
        self.model = "claude-code-subscription"


# ─────────────────────────────────────────────────────────────
# Prompt builder
# ─────────────────────────────────────────────────────────────


def _flatten_message_content(content: Any) -> str:
    """Anthropic SDK accepts str or list of blocks. Flatten to text."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for b in content:
            if isinstance(b, dict):
                if b.get("type") == "text":
                    parts.append(b.get("text", ""))
                elif b.get("type") == "tool_result":
                    parts.append(str(b.get("content", "")))
            else:
                parts.append(str(b))
        return "\n".join(parts)
    return str(content)


def _build_prompt(
    system: str,
    messages: list[dict],
    tools: list[dict] | None,
    tool_choice: dict | None,
) -> tuple[str, bool]:
    """Returns (prompt, expects_tool_use)."""
    parts: list[str] = []
    if system:
        parts.append(f"=== SYSTEM ===\n{system}\n")

    for m in messages:
        role = m["role"].upper()
        content = _flatten_message_content(m.get("content", ""))
        parts.append(f"=== {role} ===\n{content}")

    expects_tool = bool(tools and tool_choice and tool_choice.get("type") == "tool")
    if expects_tool:
        tool = tools[0]
        for t in tools:
            if t["name"] == tool_choice.get("name"):
                tool = t
                break
        parts.append("\n=== INSTRUÇÃO FINAL (shim subscription) ===")
        parts.append(
            f"Você DEVE responder APENAS com um JSON válido (sem markdown, "
            f"sem ```json wrapping, sem texto antes/depois) representando os "
            f"argumentos da função `{tool['name']}` com este schema:"
        )
        parts.append(json.dumps(tool["input_schema"], indent=2, ensure_ascii=False))
        parts.append(f"\nDescrição da função: {tool.get('description', '')}")
        parts.append("\nRetorne SOMENTE o JSON object, sem nada antes ou depois.")

    # Detect prefill pattern (last message is assistant with partial content)
    if messages and messages[-1]["role"] == "assistant":
        # Prefill — tell Claude to continue from this prefix
        prefix = _flatten_message_content(messages[-1].get("content", ""))
        if prefix.strip() == "{":
            parts.append(
                "\n=== INSTRUÇÃO ===\nSua resposta DEVE começar com '{' e ser "
                "um JSON válido completo (sem markdown, sem texto antes/depois)."
            )

    return "\n".join(parts), expects_tool


# ─────────────────────────────────────────────────────────────
# Claude CLI invocation
# ─────────────────────────────────────────────────────────────

CLAUDE_BIN = "claude"
TIMEOUT_S = 180


def _call_claude_cli(prompt: str) -> str:
    try:
        proc = subprocess.run(
            [CLAUDE_BIN, "-p", prompt],
            capture_output=True,
            text=True,
            timeout=TIMEOUT_S,
        )
    except subprocess.TimeoutExpired:
        raise RuntimeError(f"shim: claude CLI timeout após {TIMEOUT_S}s")
    if proc.returncode != 0:
        raise RuntimeError(
            f"shim: claude CLI failed (exit={proc.returncode}): {proc.stderr[:300]}"
        )
    out = proc.stdout.strip()
    if not out:
        raise RuntimeError("shim: claude CLI returned empty stdout")
    return out


def _extract_json(text: str) -> dict:
    """Pull first JSON object out of free-form text."""
    # Strip markdown fences if Claude wrapped despite instructions
    cleaned = re.sub(r"^```(?:json)?\s*", "", text.strip())
    cleaned = re.sub(r"\s*```$", "", cleaned)
    m = re.search(r"\{[\s\S]*\}", cleaned)
    if not m:
        raise RuntimeError(f"shim: no JSON found in claude output: {text[:300]}")
    return json.loads(m.group(0))


# ─────────────────────────────────────────────────────────────
# Drop-in replacement for anthropic_client.messages.create
# ─────────────────────────────────────────────────────────────


def shim_messages_create(
    model: str = "",
    max_tokens: int = 1024,
    system: str = "",
    messages: list[dict] | None = None,
    tools: list[dict] | None = None,
    tool_choice: dict | None = None,
    **kwargs: Any,
) -> FakeMessage:
    messages = messages or []
    prompt, expects_tool = _build_prompt(system, messages, tools, tool_choice)

    log.info(
        "shim: calling claude -p (prompt=%dch, expects_tool=%s, has_prefill=%s)",
        len(prompt),
        expects_tool,
        bool(messages and messages[-1]["role"] == "assistant"),
    )

    raw = _call_claude_cli(prompt)

    if expects_tool:
        try:
            payload = _extract_json(raw)
        except (RuntimeError, json.JSONDecodeError) as e:
            log.error("shim: tool-use JSON parse failed: %s\nRAW=%s", e, raw[:500])
            raise
        tool_name = (tool_choice or {}).get("name") or tools[0]["name"]
        return FakeMessage([FakeBlock(tool_use={"name": tool_name, "input": payload})])

    # Text response — if prefill {, the backend expects to concat "{" + raw,
    # so raw should already be JSON-shaped without the leading brace.
    has_prefill = bool(messages and messages[-1]["role"] == "assistant")
    if has_prefill:
        prefix = _flatten_message_content(messages[-1].get("content", "")).strip()
        if prefix == "{" and raw.lstrip().startswith("{"):
            # Strip the leading { so backend's "{" + raw produces valid JSON
            raw = raw.lstrip()[1:]

    return FakeMessage([FakeBlock(text=raw)])


# ─────────────────────────────────────────────────────────────
# Monkey-patch helper
# ─────────────────────────────────────────────────────────────


def install_shim(anthropic_client_obj) -> None:
    """Patches anthropic_client.messages.create on a given Anthropic instance."""

    class _MessagesProxy:
        def create(self, *args, **kwargs):
            return shim_messages_create(*args, **kwargs)

    anthropic_client_obj.messages = _MessagesProxy()
    log.warning(
        "==== DRY-RUN SHIM ATIVO — chamadas Anthropic redirecionadas pra `claude -p` ===="
    )
