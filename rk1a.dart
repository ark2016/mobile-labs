import 'ditredi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;

class RK1A extends StatefulWidget {
  const RK1A({super.key});

  @override
  State<RK1A> createState() => _RK1AState();
}

class _RK1AState extends State<RK1A> {
  final _controller = DiTreDiController(
    rotationX: -25,
    rotationY: 30,
    light: vector.Vector3(-0.5, -0.5, 0.5),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.update(userScale: 2.5);
    });
    _runOptimization();
  }

  List<vector.Vector3> _optimizationPath = [];
  int _currentStep = 0;
  bool _isInitialized = false;

  // Adam optimizer parameters
  final double _learningRate = 0.1;
  final double _beta1 = 0.9;
  final double _beta2 = 0.999;
  final double _epsilon = 1e-8;
  final vector.Vector2 _startPoint = vector.Vector2(5.0, 3.0);

  // f(x) = x1^2 + x2^2
  double _function(double x1, double x2) {
    return x1 * x1 + x2 * x2;
  }

  // Gradient of f(x) = x1^2 + x2^2
  // df/dx1 = 2 * x1
  // df/dx2 = 2 * x2
  vector.Vector2 _gradient(double x1, double x2) {
    return vector.Vector2(2 * x1, 2 * x2);
  }

  // Adam optimizer implementation
  void _runOptimization() {
    // Starting point
    double x1 = _startPoint.x;
    double x2 = _startPoint.y;

    // Adam state
    vector.Vector2 m = vector.Vector2.zero();
    vector.Vector2 v = vector.Vector2.zero();

    List<vector.Vector3> path = [];
    path.add(vector.Vector3(x1, x2, _function(x1, x2)));

    // Run optimization for 100 iterations
    for (int t = 1; t <= 100; t++) {
      // Compute gradient
      vector.Vector2 grad = _gradient(x1, x2);

      // Update biased first moment estimate
      m = m.scaled(_beta1) + grad.scaled(1 - _beta1);

      // Update biased second raw moment estimate
      vector.Vector2 vUpdate = vector.Vector2(
        grad.x * grad.x,
        grad.y * grad.y,
      );
      v = v.scaled(_beta2) + vUpdate.scaled(1 - _beta2);

      // Compute bias-corrected first moment estimate
      vector.Vector2 mHat = m.scaled(1 / (1 - math.pow(_beta1, t)));

      // Compute bias-corrected second raw moment estimate
      vector.Vector2 vHat = v.scaled(1 / (1 - math.pow(_beta2, t)));

      // Update parameters
      x1 = x1 - _learningRate * mHat.x / (math.sqrt(vHat.x) + _epsilon);
      x2 = x2 - _learningRate * mHat.y / (math.sqrt(vHat.y) + _epsilon);

      // Store the path
      path.add(vector.Vector3(x1, x2, _function(x1, x2)));

      // Check convergence
      if (t > 1) {
        double diff = (path[t] - path[t - 1]).length;
        if (diff < 1e-6) {
          break;
        }
      }
    }

    setState(() {
      _optimizationPath = path;
      _currentStep = path.length - 1;
      _isInitialized = true;
    });
  }

  // Generate 3D surface mesh for f(x) = x1 * x2^2
  List<Face3D> _generateSurface() {
    List<Face3D> faces = [];
    const int gridSize = 30;
    const double rangeX1Min = -1.0;
    const double rangeX1Max = 6.0;
    const double rangeX2Min = -1.0;
    const double rangeX2Max = 4.0;
    const double stepX1 = (rangeX1Max - rangeX1Min) / gridSize;
    const double stepX2 = (rangeX2Max - rangeX2Min) / gridSize;

    // Create grid of vertices
    List<List<vector.Vector3>> grid = [];
    for (int i = 0; i <= gridSize; i++) {
      List<vector.Vector3> row = [];
      for (int j = 0; j <= gridSize; j++) {
        double x1 = rangeX1Min + i * stepX1;
        double x2 = rangeX2Min + j * stepX2;
        double z = _function(x1, x2);
        row.add(vector.Vector3(x1, x2, z));
      }
      grid.add(row);
    }

    // Create triangular faces
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        vector.Vector3 p1 = grid[i][j];
        vector.Vector3 p2 = grid[i + 1][j];
        vector.Vector3 p3 = grid[i][j + 1];
        vector.Vector3 p4 = grid[i + 1][j + 1];

        // Color based on height
        Color color = _getColorForHeight(p1.z);

        // First triangle
        faces.add(Face3D.fromVertices(p1, p2, p3, color: color.withValues(alpha: 0.6)));

        // Second triangle
        faces.add(Face3D.fromVertices(p2, p4, p3, color: color.withValues(alpha: 0.6)));
      }
    }

    return faces;
  }

  Color _getColorForHeight(double z) {
    // Map height to color gradient (for range x1: -1 to 6, x2: -1 to 4)
    // Function range approximately: -16 to 96
    double normalized = (z + 20) / 120; // Normalize to 0-1
    normalized = normalized.clamp(0.0, 1.0);

    if (normalized < 0.5) {
      // Blue to cyan
      return Color.lerp(Colors.blue, Colors.cyan, normalized * 2)!;
    } else {
      // Cyan to red
      return Color.lerp(Colors.cyan, Colors.red, (normalized - 0.5) * 2)!;
    }
  }

  // Generate optimization path visualization
  List<Model3D> _generatePathVisualization() {
    List<Model3D> figures = [];

    if (_optimizationPath.isEmpty || _currentStep >= _optimizationPath.length) {
      return figures;
    }

    // Draw lines connecting points up to current step
    for (int i = 0; i < _currentStep; i++) {
      figures.add(Line3D(
        _optimizationPath[i],
        _optimizationPath[i + 1],
        color: Colors.yellow,
        width: 5,
      ));
    }

    // Draw points up to current step
    for (int i = 0; i <= _currentStep; i++) {
      Color pointColor;
      double pointWidth;

      if (i == _currentStep) {
        // Final/current point - bright and large
        pointColor = Colors.red;
        pointWidth = 20;
      } else if (i == 0) {
        // Starting point
        pointColor = Colors.green;
        pointWidth = 15;
      } else {
        // Intermediate points
        pointColor = Colors.orange;
        pointWidth = 10;
      }

      figures.add(Point3D(
        _optimizationPath[i],
        color: pointColor,
        width: pointWidth,
      ));
    }

    return figures;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const CupertinoPageScaffold(
        child: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('РК 1А - 3D Optimization'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: DiTreDiDraggable(
                controller: _controller,
                child: DiTreDi(
                  figures: [
                    ..._generateSurface(),
                    ..._generatePathVisualization(),
                  ],
                  controller: _controller,
                  config: const DiTreDiConfig(
                    supportZIndex: true,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'f(x) = x₁² + x₂²',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adam Optimizer Parameters:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start: (${_startPoint.x.toStringAsFixed(1)}, ${_startPoint.y.toStringAsFixed(1)})',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Learning Rate: $_learningRate',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'β₁: $_beta1  β₂: $_beta2  ε: ${_epsilon.toStringAsExponential(0)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Step ${_currentStep + 1} of ${_optimizationPath.length}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (_optimizationPath.isNotEmpty && _currentStep < _optimizationPath.length)
                    Text(
                      'Point: (${_optimizationPath[_currentStep].x.toStringAsFixed(3)}, '
                      '${_optimizationPath[_currentStep].y.toStringAsFixed(3)}) → '
                      'f = ${_optimizationPath[_currentStep].z.toStringAsFixed(3)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Iteration: '),
                      Expanded(
                        child: CupertinoSlider(
                          value: _currentStep.toDouble(),
                          min: 0,
                          max: (_optimizationPath.length - 1).toDouble(),
                          divisions: _optimizationPath.length - 1,
                          onChanged: (value) {
                            setState(() {
                              _currentStep = value.round();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Drag to rotate, Scroll to zoom',
                    style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}