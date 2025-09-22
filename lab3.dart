import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // для отображения старых лаб
import 'lab1.dart' as lab1;
import 'lab2.dart' as lab2;
import 'lab4.dart' as lab4;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Labs Demo',
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
  Widget _currentLab = const lab1.MyHomePage(title: 'Lab 1');
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
        middle: Text('Лабораторные работы'),
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
                      title: const Text('Лаб 1'),
                      onTap: () => _navigateToLab(const lab1.MyHomePage(title: 'Lab 1'), 0),
                      trailing: _selectedLabIndex == 0
                        ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeBlue)
                        : const CupertinoListTileChevron(),
                      backgroundColor: _selectedLabIndex == 0
                        ? CupertinoColors.systemBlue.withOpacity(0.1)
                        : null,
                    ),
                    CupertinoListTile(
                      title: const Text('Лаб 2'),
                      onTap: () => _navigateToLab(const lab2.MyHomePage(title: 'Lab 2'), 1),
                      trailing: _selectedLabIndex == 1
                        ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeBlue)
                        : const CupertinoListTileChevron(),
                      backgroundColor: _selectedLabIndex == 1
                        ? CupertinoColors.systemBlue.withOpacity(0.1)
                        : null,
                    ),
                    CupertinoListTile(
                      title: const Text('Лаб 4'),
                      onTap: () => _navigateToLab(const lab4.MyHomePage(title: 'Lab 4'), 2),
                      trailing: _selectedLabIndex == 2
                        ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeBlue)
                        : const CupertinoListTileChevron(),
                      backgroundColor: _selectedLabIndex == 2
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

