import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'study_screen.dart';
import 'exam_gate_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';
import '../core/theme.dart';
import '../core/app_localizations.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  int refreshEpoch = 0;

  void _setTab(int value) => setState(() {
        index = value;
        refreshEpoch++;
      });

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(key: ValueKey('home-$refreshEpoch'), onTabRequested: _setTab),
      StudyScreen(key: ValueKey('study-$refreshEpoch'), embedded: true),
      ExamGateScreen(key: ValueKey('exam-$refreshEpoch'), embedded: true),
      StatsScreen(key: ValueKey('stats-$refreshEpoch'), embedded: true),
      ProfileScreen(key: ValueKey('profile-$refreshEpoch')),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: index,
        onDestinationSelected: _setTab,
        destinations: [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: TxColors.red), label: TxText.t('home')),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded, color: TxColors.red), label: TxText.t('lessons')),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment_rounded, color: TxColors.red), label: TxText.t('exams')),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded, color: TxColors.red), label: TxText.t('stats')),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: TxColors.red), label: TxText.t('profile')),
        ],
      ),
    );
  }
}
