import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'rk1.dart' as rk1;
import 'rk1a.dart' as rk1a;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'РК1 - Лебедев ИУ9-71Б',
      localizationsDelegates: [
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      home: LabNavigator(),
    );
  }
}

class LabNavigator extends StatefulWidget {
  const LabNavigator({super.key});

  @override
  State<LabNavigator> createState() => _LabNavigatorState();
}

class _LabNavigatorState extends State<LabNavigator> {
  Widget _currentLab = rk1.RK1();
  int _selectedLabIndex = 0;

  void _navigateToLab(Widget lab, int index) {
    setState(() {
      _currentLab = lab;
      _selectedLabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('РК1 - Лебедев ИУ9-71Б'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: 120,
              child: CupertinoScrollbar(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    CupertinoListTile(
                      title: const Text('РК 1 - Анимация черепа'),
                      subtitle: const Text('3D модель с управлением челюстью'),
                      onTap: () => _navigateToLab(rk1.RK1(), 0),
                      trailing: _selectedLabIndex == 0
                        ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeBlue)
                        : const CupertinoListTileChevron(),
                      backgroundColor: _selectedLabIndex == 0
                        ? CupertinoColors.systemBlue.withOpacity(0.1)
                        : null,
                    ),
                    CupertinoListTile(
                      title: const Text('РК 1А - Оптимизатор Adam'),
                      subtitle: const Text('Визуализация градиентного спуска'),
                      onTap: () => _navigateToLab(const rk1a.RK1A(), 1),
                      trailing: _selectedLabIndex == 1
                        ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeBlue)
                        : const CupertinoListTileChevron(),
                      backgroundColor: _selectedLabIndex == 1
                        ? CupertinoColors.systemBlue.withOpacity(0.1)
                        : null,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _currentLab,
            ),
          ],
        ),
      ),
    );
  }
}
