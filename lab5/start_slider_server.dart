import 'slider_server.dart';

/// Запуск сервера ползунка (Лаб 5.2)
///
/// Для запуска выполните:
/// dart lib/lab5/start_slider_server.dart
///
/// Сервер будет доступен по адресам:
/// - ws://localhost:8081
/// - ws://192.168.53.206:8081 (в локальной сети)
/// - ws://10.66.66.5:8081 (альтернативный адрес)
///
/// Данные сохраняются в файл slider_data.json

void main() async {
  print('=== Запуск сервера ползунка ===');
  final server = SliderServer();
  await server.start();
}