"""
Entrypoint do backend Lead Machine Lite em modo DRY RUN com subscription Claude Code.

Substitui chamadas do SDK anthropic por invocações ao binário `claude`
usando a subscription do usuário (em vez de exigir ANTHROPIC_API_KEY paga).

Uso:
    cd backend
    PYTHONPATH=.:../scripts python -m uvicorn server_with_shim:app --port 18792
"""
from __future__ import annotations

import logging
import os
import sys
from pathlib import Path

# Garantir que backend está no PYTHONPATH
_BACKEND_DIR = Path(__file__).resolve().parent.parent / "backend"
sys.path.insert(0, str(_BACKEND_DIR))

# Forçar ANTHROPIC_API_KEY a algo não-vazio pra server inicializar o client
# (vamos sobrescrever logo abaixo de qualquer forma — setdefault não funciona
# quando a var existe mas está vazia)
if not os.environ.get("ANTHROPIC_API_KEY"):
    os.environ["ANTHROPIC_API_KEY"] = "shim-no-real-key"

import anthropic  # noqa: E402

# Patch ANTES de importar server (que cria o client global)
_real_anthropic_init = anthropic.Anthropic.__init__


def _shim_init(self, *args, **kwargs):
    """Pula validação real — não vamos chamar a API."""
    kwargs.setdefault("api_key", "shim-no-real-key")
    _real_anthropic_init(self, *args, **kwargs)


anthropic.Anthropic.__init__ = _shim_init

import server  # noqa: E402

from dry_run_shim import install_shim  # noqa: E402

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
log = logging.getLogger("server-with-shim")

if server.anthropic_client is None:
    # Server detectou env vazio antes do nosso patch — recriar
    server.anthropic_client = anthropic.Anthropic(api_key="shim-no-real-key")

install_shim(server.anthropic_client)

log.warning("DRY RUN MODE — backend usando Claude Code subscription via shim")

app = server.app
