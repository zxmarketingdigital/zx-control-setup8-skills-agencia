"""
check_prerequisites.py — Validador inicial do Setup 8: Agentes de Vendas e Captura de Leads (ZX Growth + ZX Lead Machine)

Roda ANTES de qualquer setup_*.py. Bloqueia avanço se as FERRAMENTAS do aluno
(Python, git, claude CLI) faltam. Não exige nenhum setup anterior: cria o
config.json mínimo se não existir e reaproveita o que já estiver válido.

Compatível Python 3.10+ (backend Lead Machine + Pydantic v2 exigem 3.10).
NUNCA usar type unions com `|` — usar Optional/List do typing.
"""

import json
import os
import platform
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import Optional, Tuple


CONFIG_PATH = Path.home() / ".operacao-ia" / "config" / "config.json"
SETUP_NUMBER = 8
MIN_PYTHON = (3, 10)


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


class ConfigBackupError(OSError):
    """Não foi possível guardar cópia de segurança do config; o original NÃO foi tocado."""


def backup_config_copy(path: Path) -> Path:
    """Copia (copy2) o config para <nome>.bak-<AAAAmmdd-HHMMSS>[-N], sem sobrescrever backup existente.

    Confere que o destino existe com o mesmo tamanho. Em falha, o original fica intacto
    e levanta ConfigBackupError (só então o chamador pode recriar o config)."""
    path = Path(path)
    stamp = time.strftime("%Y%m%d-%H%M%S")
    backup = None
    try:
        n = 0
        while backup is None:
            candidate = path.with_name("%s.bak-%s%s" % (path.name, stamp, "-%d" % n if n else ""))
            try:
                # O_EXCL: a criação é atômica; se outro processo pegou o nome, tenta o próximo sufixo.
                fd = os.open(str(candidate), os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            except FileExistsError:
                n += 1
                continue
            backup = candidate
            with os.fdopen(fd, "wb") as dst, open(str(path), "rb") as src:
                shutil.copyfileobj(src, dst)
            os.chmod(str(backup), 0o600)  # backup nunca herda permissao aberta do original
        if not backup.is_file() or backup.stat().st_size != path.stat().st_size:
            raise OSError("cópia de segurança incompleta")
    except OSError as e:
        try:
            if backup is not None and backup.is_file():
                backup.unlink()
        except OSError:
            pass
        msg = (f"Não consegui salvar uma cópia de segurança de {path}: {e}. "
               "Verifique a permissão da pasta e rode de novo.")
        print(f"  ❌ {msg}")
        raise ConfigBackupError(msg) from e
    return backup


def _gravar_config_minimo(exclusivo: bool = False) -> bool:
    """Grava {"phase_completed": 0}. Devolve False se `exclusivo` e outra execução criou o arquivo antes.

    exclusivo=True (config ausente): criação com O_EXCL, que nunca sobrescreve um config criado em
    paralelo por outra execução. exclusivo=False (config inválido já copiado): arquivo temporário
    + os.replace; se config.json for um symlink, o link é substituído e o alvo nunca é tocado, e
    uma falha no meio não deixa o config truncado.
    """
    conteudo = json.dumps({"phase_completed": 0}, indent=2) + "\n"
    if exclusivo:
        try:
            fd = os.open(str(CONFIG_PATH), os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        except FileExistsError:
            return False
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                f.write(conteudo)
        except BaseException:
            try:
                CONFIG_PATH.unlink()
            except OSError:
                pass
            raise
        return True
    tmp = CONFIG_PATH.with_name(f"{CONFIG_PATH.name}.tmp-{os.getpid()}")
    try:
        try:
            tmp.unlink()  # sobra de execucao interrompida
        except FileNotFoundError:
            pass
        with os.fdopen(os.open(str(tmp), os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "w", encoding="utf-8") as f:
            f.write(conteudo)
        os.replace(str(tmp), str(CONFIG_PATH))
    except BaseException:
        try:
            tmp.unlink()
        except OSError:
            pass
        raise
    return True


def ensure_config() -> bool:
    """Garante um config.json mínimo. NUNCA bloqueia: este setup é independente.

    - ausente: cria {"phase_completed": 0} (cria também as pastas base)
    - corrompido: backup config.json.bak-<timestamp> e recria o mínimo
    - existente e válido (instalação anterior de outro setup): reaproveita sem alterar
    """
    try:
        CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
        if not CONFIG_PATH.exists():
            if not _gravar_config_minimo(exclusivo=True):
                try:
                    achado = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
                except (OSError, ValueError, RecursionError) as e:
                    return _check("config.json", False, f"existe mas não é legível ({e}); confira {CONFIG_PATH} (link quebrado?) e rode de novo")
                if not isinstance(achado, dict):
                    return _check("config.json", False, f"existe mas não é um objeto JSON; confira {CONFIG_PATH} e rode de novo")
                return _check("config.json", True, "reaproveitado (criado em paralelo por outra execução)")
            return _check("config.json", True, "criado (instalação nova, sem setup anterior)")
        try:
            cfg = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
            if not isinstance(cfg, dict):
                raise ValueError("config.json não contém um objeto JSON")
        except (json.JSONDecodeError, OSError, ValueError, RecursionError) as e:
            backup = backup_config_copy(CONFIG_PATH)  # ConfigBackupError: original fica intacto
            _gravar_config_minimo()
            return _check("config.json", True, f"estava inválido ({e}); backup em {backup.name} e recriado")
        return _check("config.json", True, f"reaproveitado (phase_completed={cfg.get('phase_completed', 0)})")
    except ConfigBackupError:
        return False  # mensagem já impressa; config original intacto
    except OSError as e:
        print(f"  ❌ Não consegui preparar o config.json ({e}). Verifique a permissão da pasta {CONFIG_PATH.parent} e rode de novo.")
        return False


def check_command(name: str, label: Optional[str] = None) -> bool:
    label = label or name
    path = shutil.which(name)
    return _check(label, path is not None, path or "não encontrado")


def check_dir(path: Path, label: Optional[str] = None) -> bool:
    label = label or str(path)
    return _check(label, path.exists() and path.is_dir(), str(path))


def main() -> int:
    sysname = platform.system()
    print(f"\n🔍 Validando pré-requisitos do Setup {SETUP_NUMBER}: Agentes de Vendas e Captura de Leads (ZX Growth + ZX Lead Machine)")
    print(f"   Sistema: {sysname}\n")

    checks = []

    # Sistema operacional
    os_ok, os_detail = check_os()
    _check("Sistema operacional suportado", os_ok, os_detail)
    checks.append(os_ok)

    # Python ANTES do aviso Bloco B — erro bloqueante geral tem prioridade
    py_ok = check_python_version()
    checks.append(py_ok)

    # Aviso multi-OS só se Python passou (senão é ruído ao lado do erro real)
    if sysname != "Darwin" and py_ok:
        print()
        print("ℹ️  AVISO MULTI-OS:")
        print("   • Bloco A (6 skills da Agência IA — ZX Growth): funciona neste sistema ✅")
        print("   • Bloco B (Lead Machine Lite — ZX Lead Machine): requer macOS (LaunchAgents + cloudflared local)")
        print("   • O install.sh detecta automaticamente e instala APENAS o Bloco A.")

    # Config mínimo (não exige nenhum setup anterior)
    checks.append(ensure_config())

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
        print(f"❌ Pré-requisitos não atendidos. Instale as dependências que faltam e rode de novo.")
        return 1

    print(f"✅ Tudo pronto. Setup {SETUP_NUMBER} pode começar.\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())