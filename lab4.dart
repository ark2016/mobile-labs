import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _turns = 3.0;
  double _spacing = 20.0;
  bool _clockwise = true;
  final Color _color = CupertinoColors.systemPurple;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(
                  painter: SpiralPainter(
                    turns: _turns,
                    spacing: _spacing,
                    clockwise: _clockwise,
                    color: _color,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
            Container(
              height: 250,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text('Витки (n): ', style: TextStyle(fontSize: 14)),
                        ),
                        Expanded(
                          flex: 3,
                          child: CupertinoSlider(
                            value: _turns,
                            min: 1.0,
                            max: 10.0,
                            divisions: 9,
                            onChanged: (value) {
                              setState(() {
                                _turns = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          child: Text('${_turns.round()}', style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text('Расстояние (d): ', style: TextStyle(fontSize: 14)),
                        ),
                        Expanded(
                          flex: 3,
                          child: CupertinoSlider(
                            value: _spacing,
                            min: 5.0,
                            max: 50.0,
                            onChanged: (value) {
                              setState(() {
                                _spacing = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          child: Text('${_spacing.round()}', style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Направление:', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoSlidingSegmentedControl<bool>(
                            children: const {
                              true: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('По часовой', style: TextStyle(fontSize: 12)),
                              ),
                              false: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('Против часовой', style: TextStyle(fontSize: 12)),
                              ),
                            },
                            onValueChanged: (value) {
                              setState(() {
                                _clockwise = value!;
                              });
                            },
                            groupValue: _clockwise,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpiralPainter extends CustomPainter {
  final double turns;
  final double spacing;
  final bool clockwise;
  final Color color;

  SpiralPainter({
    required this.turns,
    required this.spacing,
    required this.clockwise,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 20;

    final path = Path();
    bool firstPoint = true;

    for (double t = 0; t <= turns * 2 * math.pi; t += 0.1) {
      final radius = (t / (2 * math.pi)) * spacing;

      if (radius > maxRadius) break;

      final angle = clockwise ? t : -t;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
