#!/usr/bin/env zsh
# fallback para bash se zsh não estiver disponível
if [ -z "$ZSH_VERSION" ]; then
    if command -v zsh >/dev/null 2>&1; then
        exec zsh "$0" "$@"
    fi
fi

# Criar diretórios se não existirem
#mkdir -p templates
#mkdir -p static

# Verificar se as dependências estão instaladas
if [ ! -d ".venv" ]; then
    echo "Criando ambiente virtual..."
    python3 -m venv .venv
fi

if [ -n "$ZSH_VERSION" ]; then
    source .venv/bin/activate
else
    source .venv/bin/activate
fi

pip install -r requirements.txt

# Iniciar a aplicação
uvicorn main:app --host 0.0.0.0 --port 8000 --reload