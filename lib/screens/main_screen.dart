import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'ai_screen.dart';
import 'analytics_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with WidgetsBindingObserver {
  int index = 0;

  final screens = const [
    HomeScreen(),
    AnalyticsScreen(),
    AiScreen(),
    ProfileScreen(),
  ];

  DateTime? _lastResumePeriodStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastResumePeriodStart = AppState.instance.currentPeriod.start;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state != AppLifecycleState.resumed) return;

    final periodStart =
        AppState.instance.currentPeriod.start;

    if (_lastResumePeriodStart == null ||
        _lastResumePeriodStart != periodStart) {
      _lastResumePeriodStart = periodStart;
      // Re-materialize the new period's recurring expenses whenever the app
      // comes back to the foreground. Existing working state is preserved;
      // this only adds newly due recurring occurrences when a period arrives.
      AppState.instance.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) =>
            setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'Advisor',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
