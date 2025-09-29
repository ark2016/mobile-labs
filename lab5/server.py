import asyncio
import websockets
import json
import logging

# Настройка логирования
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Глобальное состояние
clients = set()
slider_value = 50  # Начальное значение ползунка

async def handle_client(websocket):
    clients.add(websocket)
    logger.info(f"Новый клиент подключен: {websocket.remote_address}")

    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                await process_message(websocket, data)
            except json.JSONDecodeError:
                logger.error(f"Неверный JSON от {websocket.remote_address}: {message}")
                await websocket.send(json.dumps({
                    "type": "error",
                    "message": "Invalid JSON format"
                }))
    except websockets.exceptions.ConnectionClosed:
        logger.info(f"Клиент отключен: {websocket.remote_address}")
    finally:
        clients.remove(websocket)

async def process_message(websocket, data):
    global slider_value

    message_type = data.get('type')

    if message_type == 'calculate':
        # Вычисление математической операции
        a = data.get('a', 0)
        b = data.get('b', 0)
        operation = data.get('operation', '+')

        try:
            if operation == '+':
                result = a + b
            elif operation == '-':
                result = a - b
            elif operation == '*':
                result = a * b
            elif operation == '/':
                if b == 0:
                    result = float('inf')  # Деление на ноль
                else:
                    result = a / b
            else:
                result = 0

            response = {
                "type": "calculation_result",
                "result": result,
                "operation": operation,
                "a": a,
                "b": b
            }

            await websocket.send(json.dumps(response))
            logger.info(f"Вычисление: {a} {operation} {b} = {result}")

        except Exception as e:
            logger.error(f"Ошибка вычисления: {e}")
            await websocket.send(json.dumps({
                "type": "error",
                "message": "Calculation error"
            }))

    elif message_type == 'slider':
        # Обновление значения ползунка
        new_value = data.get('value', 50)
        slider_value = max(0, min(100, int(new_value)))  # Ограничение 0-100

        # Уведомить всех клиентов об изменении
        response = {
            "type": "slider_update",
            "value": slider_value
        }

        # Отправить всем подключенным клиентам
        disconnected_clients = []
        for client in clients:
            try:
                await client.send(json.dumps(response))
            except websockets.exceptions.ConnectionClosed:
                disconnected_clients.append(client)

        # Удалить отключенных клиентов
        for client in disconnected_clients:
            clients.discard(client)

        logger.info(f"Ползунок обновлен: {slider_value}")

    elif message_type == 'get_slider':
        # Запрос текущего значения ползунка
        response = {
            "type": "slider_value",
            "value": slider_value
        }

        await websocket.send(json.dumps(response))
        logger.info(f"Отправлено текущее значение ползунка: {slider_value}")

async def main():
    server = await websockets.serve(
        handle_client,
        "0.0.0.0",  # Прослушивать все интерфейсы
        8765,       # Порт
        ping_interval=20,
        ping_timeout=10
    )

    logger.info("WebSocket сервер запущен на порту 8765")
    logger.info("Ожидание подключений...")

    await server.wait_closed()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Сервер остановлен")
