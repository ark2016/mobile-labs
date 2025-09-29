import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // для отображения старых лаб
import 'lab1.dart' as lab1;
import 'lab2.dart' as lab2;
import 'lab4.dart' as lab4;
import 'letuchka3.dart' as letuchka3;
import 'letuchka4.dart' as letuchka4;
import 'lab5/lab51.dart' as lab51;
import 'lab5/lab52.dart' as lab52;
import 'lab5/lab53.dart' as lab53;

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
                    CupertinoListTile(
                      title: const Text('Летучка 3'),
                      onTap: () => _navigateToLab(letuchka3.AuthScreen(), 3),
                      trailing: _selectedLabIndex == 3
                        ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeBlue)
                        : const CupertinoListTileChevron(),
                      backgroundColor: _selectedLabIndex == 3
                        ? CupertinoColors.systemBlue.withOpacity(0.1)
                        : null,
                    ),
                    CupertinoListTile(
                      title: const Text('Летучка 4'),
                      onTap: () => _navigateToLab(letuchka4.MQTTAuthScreen(), 4),
                      trailing: _selectedLabIndex == 4
                        ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeBlue)
                        : const CupertinoListTileChevron(),
                      backgroundColor: _selectedLabIndex == 4
                        ? CupertinoColors.systemBlue.withOpacity(0.1)
                        : null,
                    ),
                    CupertinoListTile(
                      title: const Text('Лаб 5.1'),
                      onTap: () => _navigateToLab(const lab51.Lab51HomePage(title: 'Лаб 5.1 - WebSocket Калькулятор и Ползунок'), 5),
                      trailing: _selectedLabIndex == 5
                        ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeBlue)
                        : const CupertinoListTileChevron(),
                      backgroundColor: _selectedLabIndex == 5
                        ? CupertinoColors.systemBlue.withOpacity(0.1)
                        : null,
                    ),
                    CupertinoListTile(
                      title: const Text('Лаб 5.2'),
                      onTap: () => _navigateToLab(const lab52.Lab52HomePage(title: 'Лаб 5.2 - Python WebSocket Сервер'), 6),
                      trailing: _selectedLabIndex == 6
                        ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeBlue)
                        : const CupertinoListTileChevron(),
                      backgroundColor: _selectedLabIndex == 6
                        ? CupertinoColors.systemBlue.withOpacity(0.1)
                        : null,
                    ),
                    CupertinoListTile(
                      title: const Text('Лаб 5.3'),
                      onTap: () => _navigateToLab(const lab53.Lab53(), 7),
                      trailing: _selectedLabIndex == 7
                        ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeBlue)
                        : const CupertinoListTileChevron(),
                      backgroundColor: _selectedLabIndex == 7
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

