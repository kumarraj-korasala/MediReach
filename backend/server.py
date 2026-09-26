import json
from typing import Dict
from fastapi import FastAPI, WebSocket, WebSocketDisconnect

app = FastAPI(title="Miracle Communication Backend")

# Active WebSocket connections dictionary: key = user_id, value = WebSocket connection
active_connections: Dict[str, WebSocket] = {}

@app.get("/")
def read_root():
    return {
        "status": "online",
        "service": "Miracle WebRTC & Messaging Signaling Server",
        "active_users": list(active_connections.keys())
    }

@app.websocket("/ws/calls")
async def websocket_endpoint(websocket: WebSocket, token: str):
    """
    WebSocket endpoint for WebRTC signaling, chat messages, file transfer, and connection monitoring.
    """
    await websocket.accept()
    user_id = token
    active_connections[user_id] = websocket
    print(f"[CONNECTED] User {user_id} joined.")

    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)

            message_type = message.get("type")

            # Handle connection heartbeat
            if message_type == "ping":
                await websocket.send_text(json.dumps({"type": "pong"}))
                continue

            target_id = message.get("to")
            print(f"[MESSAGE] From {user_id} -> To {target_id} | Type: {message_type}")

            if target_id and target_id in active_connections:
                target_ws = active_connections[target_id]
                message["from"] = user_id
                await target_ws.send_text(json.dumps(message))
            else:
                print(f"[OFFLINE] Target user {target_id} is not connected.")
                await websocket.send_text(json.dumps({
                    "type": "error",
                    "message": f"User {target_id} is currently offline."
                }))

    except WebSocketDisconnect:
        if user_id in active_connections:
            del active_connections[user_id]
            print(f"[DISCONNECTED] User {user_id} disconnected.")
    except Exception as e:
        print(f"[ERROR] Connection error for {user_id}: {e}")
        if user_id in active_connections:
            del active_connections[user_id]

# Run command:
# uvicorn server:app --host 0.0.0.0 --port 8000
