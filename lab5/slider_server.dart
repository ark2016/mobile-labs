import 'dart:io';
import 'dart:convert';

class SliderServer {
  static const int port = 8081;
  HttpServer? _server;
  final Set<WebSocket> _clients = {};

  int _sliderValue = 0;

  // Путь к файлу для сохранения данных
  static const String dataFile = 'slider_data.json';

  Future<void> start() async {
    try {
      // Загружаем данные из файла при запуске
      await _loadDataFromFile();

      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      print('=== Slider WebSocket Server Started ===');
      print('Port: $port');
      print('Listening on all network interfaces:');
      print('- localhost:$port');
      print('- 10.66.66.5:$port (if available)');
      print('- 192.168.53.206:$port (if available)');
      print('Current slider value: $_sliderValue');
      print('========================================');

      await for (HttpRequest request in _server!) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final clientIP = request.connectionInfo?.remoteAddress.address ?? 'unknown';
          print('[${DateTime.now()}] Slider WebSocket upgrade request from $clientIP');
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
      print('[SLIDER] ERROR: Starting slider server: $e');
    }
  }

  void _handleClient(WebSocket socket, String clientIP) {
    _clients.add(socket);
    print('[SLIDER] Client connected from $clientIP');
    print('[SLIDER] Total clients: ${_clients.length}');

    // Отправляем текущее состояние новому клиенту
    _sendStateToClient(socket);

    socket.listen(
      (data) {
        try {
          final message = jsonDecode(data);
          _handleMessage(message, socket);
        } catch (e) {
          print('[SLIDER] Error parsing message from $clientIP: $e');
        }
      },
      onDone: () {
        _clients.remove(socket);
        print('[SLIDER] Client from $clientIP disconnected');
        print('[SLIDER] Total clients: ${_clients.length}');
      },
      onError: (error) {
        print('[SLIDER] WebSocket error from $clientIP: $error');
        _clients.remove(socket);
      },
    );
  }

  void _handleMessage(Map<String, dynamic> message, WebSocket socket) {
    final type = message['type'];
    print('[SLIDER] Received: $type = ${message['value'] ?? 'no value'}');

    switch (type) {
      case 'setSliderValue':
        final newValue = (message['value'] as num).toInt();
        if (newValue >= 0 && newValue <= 100) {
          final oldValue = _sliderValue;
          _sliderValue = newValue;
          print('[SLIDER] Value changed: $oldValue -> $_sliderValue');
          _saveDataToFile();
          _broadcastState();
        } else {
          print('[SLIDER] Invalid value rejected: $newValue (must be 0-100)');
        }
        break;
      case 'getSliderValue':
        print('[SLIDER] State requested');
        _sendStateToClient(socket);
        break;
    }
  }

  void _sendStateToClient(WebSocket socket) {
    final state = {
      'type': 'sliderState',
      'value': _sliderValue,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    socket.add(jsonEncode(state));
  }

  void _broadcastState() {
    final state = {
      'type': 'sliderState',
      'value': _sliderValue,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
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

  Future<void> _loadDataFromFile() async {
    try {
      final file = File(dataFile);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString);
        _sliderValue = data['sliderValue'] ?? 0;
        print('[SLIDER] Loaded slider data: $_sliderValue');
      }
    } catch (e) {
      print('[SLIDER] Error loading data: $e');
      _sliderValue = 0;
    }
  }

  Future<void> _saveDataToFile() async {
    try {
      final file = File(dataFile);
      final data = {
        'sliderValue': _sliderValue,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('[SLIDER] Error saving data: $e');
    }
  }

  Future<void> stop() async {
    for (final client in _clients) {
      await client.close();
    }
    _clients.clear();
    await _server?.close();
    print('Slider server stopped');
  }
}

// Запуск сервера (для тестирования)
void main() async {
  final server = SliderServer();
  await server.start();
}