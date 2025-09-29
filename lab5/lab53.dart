import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';

class Lab53 extends StatefulWidget {
  const Lab53({super.key});

  @override
  State<Lab53> createState() => _Lab53State();
}

class _Lab53State extends State<Lab53> {
  int _counter = 0;
  bool _isOn = true;
  int _slider = 0;
  final int _min = 0;
  final int _max = 100;

  WebSocket? _webSocket;
  bool _connected = false;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<void> _connectWebSocket() async {
    try {
      print('Attempting to connect to WebSocket...');
      _webSocket = await WebSocket.connect('ws://195.209.214.174:8765')
          .timeout(Duration(seconds: 10));
      print('WebSocket connected successfully');
      setState(() {
        _connected = true;
      });

      _webSocket!.listen(
        (data) {
          print('Received WebSocket data: $data');
          _handleWebSocketMessage(data);
        },
        onDone: () {
          print('WebSocket connection closed');
          setState(() {
            _connected = false;
          });
        },
        onError: (error) {
          print('WebSocket error: $error');
          setState(() {
            _connected = false;
          });
        },
      );

      // Request initial state
      _getSwitchStateFromServer();
    } catch (e) {
      print('WebSocket connection failed: $e');
      setState(() {
        _connected = false;
      });
    }
  }

  void _handleWebSocketMessage(dynamic data) {
    try {
      final message = jsonDecode(data);

      switch (message['type']) {
        case 'switch_state':
          setState(() {
            _isOn = message['value'] == 1;
          });
          if (_isOn) {
            _getSliderFromServer(force: true);
          }
          break;
        case 'slider_value':
          setState(() {
            _slider = (message['value'] as int).clamp(_min, _max);
          });
          break;
      }
    } catch (e) {
      // Handle JSON decode error
    }
  }

  void _sendWebSocketMessage(Map<String, dynamic> message) {
    if (_connected && _webSocket != null) {
      _webSocket!.add(jsonEncode(message));
    }
  }

  Future<void> _getSwitchRequestON() async {
    _sendWebSocketMessage({
      'type': 'set_switch',
      'value': 1
    });
    setState(() {
      _isOn = true;
    });
    await Future.delayed(const Duration(milliseconds: 150));
    await _getSliderFromServer(force: true);
  }

  Future<void> _getSwitchRequestOFF() async {
    _sendWebSocketMessage({
      'type': 'set_switch',
      'value': 0
    });
    setState(() {
      _isOn = false;
    });
  }

  Future<void> _getSliderFromServer({bool force = false}) async {
    _sendWebSocketMessage({
      'type': 'get_slider',
      'force': force
    });
  }

  Future<void> _getSwitchStateFromServer() async {
    _sendWebSocketMessage({
      'type': 'get_switch'
    });
  }

  void _sendSliderToServer(int value) {
    _sendWebSocketMessage({
      'type': 'set_slider',
      'value': value
    });
  }

  void _moveLeft() {
    if (_isOn && _slider > _min) {
      setState(() {
        _slider = _slider - 1;
      });
      _sendSliderToServer(_slider);
    }
  }

  void _moveRight() {
    if (_isOn && _slider < _max) {
      setState(() {
        _slider = _slider + 1;
      });
      _sendSliderToServer(_slider);
    }
  }

  void _refreshToZero() {
    if (_isOn) {
      setState(() {
        _slider = 0;
      });
      _sendSliderToServer(0);
    }
  }

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _webSocket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sliderLabel = 'SLIDER: $_slider ($_min..$_max)';
    final powerLabel = _isOn ? 'POWER: ON' : 'POWER: OFF';
    final connectionLabel = _connected ? 'Connected' : 'Disconnected';

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Lab 5.3 - WebSocket Control'),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Connection: $connectionLabel',
                style: TextStyle(
                  color: _connected ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (!_connected)
                CupertinoButton(
                  onPressed: () {
                    print('Reconnect button pressed');
                    _connectWebSocket();
                  },
                  child: const Text('Reconnect'),
                ),
              const SizedBox(height: 24),
              const Text('You have pushed the button this many times:'),
              Text(
                '$_counter',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Text(powerLabel),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoButton(
                    onPressed: _connected ? _getSwitchRequestON : null,
                    child: const Text('ON'),
                  ),
                  CupertinoButton(
                    onPressed: _connected ? _getSwitchRequestOFF : null,
                    child: const Text('OFF'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(sliderLabel),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoButton(
                    onPressed: _connected ? _moveLeft : null,
                    child: const Text('-1'),
                  ),
                  const SizedBox(width: 16),
                  CupertinoButton(
                    onPressed: _connected ? _moveRight : null,
                    child: const Text('+1'),
                  ),
                ],
              ),
              CupertinoButton(
                onPressed: _connected ? _refreshToZero : null,
                child: const Text('Обновить (0)'),
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: _incrementCounter,
                child: const Icon(CupertinoIcons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}