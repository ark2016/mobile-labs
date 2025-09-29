#!/usr/bin/env python3

import asyncio
import websockets
import json
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global state
clients = set()
switch_state = 1  # Default ON
slider_value = 0  # Default 0

async def handle_client(websocket):
    clients.add(websocket)
    logger.info(f"Client {websocket.remote_address} connected. Total clients: {len(clients)}")

    # Send initial state to newly connected client
    try:
        await websocket.send(json.dumps({
            'type': 'switch_state',
            'value': switch_state
        }))

        if switch_state == 1:
            await websocket.send(json.dumps({
                'type': 'slider_value',
                'value': slider_value
            }))
    except websockets.exceptions.ConnectionClosed:
        pass

    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                await process_message(websocket, data)
            except json.JSONDecodeError:
                logger.error(f"Invalid JSON from {websocket.remote_address}: {message}")
                await websocket.send(json.dumps({
                    "type": "error",
                    "message": "Invalid JSON format"
                }))
    except websockets.exceptions.ConnectionClosed:
        logger.info(f"Client disconnected: {websocket.remote_address}")
    finally:
        clients.remove(websocket)

async def process_message(websocket, data):
    global switch_state, slider_value

    message_type = data.get('type')

    if message_type == 'get_switch':
        await websocket.send(json.dumps({
            'type': 'switch_state',
            'value': switch_state
        }))

    elif message_type == 'set_switch':
        switch_state = data.get('value', 0)
        logger.info(f"Switch state changed to: {switch_state}")

        # Broadcast switch state to all clients
        response = {
            'type': 'switch_state',
            'value': switch_state
        }

        disconnected_clients = []
        for client in clients:
            try:
                await client.send(json.dumps(response))
            except websockets.exceptions.ConnectionClosed:
                disconnected_clients.append(client)

        # If switch turned ON, send current slider value from server
        if switch_state == 1:
            slider_response = {
                'type': 'slider_value',
                'value': slider_value
            }

            for client in clients:
                try:
                    await client.send(json.dumps(slider_response))
                except websockets.exceptions.ConnectionClosed:
                    disconnected_clients.append(client)

        for client in disconnected_clients:
            clients.discard(client)

    elif message_type == 'get_slider':
        await websocket.send(json.dumps({
            'type': 'slider_value',
            'value': slider_value
        }))

    elif message_type == 'set_slider':
        # Only update slider if switch is ON
        if switch_state == 1:
            slider_value = max(0, min(100, data.get('value', 0)))  # Clamp between 0-100
            logger.info(f"Slider value changed to: {slider_value}")

            # Broadcast slider value to all clients
            response = {
                'type': 'slider_value',
                'value': slider_value
            }

            disconnected_clients = []
            for client in clients:
                try:
                    await client.send(json.dumps(response))
                except websockets.exceptions.ConnectionClosed:
                    disconnected_clients.append(client)

            for client in disconnected_clients:
                clients.discard(client)
        else:
            logger.info(f"Slider update ignored - switch is OFF")
    else:
        logger.warning(f"Unknown message type: {message_type}")

async def main():
    server = await websockets.serve(
        handle_client,
        "0.0.0.0",  # Listen on all interfaces
        8765,       # Port
        ping_interval=20,
        ping_timeout=10
    )

    logger.info("WebSocket Remote Control Server started on port 8765")
    logger.info("Waiting for connections...")

    await server.wait_closed()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Server stopped")