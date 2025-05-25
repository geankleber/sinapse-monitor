#!/bin/bash

# Criar diretórios se não existirem
mkdir -p templates
mkdir -p static

# Verificar se as dependências estão instaladas
pip install -r requirements.txt

# Iniciar a aplicação
uvicorn main:app --host 0.0.0.0 --port 8000 --reload