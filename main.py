from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Request, Response
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import json
from datetime import datetime
import pytz
import asyncio

app = FastAPI()

# Habilitar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Diretório de templates e arquivos estáticos
templates = Jinja2Templates(directory="templates")
app.mount("/static", StaticFiles(directory="static"), name="static")

# Dicionário para armazenar mensagens em memória
mensagens: Dict[str, Dict[str, Any]] = {}

# Gerenciador de conexões WebSocket
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()

# Página inicial
@app.get("/", response_class=HTMLResponse)
async def get_index(request: Request):
    # Contar mensagens por status
    pendentes = sum(1 for msg in mensagens.values() if msg.get('status') == 'Pendente')
    impedidas = sum(1 for msg in mensagens.values() if msg.get('status') == 'Impedida')
    confirmadas = sum(1 for msg in mensagens.values() if msg.get('status') == 'Confirmada')
    
    return templates.TemplateResponse("index.html", {
        "request": request, 
        "pendentes": pendentes,
        "impedidas": impedidas,
        "confirmadas": confirmadas,
        "mensagens": list(mensagens.values())  # Passa a lista de mensagens para o template
    })

# Função para remover mensagem confirmada depois de um minuto
async def remover_confirmada_depois_de_um_minuto(codigo: str):
    await asyncio.sleep(60)
    msg = mensagens.get(codigo)
    if msg and msg.get('status') == 'Confirmada':
        del mensagens[codigo]
        # Atualiza contadores e notifica clientes
        pendentes = sum(1 for msg in mensagens.values() if msg.get('status') == 'Pendente')
        impedidas = sum(1 for msg in mensagens.values() if msg.get('status') == 'Impedida')
        confirmadas = sum(1 for msg in mensagens.values() if msg.get('status') == 'Confirmada')
        await manager.broadcast(json.dumps({
            "pendentes": pendentes,
            "impedidas": impedidas,
            "confirmadas": confirmadas,
            "mensagens": list(mensagens.values())
        }))

# Endpoint para receber as mensagens via POST
@app.post("/mensagens")
async def processar_mensagens(request: Request):
    try:
        # Recebendo e decodificando o body da requisição
        body = await request.body()
        try:
            data = json.loads(body.decode('utf-8'))
        except UnicodeDecodeError:
            # Tentando outras codificações se UTF-8 falhar
            for encoding in ['latin-1', 'iso-8859-1', 'cp1252']:
                try:
                    data = json.loads(body.decode(encoding))
                    break
                except (UnicodeDecodeError, json.JSONDecodeError):
                    continue
        
        # Verificar se é uma lista
        if not isinstance(data, list): # type: ignore
            return Response(status_code=400, content="O payload deve ser uma lista")
        
        # Se a lista estiver vazia, retornar 200 OK
        if len(data) == 0:
            return Response(status_code=200)
        
        # Processar mensagens da lista
        for msg in data:
            print(f"Mensagem recebida via POST: {msg}")  # Adicionado print no console do servidor
            # Verificar se a mensagem tem o campo 'codigo'
            if 'codigo' not in msg:
                continue
            
            codigo = msg['codigo']
            
            # Converter datas se existirem
            for data_campo in ['dataAtualizacao', 'dataCadastro']:
                if data_campo in msg and msg[data_campo]:
                    try:
                        # Converter de ISO 8601 para o formato especificado
                        data_iso = datetime.fromisoformat(msg[data_campo].replace('Z', '+00:00'))
                        # Aplicar timezone de São Paulo
                        sp_timezone = pytz.timezone("America/Sao_Paulo")
                        data_sp = data_iso.astimezone(sp_timezone)
                        # Formatar conforme especificado
                        msg[data_campo] = data_sp.strftime("%d/%m/%Y - %H:%M:%S")
                    except (ValueError, TypeError):
                        # Manter o valor original se a conversão falhar
                        pass
            
            # Verificar se a mensagem já existe e tem status especial
            if codigo in mensagens:
                # Se a mensagem tiver status "Finalizada", exclui do dicionário
                if msg.get('status') == 'Finalizada':
                    del mensagens[codigo]
                else:
                    # Adicionar ou atualizar mensagem no dicionário
                    mensagens[codigo] = msg
            else:
                # Adicionar nova mensagem ao dicionário
                mensagens[codigo] = msg

            # Se status for "Confirmada", agenda remoção em 1 minuto
            if msg.get('status') == 'Confirmada':
                asyncio.create_task(remover_confirmada_depois_de_um_minuto(codigo))
        
        # Contar mensagens por status
        pendentes = sum(1 for msg in mensagens.values() if msg.get('status') == 'Pendente')
        impedidas = sum(1 for msg in mensagens.values() if msg.get('status') == 'Impedida')
        confirmadas = sum(1 for msg in mensagens.values() if msg.get('status') == 'Confirmada')
        
        # Notificar clientes WebSocket sobre a atualização
        await manager.broadcast(json.dumps({
            "pendentes": pendentes,
            "impedidas": impedidas,
            "confirmadas": confirmadas
        }))
        
        return Response(status_code=200)
    except Exception as e:
        return Response(status_code=500, content=str(e))

# Endpoint para excluir todas as mensagens
@app.delete("/mensagens")
async def excluir_mensagens():
    mensagens.clear()
    # Notificar clientes WebSocket sobre a atualização
    await manager.broadcast(json.dumps({
        "pendentes": 0,
        "impedidas": 0,
        "confirmadas": 0
    }))
    return {"message": "Todas as mensagens foram excluídas"}

# Endpoint WebSocket
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # Manter a conexão aberta
            data = await websocket.receive_text()
            # Você pode processar mensagens recebidas do cliente se necessário
    except WebSocketDisconnect:
        manager.disconnect(websocket)

# Endpoint para obter todas as mensagens (útil para debug)
@app.get("/mensagens")
async def get_mensagens():
    return mensagens

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)