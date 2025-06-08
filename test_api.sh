#!/bin/bash

# Configuração
API_URL="http://127.0.0.1:8000"

echo "=== Teste da API REST com FastAPI ==="
echo ""

# Teste 1: Enviar uma lista vazia (deve retornar 200)
echo "Teste 1: Enviando lista vazia"
curl -s -o /dev/null -w "Status: %{http_code}\n" -X POST \
  -H "Content-Type: application/json" \
  -d "[]" \
  ${API_URL}/mensagens
echo ""

# Teste 2: Enviar mensagens válidas
echo "Teste 2: Enviando mensagens válidas"
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '[
    {
        "codigo": "1001",
        "mensagem": "Solicitação de teste 1",
        "dataCadastro": "2023-05-10T08:30:00Z",
        "dataAtualizacao": "2023-05-10T10:15:00Z",
        "status": "Pendente"
    },
    {
        "codigo": "1002",
        "mensagem": "Solicitação de teste 2",
        "dataCadastro": "2023-05-11T14:20:00Z",
        "dataAtualizacao": "2023-05-11T16:45:00Z",
        "status": "Impedida"
    }
  ]' \
  ${API_URL}/mensagens
echo ""

# Esperar um pouco para o processamento
sleep 1

# Teste 3: Verificar mensagens armazenadas
echo "Teste 3: Verificando mensagens armazenadas"
curl -s ${API_URL}/mensagens | jq
echo ""

# Teste 4: Enviar mensagem para ser excluída (status=Confirmada)
echo "Teste 4: Enviando mensagem com status Confirmada"
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '[
    {
        "codigo": "1001",
        "mensagem": "Esta mensagem deve ser excluída",
        "status": "Confirmada"
    }
  ]' \
  ${API_URL}/mensagens
echo ""

# Esperar um pouco para o processamento
sleep 1

# Teste 5: Verificar que a mensagem foi excluída
echo "Teste 5: Verificando que a mensagem com status Confirmada foi excluída"
curl -s ${API_URL}/mensagens | jq
echo ""

# Teste 6: Enviar mensagens com codificação diferente (simulando não-UTF8)
echo "Teste 6: Enviando mensagem com codificação diferente"
echo '[{"codigo": "1003", "mensagem": "Mensagem com caracteres especiais: áéíóúçãõ"}]' > /tmp/msg_latin1.json
iconv -f UTF-8 -t ISO-8859-1 /tmp/msg_latin1.json > /tmp/msg_converted.json

curl -s -X POST \
  -H "Content-Type: application/json" \
  --data-binary @/tmp/msg_converted.json \
  ${API_URL}/mensagens
echo ""

# Esperar um pouco para o processamento
sleep 1

# Teste 7: Verificar se a mensagem com codificação diferente foi processada
echo "Teste 7: Verificando processamento de mensagem com codificação diferente"
curl -s ${API_URL}/mensagens | jq
echo ""

# Teste 8: Excluir todas as mensagens
echo "Teste 8: Excluindo todas as mensagens"
curl -s -X DELETE ${API_URL}/mensagens | jq
echo ""

# Teste 9: Verificar que todas as mensagens foram excluídas
echo "Teste 9: Verificando que todas as mensagens foram excluídas"
curl -s ${API_URL}/mensagens | jq
echo ""

echo "=== Testes concluídos ==="
