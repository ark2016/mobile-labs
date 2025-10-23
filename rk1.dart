import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';

class RK1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('RK1 - Анимация черепа'),
      ),
      child: SkullAnimation(),
    );
  }
}

class SkullAnimation extends StatefulWidget {
  @override
  _SkullAnimationState createState() => _SkullAnimationState();
}

class _SkullAnimationState extends State<SkullAnimation>
    with SingleTickerProviderStateMixin {
  late Scene _scene;
  Object? _skull;
  Object? _jaw; // Отдельная ссылка на челюсть
  Object? _lowerTeeth; // Нижние зубы
  double _jawRotation = 0.0; // Угол открытия челюсти (от 0 до 30 градусов)
  bool _modelLoaded = false;
  late AnimationController _animationController;
  double _autoRotationY = 0.0; // Автоматическое вращение по Y
  double _rotationSpeed = 0.0; // Скорость вращения (0.0 = остановлено, 1.0 = максимум)

  void _onSceneCreated(Scene scene) {
    _scene = scene;
    // Настройка камеры - отодвигаем немного дальше
    scene.camera.position.z = 15;
    scene.camera.position.y = 2;
    scene.camera.position.x = 0;

    // Яркое освещение со всех сторон
    scene.light.position.setFrom(Vector3(10, 10, 10));
    scene.light.setColor(Colors.white, 0.5, 1.0, 1.0);

    // Загружаем модель черепа
    print('Загружаем модель черепа...');

    _skull = Object(
      position: Vector3(0, 3, 0), // Поднимаем череп выше, чтобы ползунки не мешали
      rotation: Vector3(-90, 0, 0), // Переворачиваем череп правильно
      scale: Vector3(8.0, 8.0, 8.0),
      lighting: true,
      fileName: 'lib/RK1/flutter_cube/10_lec_flutter_3D_2022/obj_files/1.obj',
      backfaceCulling: false,
    );

    scene.world.add(_skull!);
    print('Модель добавлена в сцену');

    // Задержка для загрузки и поиска челюсти
    Future.delayed(Duration(milliseconds: 2000), () {
      if (mounted) {
        // Ищем челюсть среди дочерних объектов
        _jaw = _skull?.find(RegExp(r'jaw', caseSensitive: false));

        // Ищем нижние зубы - они могут быть дочерним объектом челюсти
        // или отдельным объектом с "lower" в названии
        if (_jaw != null) {
          // Сначала проверяем, есть ли зубы внутри челюсти
          _lowerTeeth = _jaw?.find(RegExp(r'teet', caseSensitive: false));
        }

        // Если не нашли внутри челюсти, ищем отдельно с "lower" или просто teeth
        if (_lowerTeeth == null) {
          _lowerTeeth = _skull?.find(RegExp(r'(lower.*teet|teet.*lower)', caseSensitive: false));
        }

        setState(() {
          _modelLoaded = true;
          print('Модель загружена');
          print('Дочерних объектов черепа: ${_skull?.children.length}');
          print('Названия объектов:');
          _skull?.children.forEach((child) {
            print('  - ${child.name}');
            if (child.children.isNotEmpty) {
              child.children.forEach((subChild) {
                print('    └─ ${subChild.name}');
              });
            }
          });

          if (_jaw != null) {
            print('Челюсть найдена: ${_jaw?.name}');
            print('  Дочерних объектов челюсти: ${_jaw?.children.length}');
          } else {
            print('ВНИМАНИЕ: Челюсть не найдена!');
          }

          if (_lowerTeeth != null) {
            print('Нижние зубы найдены: ${_lowerTeeth?.name}');
          } else {
            print('ВНИМАНИЕ: Нижние зубы не найдены!');
          }
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Контроллер для автоматического вращения черепа вокруг вертикальной оси
    // 60 fps = 16.67ms per frame, за 10 секунд = полный оборот
    _animationController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    )..addListener(() {
        if (_skull != null && _rotationSpeed > 0.0) {
          // Умножаем на _rotationSpeed для управления скоростью
          _autoRotationY = _animationController.value * 360 * _rotationSpeed;
          _updateSkullRotation();
        }
      })..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateSkullRotation() {
    if (_skull != null) {
      // Вращаем весь череп по оси Y (автоматическое вращение)
      _skull!.rotation.y = _autoRotationY;
      _skull!.updateTransform();

      // Вращаем ТОЛЬКО челюсть и нижние зубы по оси X (открытие рта)
      if (_jaw != null) {
        _jaw!.rotation.x = _jawRotation;
        _jaw!.updateTransform();
      }

      if (_lowerTeeth != null) {
        _lowerTeeth!.rotation.x = _jawRotation;
        _lowerTeeth!.updateTransform();
      }

      _scene.update();
    }
  }

  void _updateJawRotation(double value) {
    setState(() {
      _jawRotation = value;
      _updateSkullRotation();
    });
  }

  void _updateRotationSpeed(double value) {
    setState(() {
      _rotationSpeed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Градиентный фон для лучшей видимости модели
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                ],
              ),
            ),
          ),

          // 3D модель черепа
          Cube(onSceneCreated: _onSceneCreated),

          // Индикатор загрузки
          if (!_modelLoaded)
            Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoActivityIndicator(radius: 15),
                    SizedBox(height: 12),
                    Text(
                      'Загрузка модели черепа...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Ползунки для управления челюстью и вращением
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Управление челюстью
                  Text(
                    'Движение челюсти',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Закрыто',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Expanded(
                        child: CupertinoSlider(
                          value: _jawRotation,
                          min: 0.0,
                          max: 30.0,
                          divisions: 30,
                          onChanged: _updateJawRotation,
                        ),
                      ),
                      Text(
                        'Открыто',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    'Угол: ${_jawRotation.toStringAsFixed(0)}°',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),

                  SizedBox(height: 16),
                  Divider(color: Colors.white30),
                  SizedBox(height: 8),

                  // Управление скоростью вращения
                  Text(
                    'Скорость вращения',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Стоп',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Expanded(
                        child: CupertinoSlider(
                          value: _rotationSpeed,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          onChanged: _updateRotationSpeed,
                        ),
                      ),
                      Text(
                        'Быстро',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    'Скорость: ${(_rotationSpeed * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
