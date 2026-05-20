"""
check_prerequisites.py — Validador inicial do Setup 8: Skills da Agência IA + Lead Machine Lite no seu Mac

Roda ANTES de qualquer setup_*.py. Bloqueia avanço se ambiente do aluno
não atende os pré-requisitos.

Compatível Python 3.9+ (alunos com macOS Monterey têm 3.9 de fábrica).
NUNCA usar type unions com `|` — usar Optional/List do typing.
"""

from __future__ import annotations

import json
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Optional, Tuple


CONFIG_PATH = Path.home() / ".operacao-ia" / "config" / "config.json"
SETUP_NUMBER = 8
REQUIRED_PHASE = 7
MIN_PYTHON = (3, 9)


def _check(label: str, ok: bool, detail: str = "") -> bool:
    icon = "✅" if ok else "❌"
    print(f"  {icon} {label}{(': ' + detail) if detail else ''}")
    return ok


def check_python_version() -> bool:
    v = sys.version_info
    ok = v >= MIN_PYTHON
    return _check(
        f"Python {MIN_PYTHON[0]}.{MIN_PYTHON[1]}+",
        ok,
        f"{v.major}.{v.minor}.{v.micro}",
    )


def check_os() -> Tuple[bool, str]:
    sysname = platform.system()
    if sysname == "Darwin":
        return True, "macOS"
    if sysname == "Linux":
        return True, "Linux (LaunchAgents serão pulados)"
    if sysname == "Windows":
        return True, "Windows (LaunchAgents serão pulados)"
    return False, sysname


def check_phase_completed() -> bool:
    if REQUIRED_PHASE == 0:
        return _check("Setup anterior", True, "não exige")
    if not CONFIG_PATH.exists():
        return _check(
            f"Setup {REQUIRED_PHASE} concluído",
            False,
            f"{CONFIG_PATH} não existe. Conclua Setup {REQUIRED_PHASE} antes.",
        )
    try:
        cfg = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as e:
        return _check(f"Setup {REQUIRED_PHASE} concluído", False, f"config.json inválido: {e}")
    phase = int(cfg.get("phase_completed", 0))
    ok = phase >= REQUIRED_PHASE
    return _check(
        f"Setup {REQUIRED_PHASE} concluído",
        ok,
        f"phase_completed={phase}",
    )


def check_command(name: str, label: Optional[str] = None) -> bool:
    label = label or name
    path = shutil.which(name)
    return _check(label, path is not None, path or "não encontrado")


def check_dir(path: Path, label: Optional[str] = None) -> bool:
    label = label or str(path)
    return _check(label, path.exists() and path.is_dir(), str(path))


def main() -> int:
    print(f"\n🔍 Validando pré-requisitos do Setup {SETUP_NUMBER}: Skills da Agência IA + Lead Machine Lite no seu Mac\n")

    checks = []

    # Sistema operacional
    os_ok, os_detail = check_os()
    _check("Sistema operacional suportado", os_ok, os_detail)
    checks.append(os_ok)

    # Python
    checks.append(check_python_version())

    # Setup anterior
    checks.append(check_phase_completed())

    # Comandos necessários
    checks.append(check_command("git"))
    checks.append(check_command("python3"))
    checks.append(check_command("claude"))

    # Diretórios base
    base = Path.home() / ".operacao-ia"
    if not base.exists():
        base.mkdir(parents=True)
        print(f"  📁 Criado: {base}")
    sub = base / "config"
    if not sub.exists():
        sub.mkdir(parents=True)
        print(f"  📁 Criado: {sub}")
    sub = base / "scripts"
    if not sub.exists():
        sub.mkdir(parents=True)
        print(f"  📁 Criado: {sub}")
    sub = base / "leads"
    if not sub.exists():
        sub.mkdir(parents=True)
        print(f"  📁 Criado: {sub}")

    # Resumo
    passed = sum(1 for c in checks if c)
    total = len(checks)
    print(f"\n📊 {passed}/{total} checks passaram\n")

    if passed < total:
        print(f"❌ Pré-requisitos não atendidos. Conclua Setup {REQUIRED_PHASE} ou instale dependências antes.")
        return 1

    print(f"✅ Tudo pronto. Setup {SETUP_NUMBER} pode começar.\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())