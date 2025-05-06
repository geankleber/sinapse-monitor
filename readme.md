# API REST com FastAPI para Gerenciamento de Mensagens

Este projeto implementa uma API REST usando FastAPI para receber e gerenciar mensagens, com uma interface web que atualiza em tempo real via WebSockets.

## Funcionalidades

- API REST com CORS habilitado
- Recebimento de mensagens via POST
- Gerenciamento de mensagens por status: Pendente, Impedida, Confirmada, Finalizada
- Conversão automática de formatos de data
- Gerenciamento de mensagens em memória
- Página web com atualização em tempo real via WebSockets
- Endpoint para excluir todas as mensagens

## Requisitos

- Python 3.9+
- Pacotes listados em `requirements.txt`

## Estrutura do Projeto

```
.
├── main.py              # Código principal da aplicação
├── requirements.txt     # Dependências do projeto
├── templates/           # Templates HTML
│   └── index.html       # Página principal
├── static/              # Arquivos estáticos (CSS, JS, etc.)
├── test_api.sh          # Script para testar a API
├── Dockerfile           # Configuração para Docker
└── start.sh             # Script para iniciar a aplicação
```

## Como Executar

### Método 1: Usando Python diretamente

1. Crie um ambiente virtual (opcional, mas recomendado):
   ```bash
   python -m venv venv
   source venv/bin/activate  # No Windows: venv\Scripts\activate
   ```

2. Instale as dependências:
   ```bash
   pip install -r requirements.txt
   ```

3. Inicie a aplicação:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

   Ou use o script de inicialização:
   ```bash
   chmod +x start.sh
   ./start.sh
   ```

### Método 2: Usando Docker

1. Construa a imagem Docker:
   ```bash
   docker build -t api-mensagens .
   ```

2. Execute o contêiner:
   ```bash
   docker run -p 8000:8000 api-mensagens
   ```

## Testando a API

1. Torne o script de teste executável:
   ```bash
   chmod +x test_api.sh
   ```

2. Execute os testes:
   ```bash
   ./test_api.sh
   ```

## Endpoints da API

- `GET /`: Página inicial com tabela de solicitações
- `POST /mensagens`: Receber mensagens
- `GET /mensagens`: Listar todas as mensagens armazenadas
- `DELETE /mensagens`: Excluir todas as mensagens
- `WebSocket /ws`: Conexão WebSocket para atualizações em tempo real

## Formato das Mensagens

As mensagens devem ser enviadas como uma lista de objetos JSON, onde cada objeto deve conter pelo menos o campo `codigo`. Exemplo:

```json
[
  {
    "codigo": "1001",
    "descricao": "Exemplo de solicitação",
    "dataCadastro": "2023-05-10T08:30:00Z",
    "dataAtualizacao": "2023-05-10T10:15:00Z",
    "status": "Pendente"
  }
]
```

Campos especiais:
- `codigo`: Identificador único da mensagem (obrigatório)
- `dataCadastro`: Data de cadastro no formato ISO 8601 (será convertida)
- `dataAtualizacao`: Data de atualização no formato ISO 8601 (será convertida)
- `status`: Status da mensagem, pode ser:
  - `Pendente`: Destacada em amarelo na interface
  - `Impedida`: Destacada em vermelho na interface
  - `Confirmada`: Destacada em verde na interface
  - `Finalizada`: Mensagem será excluída do sistema