import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  bool _isOn = true;
  int _slider = 0;
  final int _min = 0;
  final int _max = 100;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<void> _getSwitchRequestON() async {
    try {
      await http.get(Uri.parse('http://iocontrol.ru/api/sendData/Lebedev_Arkadiy/switch/1'));
      setState(() {
        _isOn = true;
      });
      await Future.delayed(const Duration(milliseconds: 150));
      await _getSliderFromServer(force: true);
    } catch (_) {}
  }

  Future<void> _getSwitchRequestOFF() async {
    try {
      await http.get(Uri.parse('http://iocontrol.ru/api/sendData/Lebedev_Arkadiy/switch/0'));
      setState(() {
        _isOn = false;
      });
    } catch (_) {}
  }

  Future<void> _getSliderFromServer({bool force = false}) async {
    try {
      final bust = force ? '?_=${DateTime.now().millisecondsSinceEpoch}' : '';
      final resp = await http.get(
        Uri.parse('http://iocontrol.ru/api/readData/Lebedev_Arkadiy/slider$bust'),
        headers: {'Cache-Control': 'no-cache'},
      );
      final m = RegExp(r'-?\d+').firstMatch(resp.body);
      if (m != null) {
        final parsed = int.parse(m.group(0)!);
        setState(() {
          _slider = parsed.clamp(_min, _max);
        });
      }
    } catch (_) {}
  }

  Future<void> _getSwitchStateFromServer() async {
    try {
      final resp = await http.get(Uri.parse('http://iocontrol.ru/api/readData/Lebedev_Arkadiy/switch'), headers: {'Cache-Control': 'no-cache'});
      final on = resp.body.trim().contains('1');
      setState(() {
        _isOn = on;
      });
      if (on) {
        await _getSliderFromServer(force: true);
      }
    } catch (_) {}
  }

  void _sendSliderToServer(int value) {
    http.get(Uri.parse('http://iocontrol.ru/api/sendData/Lebedev_Arkadiy/slider/$value'));
  }

  void _moveLeft() {
    if (_slider > _min) {
      setState(() {
        _slider = _slider - 1;
      });
      if (_isOn) {
        _sendSliderToServer(_slider);
      }
    }
  }

  void _moveRight() {
    if (_slider < _max) {
      setState(() {
        _slider = _slider + 1;
      });
      if (_isOn) {
        _sendSliderToServer(_slider);
      }
    }
  }

  void _refreshToZero() {
    setState(() {
      _slider = 0;
    });
    if (_isOn) {
      _sendSliderToServer(0);
    }
  }

  @override
  void initState() {
    super.initState();
    _getSwitchStateFromServer();
  }

  @override
  Widget build(BuildContext context) {
    final sliderLabel = 'SLIDER: $_slider (${_min}..$_max)';
    final powerLabel = _isOn ? 'POWER: ON' : 'POWER: OFF';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Text(powerLabel),
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
              ),
              onPressed: _getSwitchRequestON,
              child: const Text('ON'),
            ),
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
              ),
              onPressed: _getSwitchRequestOFF,
              child: const Text('OFF'),
            ),
            const SizedBox(height: 16),
            Text(sliderLabel),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                  ),
                  onPressed: _moveLeft,
                  child: const Text('-1'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                  ),
                  onPressed: _moveRight,
                  child: const Text('+1'),
                ),
              ],
            ),
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.red),
              ),
              onPressed: _refreshToZero,
              child: const Text('Обновить (0)'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
