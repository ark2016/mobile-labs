import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // нужно для TabController и TabBarView
import 'dart:convert';
import 'dart:io';

class Lab51HomePage extends StatefulWidget {
  const Lab51HomePage({super.key, required this.title});
  final String title;

  @override
  State<Lab51HomePage> createState() => _Lab51HomePageState();
}

class _Lab51HomePageState extends State<Lab51HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  WebSocket? _calculatorSocket;
  WebSocket? _sliderSocket;
  bool _isCalculatorConnected = false;
  bool _isSliderConnected = false;

  // Calculator state
  double _numberA = 0;
  double _numberB = 0;
  String _operation = '+';
  double _result = 0;
  final _numberAController = TextEditingController();
  final _numberBController = TextEditingController();
  bool _isUserEditingA = false;
  bool _isUserEditingB = false;
  String _calculatorConnectionStatus = 'Отключено';

  // Slider state
  int _sliderValue = 0;
  String _sliderConnectionStatus = 'Отключено';
  String _lastUpdated = '';
  bool _isUserUsingSlider = false;

  // отдельные контроллеры для скроллов
  final ScrollController _calculatorScrollController = ScrollController();
  final ScrollController _sliderScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _connectToCalculatorServer();
    _connectToSliderServer();
  }

  // ---------------- Подключение к серверам ----------------
  Future<void> _connectToCalculatorServer() async {
    final addresses = [
      'ws://192.168.53.206:8080',
      'ws://10.66.66.5:8080',
      'ws://192.168.1.100:8080',
      'ws://192.168.0.100:8080',
      'ws://192.168.43.100:8080',
      'ws://172.20.10.2:8080',
      'ws://192.168.137.1:8080',
      'ws://localhost:8080',
      'ws://10.0.2.2:8080'
    ];

    for (final address in addresses) {
      try {
        _calculatorSocket = await WebSocket.connect(address).timeout(
          const Duration(seconds: 5),
        );

        if (mounted) {
          setState(() {
            _isCalculatorConnected = true;
            _calculatorConnectionStatus = 'Подключено к $address';
          });
        }

        _setupCalculatorListeners();
        _sendCalculatorMessage({'type': 'getState'});
        return;
      } catch (_) {
        continue;
      }
    }

    if (mounted) {
      setState(() {
        _isCalculatorConnected = false;
        _calculatorConnectionStatus = 'Не удалось подключиться к серверу';
      });
    }
  }

  Future<void> _connectToSliderServer() async {
    final addresses = [
      'ws://192.168.53.206:8081',
      'ws://10.66.66.5:8081',
      'ws://192.168.1.100:8081',
      'ws://192.168.0.100:8081',
      'ws://192.168.43.100:8081',
      'ws://172.20.10.2:8081',
      'ws://192.168.137.1:8081',
      'ws://localhost:8081',
    ];

    for (final address in addresses) {
      try {
        _sliderSocket = await WebSocket.connect(address).timeout(
          const Duration(seconds: 5),
        );

        if (mounted) {
          setState(() {
            _isSliderConnected = true;
            _sliderConnectionStatus = 'Подключено к $address';
          });
        }

        _setupSliderListeners();
        _sendSliderMessage({'type': 'getSliderValue'});
        return;
      } catch (_) {
        continue;
      }
    }

    if (mounted) {
      setState(() {
        _isSliderConnected = false;
        _sliderConnectionStatus = 'Не удалось подключиться к серверу';
      });
    }
  }

  // ---------------- Вспомогательные методы для отправки ----------------
  void _sendCalculatorMessage(Map<String, dynamic> message) {
    if (_isCalculatorConnected && _calculatorSocket != null) {
      _calculatorSocket!.add(jsonEncode(message));
    }
  }

  void _sendSliderMessage(Map<String, dynamic> message) {
    if (_isSliderConnected && _sliderSocket != null) {
      _sliderSocket!.add(jsonEncode(message));
    }
  }

  // ---------------- Listeners ----------------
  void _setupCalculatorListeners() {
    _calculatorSocket!.listen(
          (data) {
        final message = jsonDecode(data);
        if (message['type'] == 'state') {
          if (mounted) {
            setState(() {
              _numberA = message['numberA'];
              _numberB = message['numberB'];
              _operation = message['operation'];
              _result = message['result'];

              if (!_isUserEditingA) {
                _numberAController.text = _numberA.toString();
              }
              if (!_isUserEditingB) {
                _numberBController.text = _numberB.toString();
              }
            });
          }
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isCalculatorConnected = false;
            _calculatorConnectionStatus = 'Соединение разорвано';
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isCalculatorConnected = false;
            _calculatorConnectionStatus = 'Ошибка: $error';
          });
        }
      },
    );
  }

  void _setupSliderListeners() {
    _sliderSocket!.listen(
          (data) {
        final message = jsonDecode(data);
        if (message['type'] == 'sliderState') {
          if (mounted && !_isUserUsingSlider) {
            setState(() {
              _sliderValue = message['value'];
              if (message['timestamp'] != null) {
                final timestamp =
                DateTime.fromMillisecondsSinceEpoch(message['timestamp']);
                _lastUpdated =
                '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
              }
            });
          }
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isSliderConnected = false;
            _sliderConnectionStatus = 'Соединение разорвано';
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isSliderConnected = false;
            _sliderConnectionStatus = 'Ошибка: $error';
          });
        }
      },
    );
  }

  // ---------------- Calculator actions ----------------
  void _setNumberA(String value) {
    final num = double.tryParse(value) ?? 0;
    _sendCalculatorMessage({'type': 'setNumberA', 'value': num});
  }

  void _setNumberB(String value) {
    final num = double.tryParse(value) ?? 0;
    _sendCalculatorMessage({'type': 'setNumberB', 'value': num});
  }

  void _setOperation(String op) {
    _sendCalculatorMessage({'type': 'setOperation', 'value': op});
  }

  void _calculate() {
    _sendCalculatorMessage({'type': 'calculate'});
  }

  // ---------------- Slider actions ----------------
  void _setSliderValue(int value) {
    _sendSliderMessage({'type': 'setSliderValue', 'value': value});
  }

  void _incrementSlider() {
    if (_sliderValue < 100) _setSliderValue(_sliderValue + 1);
  }

  void _decrementSlider() {
    if (_sliderValue > 0) _setSliderValue(_sliderValue - 1);
  }

  void _resetSlider() {
    _setSliderValue(0);
  }

  void _setToMax() {
    _setSliderValue(100);
  }

  // ---------------- UI ----------------
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
                color: _isCalculatorConnected
                    ? CupertinoColors.systemGreen.withOpacity(0.2)
                    : CupertinoColors.systemRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _calculatorConnectionStatus,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isCalculatorConnected
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            CupertinoTextField(
              controller: _numberAController,
              placeholder: 'Число A',
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              onChanged: _setNumberA,
              enabled: _isCalculatorConnected,
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
                if (_isCalculatorConnected) {
                  setState(() => _operation = value);
                  _setOperation(value);
                }
              },
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _numberBController,
              placeholder: 'Число B',
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              onChanged: _setNumberB,
              enabled: _isCalculatorConnected,
              onTap: () => setState(() => _isUserEditingB = true),
              onEditingComplete: () =>
                  setState(() => _isUserEditingB = false),
              onSubmitted: (_) => setState(() => _isUserEditingB = false),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: _isCalculatorConnected ? _calculate : null,
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
            if (!_isCalculatorConnected)
              CupertinoButton(
                onPressed: _connectToCalculatorServer,
                child: const Text('Переподключить калькулятор'),
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
                color: _isSliderConnected
                    ? CupertinoColors.systemGreen.withOpacity(0.2)
                    : CupertinoColors.systemRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _sliderConnectionStatus,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isSliderConnected
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
                      _setSliderValue(value.round());
                    },
                    onChangeStart: (_) =>
                        setState(() => _isUserUsingSlider = true),
                    onChangeEnd: (_) => Future.delayed(
                      const Duration(milliseconds: 500),
                          () => setState(() => _isUserUsingSlider = false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CupertinoButton.filled(
                  onPressed: _isSliderConnected ? _decrementSlider : null,
                  child: const Text('-1'),
                ),
                CupertinoButton.filled(
                  onPressed: _isSliderConnected ? _incrementSlider : null,
                  child: const Text('+1'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CupertinoButton(
                  onPressed: _isSliderConnected ? _resetSlider : null,
                  child: const Text('Сброс (0)'),
                ),
                CupertinoButton(
                  onPressed: _isSliderConnected ? _setToMax : null,
                  child: const Text('Макс (100)'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (!_isSliderConnected)
              CupertinoButton.filled(
                onPressed: _connectToSliderServer,
                child: const Text('Переподключить слайдер'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _calculatorSocket?.close();
    _sliderSocket?.close();
    _numberAController.dispose();
    _numberBController.dispose();
    _tabController.dispose();
    _calculatorScrollController.dispose();
    _sliderScrollController.dispose();
    super.dispose();
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
}
