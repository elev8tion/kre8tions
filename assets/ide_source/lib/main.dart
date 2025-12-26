import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kre8tions/theme.dart';
import 'package:kre8tions/screens/home_page.dart';
import 'package:kre8tions/services/app_state_manager.dart';
import 'package:kre8tions/services/ide_inspector_service.dart';
import 'package:kre8tions/widgets/precise_widget_selector.dart';
import 'package:kre8tions/utils/performance_monitor.dart';

void main() {
  PerformanceMonitor.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppStateManager _stateManager = AppStateManager();
  final IDEInspectorService _ideInspector = IDEInspectorService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _stateManager,
      builder: (context, child) {
        return MaterialApp(
          title: 'KRE8TIONS IDE - AI Flutter Editor',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.dark,
          home: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              // Global keyboard shortcut: F2 to toggle IDE inspector
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.f2) {
                _ideInspector.toggle();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: PreciseWidgetSelector(
              child: HomePage(stateManager: _stateManager),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _stateManager.forceSave();
    PerformanceMonitor.dispose();
    super.dispose();
  }
}
