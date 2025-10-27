import 'ditredi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math';

class Lab7 extends StatefulWidget {
  const Lab7({Key? key}) : super(key: key);

  @override
  State<Lab7> createState() => _Lab7State();
}

class _Lab7State extends State<Lab7> {
  // Углы сгибания пальцев (от 0 до 12, где 12 = полностью согнут)
  var indexAngle = 0.0;
  var middleAngle = 0.0;
  var ringAngle = 0.0;
  var pinkyAngle = 0.0;

  // Позиция руки в 3D пространстве
  var handX = 0.0;
  var handY = 0.0;
  var handZ = 0.0;

  // Позиция объекта
  var objectX = 10.0;
  var objectY = 5.0;
  var objectZ = 5.0;

  // Состояние хватания
  bool isGrabbing = false;
  bool objectGrabbed = false;

  // Отслеживание предыдущего состояния пальцев для детекции момента сжатия
  bool _previousFingersGrabbing = false;

  // Состояние коллизии
  bool isColliding = false;

  // Хранение offset при захвате
  vector.Vector3? grabOffset;

  Future<List<Mesh3D>>? _handMeshes;

  final _controller = DiTreDiController(
    rotationX: -30,
    rotationY: 30,
    light: vector.Vector3(-0.5, -0.5, 0.5),
  );

  @override
  void initState() {
    super.initState();
    _handMeshes = _loadHandMeshes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.update(userScale: 1.5);
    });
  }

  Future<List<Mesh3D>> _loadHandMeshes() async {
    return [
      Mesh3D(await ObjParser().loadFromResources("lib/lab7/assets/hand/hand.obj")),
      Mesh3D(await ObjParser().loadFromResources("lib/lab7/assets/hand/index.obj")),
      Mesh3D(await ObjParser().loadFromResources("lib/lab7/assets/hand/middle.obj")),
      Mesh3D(await ObjParser().loadFromResources("lib/lab7/assets/hand/ring.obj")),
      Mesh3D(await ObjParser().loadFromResources("lib/lab7/assets/hand/pinky.obj")),
    ];
  }

  // Проверка условий захвата
  void _checkGrabbing() {
    // Проверяем, что все пальцы достаточно согнуты (порог = 8 из 12)
    const grabThreshold = 8.0;
    bool fingersGrabbing = indexAngle >= grabThreshold &&
        middleAngle >= grabThreshold &&
        ringAngle >= grabThreshold &&
        pinkyAngle >= grabThreshold;

    // Вычисляем расстояние между рукой и объектом
    double distance = sqrt(
      pow(handX - objectX, 2) +
          pow(handY - objectY, 2) +
          pow(handZ - objectZ, 2),
    );

    // Порог расстояния для захвата
    const distanceThreshold = 12.0;

    // Порог расстояния для коллизии (немного меньше, чем для захвата)
    const collisionThreshold = 8.0;

    // Детектируем момент сжатия (переход из разжатого в сжатое)
    bool justGrabbed = !_previousFingersGrabbing && fingersGrabbing;

    setState(() {
      // Захватываем объект ТОЛЬКО в момент сжатия пальцев (не когда они уже сжаты!)
      // Это гарантирует, что сжатая рука проходит мимо объекта, не захватывая его
      if (justGrabbed && distance < distanceThreshold && !objectGrabbed) {
        objectGrabbed = true;
        // Сохраняем offset относительно руки
        grabOffset = vector.Vector3(
          objectX - handX,
          objectY - handY,
          objectZ - handZ,
        );
      }
      // Отпускаем объект, если пальцы разжались
      else if (!fingersGrabbing && objectGrabbed) {
        objectGrabbed = false;
        grabOffset = null;
      }
      // Если объект схвачен, обновляем его позицию относительно руки
      else if (objectGrabbed && grabOffset != null) {
        objectX = handX + grabOffset!.x;
        objectY = handY + grabOffset!.y;
        objectZ = handZ + grabOffset!.z;
      }
      // КОЛЛИЗИЯ: Если объект НЕ схвачен и рука слишком близко - отталкиваем объект
      if (!objectGrabbed && distance < collisionThreshold && distance > 0.01) {
        // Вычисляем вектор от руки к объекту (направление отталкивания)
        double dx = objectX - handX;
        double dy = objectY - handY;
        double dz = objectZ - handZ;

        // Нормализуем вектор
        double length = sqrt(dx * dx + dy * dy + dz * dz);
        dx /= length;
        dy /= length;
        dz /= length;

        // Рассчитываем силу отталкивания (чем ближе, тем сильнее)
        double pushForce = (collisionThreshold - distance) * 0.5;

        // Отталкиваем объект от руки
        objectX += dx * pushForce;
        objectY += dy * pushForce;
        objectZ += dz * pushForce;

        isColliding = true;
      } else {
        isColliding = false;
      }

      isGrabbing = fingersGrabbing;
      _previousFingersGrabbing = fingersGrabbing; // Сохраняем текущее состояние для следующего вызова
    });
  }

  // Создание 3D фигур для сцены
  List<Model3D> _generateScene() {
    List<Model3D> figures = [];

    // Определяем цвет объекта в зависимости от состояния
    Color objectColor;
    if (objectGrabbed) {
      objectColor = Colors.green; // Зеленый - захвачен
    } else if (isColliding) {
      objectColor = Colors.orange; // Оранжевый - коллизия
    } else {
      objectColor = Colors.red; // Красный - свободен
    }

    // Добавляем куб (объект для захвата)
    figures.add(
      TransformModifier3D(
        Group3D([
          Cube3D(2, vector.Vector3.zero(), color: objectColor),
        ]),
        Matrix4.identity()..translate(objectX, objectY, objectZ),
      ),
    );

    return figures;
  }

  // Создание фигур руки
  List<Model3D> _generateHandFigures(List<Mesh3D> meshes) {
    return [
      // Ладонь (palm)
      TransformModifier3D(
        meshes[0],
        Matrix4.identity()
          ..translate(handX, handY, handZ)
          ..rotateX(-pi / 2),
      ),
      // Указательный палец
      TransformModifier3D(
        meshes[1],
        Matrix4.identity()
          ..translate(handX, handY, handZ)
          ..rotateX(-pi / 2)
          ..translate(3.05, 1.15, 8.75)
          ..translate(-0.2, -0.25, -2.2)
          ..rotateX(-(indexAngle * pi / 18))
          ..translate(0.2, 0.25, 2.2),
      ),
      // Средний палец
      TransformModifier3D(
        meshes[2],
        Matrix4.identity()
          ..translate(handX, handY, handZ)
          ..rotateX(-pi / 2)
          ..translate(0.7, 0.0, 9.75)
          ..translate(0.0, -0.5, -2.25)
          ..rotateX(-(middleAngle * pi / 18))
          ..translate(0.0, 0.5, 2.25),
      ),
      // Безымянный палец
      TransformModifier3D(
        meshes[3],
        Matrix4.identity()
          ..translate(handX, handY, handZ)
          ..rotateX(-pi / 2)
          ..translate(-2.0, -0.56, 9.1)
          ..translate(0.0, -0.25, -2.2)
          ..rotateX(-(ringAngle * pi / 18))
          ..translate(0.0, 0.25, 2.2),
      ),
      // Мизинец
      TransformModifier3D(
        meshes[4],
        Matrix4.identity()
          ..translate(handX, handY, handZ)
          ..rotateX(-pi / 2)
          ..translate(-4.65, -1.0, 7.15)
          ..translate(0.0, 0.0, -1.25)
          ..rotateX(-(pinkyAngle * pi / 18))
          ..translate(0.0, 0.0, 1.25),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Lab 7 - 3D Hand Grabbing'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 3D сцена
            Expanded(
              flex: 3,
              child: FutureBuilder<List<Mesh3D>>(
                future: _handMeshes,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return DiTreDiDraggable(
                      controller: _controller,
                      child: DiTreDi(
                        figures: [
                          ..._generateScene(),
                          ..._generateHandFigures(snapshot.data!),
                        ],
                        controller: _controller,
                        config: const DiTreDiConfig(
                          supportZIndex: true,
                        ),
                      ),
                    );
                  } else {
                    return const Center(
                      child: CupertinoActivityIndicator(),
                    );
                  }
                },
              ),
            ),

            // Панель управления
            Expanded(
              flex: 2,
              child: Container(
                color: CupertinoColors.systemGrey6,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Статус
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: objectGrabbed
                            ? Colors.green.shade100
                            : (isColliding ? Colors.orange.shade100 : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              objectGrabbed
                                ? CupertinoIcons.hand_raised_fill
                                : (isColliding ? CupertinoIcons.exclamationmark_triangle_fill : CupertinoIcons.hand_raised),
                              color: objectGrabbed
                                ? Colors.green
                                : (isColliding ? Colors.orange : Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                objectGrabbed
                                  ? 'ОБЪЕКТ ЗАХВАЧЕН'
                                  : (isColliding
                                    ? 'КОЛЛИЗИЯ - объект отталкивается'
                                    : (isGrabbing ? 'Попытка захвата...' : 'Разожмите пальцы')),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: objectGrabbed
                                    ? Colors.green.shade900
                                    : (isColliding ? Colors.orange.shade900 : Colors.grey.shade700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Управление пальцами
                      const Text('Пальцы (поднести руку к объекту и сжать)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  indexAngle = 0.0;
                                  middleAngle = 0.0;
                                  ringAngle = 0.0;
                                  pinkyAngle = 0.0;
                                });
                                _checkGrabbing();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.black, width: 1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Разжать все',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  indexAngle = 12.0;
                                  middleAngle = 12.0;
                                  ringAngle = 12.0;
                                  pinkyAngle = 12.0;
                                });
                                _checkGrabbing();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.black, width: 1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Сжать все',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildSlider('Указательный', indexAngle, (v) {
                        setState(() => indexAngle = v);
                        _checkGrabbing();
                      }),
                      _buildSlider('Средний', middleAngle, (v) {
                        setState(() => middleAngle = v);
                        _checkGrabbing();
                      }),
                      _buildSlider('Безымянный', ringAngle, (v) {
                        setState(() => ringAngle = v);
                        _checkGrabbing();
                      }),
                      _buildSlider('Мизинец', pinkyAngle, (v) {
                        setState(() => pinkyAngle = v);
                        _checkGrabbing();
                      }),

                      const Divider(height: 24),

                      // Управление позицией руки
                      const Text('Позиция руки', style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildPositionSlider('X', handX, -20, 20, (v) {
                        setState(() => handX = v);
                        _checkGrabbing();
                      }),
                      _buildPositionSlider('Y', handY, -20, 20, (v) {
                        setState(() => handY = v);
                        _checkGrabbing();
                      }),
                      _buildPositionSlider('Z', handZ, -20, 20, (v) {
                        setState(() => handZ = v);
                        _checkGrabbing();
                      }),

                      const SizedBox(height: 8),

                      // Легенда цветов
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey5,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Цвета объекта:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('Свободен', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 12),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('Коллизия', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 12),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('Захвачен', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Drag to rotate, Scroll to zoom',
                        style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: CupertinoSlider(
              value: value,
              min: 0,
              max: 12,
              divisions: 24,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: CupertinoSlider(
              value: value,
              min: min,
              max: max,
              divisions: 80,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
