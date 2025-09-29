import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // нужно для TabController и TabBarView
import 'dart:convert';
import 'dart:io';

class Lab52HomePage extends StatefulWidget {
  const Lab52HomePage({super.key, required this.title});
  final String title;

  @override
  State<Lab52HomePage> createState() => _Lab52HomePageState();
}

class _Lab52HomePageState extends State<Lab52HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  WebSocket? _webSocket;
  bool _isConnected = false;
  String _connectionStatus = 'Отключено';
  String _serverUrl = 'ws://195.209.214.174:8765';

  // Calculator state
  double _numberA = 0;
  double _numberB = 0;
  String _operation = '+';
  double _result = 0;
  final _numberAController = TextEditingController();
  final _numberBController = TextEditingController();
  final _serverUrlController = TextEditingController();
  bool _isUserEditingA = false;
  bool _isUserEditingB = false;

  // Slider state
  int _sliderValue = 0;
  String _lastUpdated = '';
  bool _isUserUsingSlider = false;

  // отдельные контроллеры для скроллов
  final ScrollController _calculatorScrollController = ScrollController();
  final ScrollController _sliderScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _serverUrlController.text = _serverUrl;
    _connectToServer(); // Auto-connect on startup

    _numberAController.addListener(() {
      if (_isUserEditingA) {
        _numberA = double.tryParse(_numberAController.text) ?? 0;
      }
    });

    _numberBController.addListener(() {
      if (_isUserEditingB) {
        _numberB = double.tryParse(_numberBController.text) ?? 0;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _webSocket?.close();
    _numberAController.dispose();
    _numberBController.dispose();
    _serverUrlController.dispose();
    _calculatorScrollController.dispose();
    _sliderScrollController.dispose();
    super.dispose();
  }

  Future<void> _connectToServer() async {
    if (_isConnected) {
      await _disconnectFromServer();
      return;
    }

    try {
      setState(() {
        _connectionStatus = 'Подключение...';
      });

      _webSocket = await WebSocket.connect(_serverUrlController.text);

      setState(() {
        _isConnected = true;
        _connectionStatus = 'Подключено к ${_serverUrlController.text}';
      });

      _webSocket!.listen(
        (data) {
          _handleMessage(data);
        },
        onDone: () {
          setState(() {
            _isConnected = false;
            _connectionStatus = 'Соединение закрыто';
          });
        },
        onError: (error) {
          setState(() {
            _isConnected = false;
            _connectionStatus = 'Ошибка: $error';
          });
        },
      );

      // Request current slider value on connection
      _requestSliderValue();

    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Ошибка подключения: $e';
      });
    }
  }

  Future<void> _disconnectFromServer() async {
    await _webSocket?.close();
    setState(() {
      _isConnected = false;
      _connectionStatus = 'Отключено';
    });
  }

  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data);

      if (message['type'] == 'calculation_result') {
        setState(() {
          _result = message['result'].toDouble();
        });
      } else if (message['type'] == 'slider_update') {
        if (!_isUserUsingSlider) {
          setState(() {
            _sliderValue = message['value'];
            _lastUpdated = DateTime.now().toString().substring(11, 19);
          });
        }
      } else if (message['type'] == 'slider_value') {
        setState(() {
          _sliderValue = message['value'];
          _lastUpdated = DateTime.now().toString().substring(11, 19);
        });
      }
    } catch (e) {
      print('Error parsing message: $e');
    }
  }

  void _sendCalculation(String operation) {
    if (!_isConnected || _webSocket == null) return;

    final message = jsonEncode({
      'type': 'calculate',
      'a': _numberA,
      'b': _numberB,
      'operation': operation,
    });

    _webSocket!.add(message);
    setState(() {
      _operation = operation;
    });
  }

  void _sendSliderValue(int value) {
    if (!_isConnected || _webSocket == null) return;

    final message = jsonEncode({
      'type': 'slider',
      'value': value,
    });

    _webSocket!.add(message);
  }

  void _requestSliderValue() {
    if (!_isConnected || _webSocket == null) return;

    final message = jsonEncode({
      'type': 'get_slider',
    });

    _webSocket!.add(message);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
      ),
      child: SafeArea(
        child: Column(
          children: [
            CupertinoSegmentedControl<int>(
              children: const {
                0: Text('Калькулятор'),
                1: Text('Ползунок'),
              },
              groupValue: _tabController.index,
              onValueChanged: (int value) {
                setState(() {
                  _tabController.animateTo(value);
                });
              },
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCalculatorTab(),
                  _buildSliderTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorTab() {
    return CupertinoScrollbar(
      controller: _calculatorScrollController,
      child: SingleChildScrollView(
        controller: _calculatorScrollController,
        primary: false,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isConnected
                    ? CupertinoColors.systemGreen.withOpacity(0.2)
                    : CupertinoColors.systemRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _connectionStatus,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isConnected
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _serverUrlController,
              placeholder: 'WebSocket Server URL',
              enabled: !_isConnected,
              onChanged: (value) {
                _serverUrl = value;
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: _connectToServer,
                color: _isConnected ? CupertinoColors.destructiveRed : CupertinoColors.activeBlue,
                child: Text(_isConnected ? 'Отключить' : 'Подключить'),
              ),
            ),
            const SizedBox(height: 24),
            CupertinoTextField(
              controller: _numberAController,
              placeholder: 'Число A',
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                if (_isUserEditingA) {
                  _numberA = double.tryParse(value) ?? 0;
                }
              },
              enabled: _isConnected,
              onTap: () => setState(() => _isUserEditingA = true),
              onEditingComplete: () =>
                  setState(() => _isUserEditingA = false),
              onSubmitted: (_) => setState(() => _isUserEditingA = false),
            ),
            const SizedBox(height: 16),
            CupertinoSegmentedControl<String>(
              children: const {
                '+': Text('+'),
                '-': Text('-'),
                '*': Text('×'),
                '/': Text('÷'),
              },
              groupValue: _operation,
              onValueChanged: (String value) {
                if (_isConnected) {
                  setState(() => _operation = value);
                }
              },
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _numberBController,
              placeholder: 'Число B',
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                if (_isUserEditingB) {
                  _numberB = double.tryParse(value) ?? 0;
                }
              },
              enabled: _isConnected,
              onTap: () => setState(() => _isUserEditingB = true),
              onEditingComplete: () =>
                  setState(() => _isUserEditingB = false),
              onSubmitted: (_) => setState(() => _isUserEditingB = false),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: _isConnected ? () => _sendCalculation(_operation) : null,
                child: const Text('Вычислить'),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Результат:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _result.toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!_isConnected)
              CupertinoButton(
                onPressed: _connectToServer,
                child: const Text('Переподключить'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderTab() {
    return CupertinoScrollbar(
      controller: _sliderScrollController,
      child: SingleChildScrollView(
        controller: _sliderScrollController,
        primary: false,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isConnected
                    ? CupertinoColors.systemGreen.withOpacity(0.2)
                    : CupertinoColors.systemRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _connectionStatus,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isConnected
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_lastUpdated.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Обновлено: $_lastUpdated',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Значение ползунка:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _sliderValue.toString(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoSlider(
                    value: _sliderValue.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (double value) {
                      setState(() => _isUserUsingSlider = true);
                      setState(() => _sliderValue = value.round());
                    },
                    onChangeStart: (_) =>
                        setState(() => _isUserUsingSlider = true),
                    onChangeEnd: (value) {
                      _isUserUsingSlider = false;
                      _sendSliderValue(value.round());
                      setState(() {
                        _lastUpdated = DateTime.now().toString().substring(11, 19);
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CupertinoButton.filled(
                  onPressed: _isConnected ? () => _sendSliderValue(_sliderValue > 0 ? _sliderValue - 1 : 0) : null,
                  child: const Text('-1'),
                ),
                CupertinoButton.filled(
                  onPressed: _isConnected ? () => _sendSliderValue(_sliderValue < 100 ? _sliderValue + 1 : 100) : null,
                  child: const Text('+1'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CupertinoButton(
                  onPressed: _isConnected ? () => _sendSliderValue(0) : null,
                  child: const Text('Сброс (0)'),
                ),
                CupertinoButton(
                  onPressed: _isConnected ? () => _sendSliderValue(100) : null,
                  child: const Text('Макс (100)'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (!_isConnected)
              CupertinoButton.filled(
                onPressed: _connectToServer,
                child: const Text('Переподключить'),
              ),
          ],
        ),
      ),
    );
  }
}