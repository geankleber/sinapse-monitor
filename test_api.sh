#!/bin/bash

# Configuração
API_URL="http://127.0.0.1:8000"

function teste1() {
  echo "Teste 1: Enviando lista vazia"
  curl -s -o /dev/null -w "Status: %{http_code}\n" -X POST \
    -H "Content-Type: application/json" \
    -d "[]" \
    ${API_URL}/mensagens
  echo ""
}

function teste2() {
  echo "Teste 2: Enviando mensagens válidas"
  curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{
      "mensagens": [
        {"codigo": "1001", "mensagem": "Solicitação de teste 1", "dataCadastro": "2023-05-10T08:30:00Z", "dataAtualizacao": "2023-05-10T10:15:00Z", "status": "Pendente"},
        {"codigo": "1002", "mensagem": "Solicitação de teste 2", "dataCadastro": "2023-05-11T14:20:00Z", "dataAtualizacao": "2023-05-11T16:45:00Z", "status": "Impedida"}
      ]
    }' \
    ${API_URL}/mensagens
  echo ""
}

function teste3() {
  echo "Teste 3: Verificando mensagens armazenadas"
  curl -s ${API_URL}/mensagens | jq
  echo ""
}

function teste4() {
  echo "Teste 4: Enviando mensagem com status Confirmada"
  curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '[{"codigo": "1001", "mensagem": "Esta mensagem deve ser excluída", "status": "Confirmada"}]' \
    ${API_URL}/mensagens
  echo ""
}

function teste5() {
  echo "Teste 5: Verificando que a mensagem com status Confirmada foi excluída"
  curl -s ${API_URL}/mensagens | jq
  echo ""
}

function teste6() {
  echo "Teste 6: Enviando mensagem com codificação diferente"
  echo '[{"codigo": "1003", "mensagem": "Mensagem com caracteres especiais: áéíóúçãõ"}]' > /tmp/msg_latin1.json
  iconv -f UTF-8 -t ISO-8859-1 /tmp/msg_latin1.json > /tmp/msg_converted.json
  curl -s -X POST \
    -H "Content-Type: application/json" \
    --data-binary @/tmp/msg_converted.json \
    ${API_URL}/mensagens
  echo ""
}

function teste7() {
  echo "Teste 7: Verificando processamento de mensagem com codificação diferente"
  curl -s ${API_URL}/mensagens | jq
  echo ""
}

function teste8() {
  echo "Teste 8: Excluindo todas as mensagens"
  curl -s -X DELETE ${API_URL}/mensagens | jq
  echo ""
}

function teste9() {
  echo "Teste 9: Verificando que todas as mensagens foram excluídas"
  curl -s ${API_URL}/mensagens | jq
  echo ""
}

while true; do
  echo "\n=== Menu de Testes da API REST com FastAPI ==="
  echo "1) Teste 1: Enviar lista vazia"
  echo "2) Teste 2: Enviar mensagens válidas"
  echo "3) Teste 3: Verificar mensagens armazenadas"
  echo "4) Teste 4: Enviar mensagem com status Confirmada"
  echo "5) Teste 5: Verificar que a mensagem Confirmada foi excluída"
  echo "6) Teste 6: Enviar mensagem com codificação diferente"
  echo "7) Teste 7: Verificar mensagem com codificação diferente"
  echo "8) Teste 8: Excluir todas as mensagens"
  echo "9) Teste 9: Verificar que todas as mensagens foram excluídas"
  echo "0) Sair"
  read -p "Escolha uma opção: " opcao
  case $opcao in
    1) teste1 ;;
    2) teste2 ;;
    3) teste3 ;;
    4) teste4 ;;
    5) teste5 ;;
    6) teste6 ;;
    7) teste7 ;;
    8) teste8 ;;
    9) teste9 ;;
    0) echo "Encerrando script."; exit 0 ;;
    *) echo "Opção inválida." ;;
  esac
done
