import 'calculator_server.dart';

/// Запуск сервера калькулятора (Лаб 5.1)
///
/// Для запуска выполните:
/// dart lib/lab5/start_calculator_server.dart
///
/// Сервер будет доступен по адресам:
/// - ws://localhost:8080
/// - ws://192.168.53.206:8080 (в локальной сети)
/// - ws://10.66.66.5:8080 (альтернативный адрес)

void main() async {
  print('=== Запуск сервера калькулятора ===');
  final server = CalculatorServer();
  await server.start();
}