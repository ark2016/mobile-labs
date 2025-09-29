import 'dart:io';
import 'dart:convert';

class CalculatorServer {
  static const int port = 8080;
  HttpServer? _server;
  final Set<WebSocket> _clients = {};

  double _numberA = 0;
  double _numberB = 0;
  String _operation = '+';
  double _result = 0;

  Future<void> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      print('=== Calculator WebSocket Server Started ===');
      print('Port: $port');
      print('Listening on all network interfaces:');
      print('- localhost:$port');
      print('- 10.66.66.5:$port (if available)');
      print('- 192.168.53.206:$port (if available)');
      print('==========================================');

      await for (HttpRequest request in _server!) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final clientIP = request.connectionInfo?.remoteAddress.address ?? 'unknown';
          print('[${DateTime.now()}] WebSocket upgrade request from $clientIP');
          WebSocket socket = await WebSocketTransformer.upgrade(request);
          _handleClient(socket, clientIP);
        } else {
          print('[${DateTime.now()}] Non-WebSocket request from ${request.connectionInfo?.remoteAddress.address}');
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write('WebSocket connections only');
          await request.response.close();
        }
      }
    } catch (e) {
      print('[CALC] ERROR: Starting calculator server: $e');
    }
  }

  void _handleClient(WebSocket socket, String clientIP) {
    _clients.add(socket);
    print('[CALC] Client connected from $clientIP');
    print('[CALC] Total clients: ${_clients.length}');

    // Отправляем текущее состояние новому клиенту
    _sendStateToClient(socket);

    socket.listen(
      (data) {
        try {
          final message = jsonDecode(data);
          _handleMessage(message, socket);
        } catch (e) {
          print('Error parsing message: $e');
        }
      },
      onDone: () {
        _clients.remove(socket);
        print('[CALC] Client from $clientIP disconnected');
        print('[CALC] Total clients: ${_clients.length}');
      },
      onError: (error) {
        print('[CALC] WebSocket error from $clientIP: $error');
        _clients.remove(socket);
      },
    );
  }

  void _handleMessage(Map<String, dynamic> message, WebSocket socket) {
    final type = message['type'];
    print('[CALC] Received: $type = ${message['value'] ?? 'no value'}');

    switch (type) {
      case 'setNumberA':
        _numberA = (message['value'] as num).toDouble();
        print('[CALC] Number A set to: $_numberA');
        _calculateResult();
        _broadcastState();
        break;
      case 'setNumberB':
        _numberB = (message['value'] as num).toDouble();
        print('[CALC] Number B set to: $_numberB');
        _calculateResult();
        _broadcastState();
        break;
      case 'setOperation':
        _operation = message['value'] as String;
        print('[CALC] Operation set to: $_operation');
        _calculateResult();
        _broadcastState();
        break;
      case 'calculate':
        print('[CALC] Calculating: $_numberA $_operation $_numberB');
        _calculateResult();
        _broadcastState();
        break;
      case 'getState':
        print('[CALC] State requested');
        _sendStateToClient(socket);
        break;
    }
  }

  void _calculateResult() {
    switch (_operation) {
      case '+':
        _result = _numberA + _numberB;
        break;
      case '-':
        _result = _numberA - _numberB;
        break;
      case '*':
        _result = _numberA * _numberB;
        break;
      case '/':
        _result = _numberB != 0 ? _numberA / _numberB : 0;
        if (_numberB == 0) {
          print('[CALC] WARNING: Division by zero attempted, result set to 0');
        }
        break;
    }
    print('[CALC] Result calculated: $_result');
  }

  void _sendStateToClient(WebSocket socket) {
    final state = {
      'type': 'state',
      'numberA': _numberA,
      'numberB': _numberB,
      'operation': _operation,
      'result': _result,
    };
    socket.add(jsonEncode(state));
  }

  void _broadcastState() {
    final state = {
      'type': 'state',
      'numberA': _numberA,
      'numberB': _numberB,
      'operation': _operation,
      'result': _result,
    };
    final message = jsonEncode(state);

    _clients.removeWhere((socket) {
      try {
        socket.add(message);
        return false;
      } catch (e) {
        return true; // Удаляем отключенные сокеты
      }
    });
  }

  Future<void> stop() async {
    for (final client in _clients) {
      await client.close();
    }
    _clients.clear();
    await _server?.close();
    print('Server stopped');
  }
}

// Запуск сервера (для тестирования)
void main() async {
  final server = CalculatorServer();
  await server.start();
}