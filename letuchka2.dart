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

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  // --- добавлены функции для запросов ---
  void _getSwitchRequestON() {
    setState(() {
      http
          .get(Uri.parse(
          'http://iocontrol.ru/api/sendData/Lebedev_Arkadiy/switch/1'))
          .then((response) {
        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");
      }).catchError((error) {
        print("Error: $error");
      });
    });
  }

  void _getSwitchRequestOFF() {
    setState(() {
      http
          .get(Uri.parse(
          'http://iocontrol.ru/api/sendData/Lebedev_Arkadiy/switch/0'))
          .then((response) {
        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");
      }).catchError((error) {
        print("Error: $error");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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

            // --- добавлены кнопки ON / OFF ---
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
