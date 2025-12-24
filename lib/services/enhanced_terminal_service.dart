import 'dart:async';

import 'package:kre8tions/models/flutter_project.dart';

enum CommandStatus {
  running,
  success,
  error,
  cancelled,
}

class TerminalCommand {
  final String id;
  final String command;
  final DateTime timestamp;
  final CommandStatus status;
  final List<String> output;
  final int? exitCode;

  TerminalCommand({
    required this.id,
    required this.command,
    required this.timestamp,
    required this.status,
    required this.output,
    this.exitCode,
  });

  TerminalCommand copyWith({
    CommandStatus? status,
    List<String>? output,
    int? exitCode,
  }) {
    return TerminalCommand(
      id: id,
      command: command,
      timestamp: timestamp,
      status: status ?? this.status,
      output: output ?? this.output,
      exitCode: exitCode ?? this.exitCode,
    );
  }
}

class EnhancedTerminalService {
  static final EnhancedTerminalService _instance = EnhancedTerminalService._internal();
  factory EnhancedTerminalService() => _instance;
  EnhancedTerminalService._internal();

  final List<TerminalCommand> _history = [];
  final StreamController<TerminalCommand> _commandStreamController = StreamController.broadcast();
  final Map<String, Timer> _runningCommands = {};

  Stream<TerminalCommand> get commandStream => _commandStreamController.stream;
  List<TerminalCommand> get history => List.unmodifiable(_history);

  // Flutter/Dart specific commands that work in web environment
  final Map<String, Function(FlutterProject?, List<String>)> _webCompatibleCommands = {
    'help': _handleHelp,
    'clear': _handleClear,
    'ls': _handleList,
    'pwd': _handlePwd,
    'echo': _handleEcho,
    'flutter': _handleFlutter,
    'dart': _handleDart,
    'pub': _handlePub,
    'analyze': _handleAnalyze,
    'build': _handleBuild,
    'run': _handleRun,
    'test': _handleTest,
    'clean': _handleClean,
    'doctor': _handleDoctor,
    'devices': _handleDevices,
    'upgrade': _handleUpgrade,
    'config': _handleConfig,
  };

  Future<TerminalCommand> executeCommand(
    String command, 
    FlutterProject? project
  ) async {
    final parts = command.trim().split(' ');
    final baseCommand = parts.isNotEmpty ? parts[0].toLowerCase() : '';
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];

    final terminalCommand = TerminalCommand(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      command: command,
      timestamp: DateTime.now(),
      status: CommandStatus.running,
      output: [],
    );

    _history.add(terminalCommand);
    _commandStreamController.add(terminalCommand);

    try {
      if (_webCompatibleCommands.containsKey(baseCommand)) {
        final result = await _webCompatibleCommands[baseCommand]!(project, args);
        final completedCommand = terminalCommand.copyWith(
          status: CommandStatus.success,
          output: result,
          exitCode: 0,
        );
        
        _updateCommand(completedCommand);
        return completedCommand;
      } else {
        // Handle unknown commands
        final errorOutput = [
          'Command not found: $baseCommand',
          'Type "help" to see available commands.',
        ];
        
        final errorCommand = terminalCommand.copyWith(
          status: CommandStatus.error,
          output: errorOutput,
          exitCode: 127,
        );
        
        _updateCommand(errorCommand);
        return errorCommand;
      }
    } catch (e) {
      final errorCommand = terminalCommand.copyWith(
        status: CommandStatus.error,
        output: ['Error executing command: $e'],
        exitCode: 1,
      );
      
      _updateCommand(errorCommand);
      return errorCommand;
    }
  }

  void _updateCommand(TerminalCommand updatedCommand) {
    final index = _history.indexWhere((cmd) => cmd.id == updatedCommand.id);
    if (index != -1) {
      _history[index] = updatedCommand;
      _commandStreamController.add(updatedCommand);
    }
  }

  void clearHistory() {
    _history.clear();
  }

  // Command handlers
  static Future<List<String>> _handleHelp(FlutterProject? project, List<String> args) async {
    return [
      'CodeWhisper Enhanced Terminal - Available Commands:',
      '',
      '📁 File Operations:',
      '  ls                    List files in current directory',
      '  pwd                   Show current working directory',
      '',
      '🚀 Flutter Commands:',
      '  flutter doctor        Check Flutter installation',
      '  flutter devices       List connected devices',
      '  flutter run           Run the app (simulated)',
      '  flutter build web     Build for web (simulated)',
      '  flutter clean         Clean build cache',
      '  flutter upgrade       Upgrade Flutter (simulated)',
      '',
      '🎯 Dart Commands:',
      '  dart analyze          Analyze Dart code',
      '  dart test             Run tests',
      '  dart pub get          Get dependencies',
      '  dart pub upgrade      Upgrade dependencies',
      '',
      '🔧 Project Commands:',
      '  analyze              Quick analysis of current project',
      '  build <platform>     Build for platform (web, android, ios)',
      '  test                 Run project tests',
      '  clean                Clean project',
      '',
      '💡 Utility Commands:',
      '  echo <text>          Echo text to terminal',
      '  clear                Clear terminal history',
      '  help                 Show this help message',
      '',
      'Note: This terminal is web-safe and simulates Flutter/Dart commands.',
    ];
  }

  static Future<List<String>> _handleClear(FlutterProject? project, List<String> args) async {
    EnhancedTerminalService().clearHistory();
    return ['Terminal cleared.'];
  }

  static Future<List<String>> _handleList(FlutterProject? project, List<String> args) async {
    if (project == null) {
      return ['No project loaded.'];
    }

    final output = <String>[];
    output.add('Project files:');
    
    for (final file in project.files) {
      final icon = file.path.endsWith('.dart') ? '📄' : '📁';
      output.add('  $icon ${file.fileName}');
    }

    if (project.files.isEmpty) {
      output.add('  (no files found)');
    }

    return output;
  }

  static Future<List<String>> _handlePwd(FlutterProject? project, List<String> args) async {
    return ['/project/${project?.name ?? 'unnamed'}'];
  }

  static Future<List<String>> _handleEcho(FlutterProject? project, List<String> args) async {
    return [args.join(' ')];
  }

  static Future<List<String>> _handleFlutter(FlutterProject? project, List<String> args) async {
    if (args.isEmpty) {
      return [
        'Flutter 3.22.0 • channel stable',
        'Tools • Dart 3.4.0 • DevTools 2.34.3',
        '',
        'Run "flutter help" for usage information.',
      ];
    }

    final subcommand = args[0].toLowerCase();
    final subArgs = args.length > 1 ? args.sublist(1) : <String>[];

    switch (subcommand) {
      case 'doctor':
        return _handleDoctor(project, subArgs);
      case 'devices':
        return _handleDevices(project, subArgs);
      case 'run':
        return _handleRun(project, subArgs);
      case 'build':
        return _handleBuild(project, subArgs);
      case 'clean':
        return _handleClean(project, subArgs);
      case 'upgrade':
        return _handleUpgrade(project, subArgs);
      default:
        return ['Unknown flutter command: $subcommand'];
    }
  }

  static Future<List<String>> _handleDart(FlutterProject? project, List<String> args) async {
    if (args.isEmpty) {
      return [
        'Dart SDK version: 3.4.0 (stable)',
        '',
        'Usage: dart <command> [options]',
        'Run "dart help" for more information.',
      ];
    }

    final subcommand = args[0].toLowerCase();
    final subArgs = args.length > 1 ? args.sublist(1) : <String>[];

    switch (subcommand) {
      case 'analyze':
        return _handleAnalyze(project, subArgs);
      case 'test':
        return _handleTest(project, subArgs);
      case 'pub':
        return _handlePub(project, subArgs);
      default:
        return ['Unknown dart command: $subcommand'];
    }
  }

  static Future<List<String>> _handlePub(FlutterProject? project, List<String> args) async {
    if (args.isEmpty) {
      return ['Usage: dart pub <command> [options]'];
    }

    final subcommand = args[0].toLowerCase();

    switch (subcommand) {
      case 'get':
        return [
          'Running "flutter pub get" in ${project?.name ?? 'project'}...',
          'Resolving dependencies...',
          '✓ Dependencies resolved successfully',
          'Got dependencies!',
        ];
      case 'upgrade':
        return [
          'Running "flutter pub upgrade" in ${project?.name ?? 'project'}...',
          'Resolving dependencies...',
          '✓ All dependencies are up to date!',
        ];
      case 'deps':
        return [
          'Dependencies for ${project?.name ?? 'project'}:',
          '- flutter: sdk',
          '- cupertino_icons: ^1.0.8',
          '- device_preview: ^1.0.0',
          '- url_launcher: ^6.0.0',
        ];
      default:
        return ['Unknown pub command: $subcommand'];
    }
  }

  static Future<List<String>> _handleAnalyze(FlutterProject? project, List<String> args) async {
    if (project == null) {
      return ['No project loaded to analyze.'];
    }

    return [
      'Analyzing ${project.name}...',
      '',
      '🔍 Running static analysis...',
      '✓ No issues found in lib/',
      '✓ Code follows Flutter style guidelines',
      '✓ No unused imports detected',
      '',
      'Analysis complete • No issues found • ${project.files.length} files analyzed',
    ];
  }

  static Future<List<String>> _handleBuild(FlutterProject? project, List<String> args) async {
    final platform = args.isNotEmpty ? args[0] : 'web';
    
    return [
      'Building Flutter app for $platform...',
      '',
      '🔨 Compiling Dart code...',
      '📦 Bundling assets...',
      '🚀 Optimizing for production...',
      '',
      '✅ Build complete!',
      'Output: build/$platform/',
    ];
  }

  static Future<List<String>> _handleRun(FlutterProject? project, List<String> args) async {
    final device = args.isNotEmpty ? args[0] : 'chrome';
    
    return [
      'Launching ${project?.name ?? 'app'} on $device...',
      '',
      '🚀 Starting development server...',
      '📱 App running on http://localhost:8080',
      '',
      '💡 Hot reload enabled - press "r" to reload',
      '🔄 Hot restart enabled - press "R" to restart',
      '🛑 Press "q" to quit',
    ];
  }

  static Future<List<String>> _handleTest(FlutterProject? project, List<String> args) async {
    return [
      'Running tests for ${project?.name ?? 'project'}...',
      '',
      '🧪 test/widget_test.dart',
      '✅ All tests passed! (1 test, 0 skipped)',
      '',
      'Test run complete • 1 passed • 0 failed • 0 skipped',
    ];
  }

  static Future<List<String>> _handleClean(FlutterProject? project, List<String> args) async {
    return [
      'Cleaning build cache...',
      '',
      '🧹 Removing build/ directory',
      '🧹 Cleaning pub cache',
      '🧹 Removing .dart_tool/',
      '',
      '✅ Clean complete!',
    ];
  }

  static Future<List<String>> _handleDoctor(FlutterProject? project, List<String> args) async {
    return [
      'Doctor summary (to see all details, run flutter doctor -v):',
      '',
      '[✓] Flutter (Channel stable, 3.22.0, on macOS 14.0)',
      '[✓] Android toolchain - develop for Android devices',
      '[✓] Xcode - develop for iOS and macOS',
      '[✓] Chrome - develop for the web',
      '[✓] Android Studio',
      '[✓] VS Code',
      '[✓] Connected device (3 available)',
      '',
      '• No issues found!',
    ];
  }

  static Future<List<String>> _handleDevices(FlutterProject? project, List<String> args) async {
    return [
      'Available devices:',
      '',
      'Chrome (web) • chrome • web-javascript • Google Chrome 119.0',
      'iPhone 15 Pro (mobile) • ios-sim • ios • iOS 17.0 (simulator)',
      'Pixel 7 (mobile) • android-sim • android • Android 13 (emulator)',
      '',
      '3 connected devices',
    ];
  }

  static Future<List<String>> _handleUpgrade(FlutterProject? project, List<String> args) async {
    return [
      'Checking for Flutter updates...',
      '',
      '✅ Flutter is already up to date!',
      'Flutter 3.22.0 • channel stable',
      '',
      'Run "flutter doctor" to verify installation.',
    ];
  }

  static Future<List<String>> _handleConfig(FlutterProject? project, List<String> args) async {
    return [
      'Flutter configuration:',
      '',
      'flutter-root: /opt/flutter',
      'flutter-version: 3.22.0',
      'dart-version: 3.4.0',
      'pub-cache: ~/.pub-cache',
      '',
      'Web support: enabled',
      'Analytics: enabled',
    ];
  }

  void dispose() {
    _commandStreamController.close();
    for (final timer in _runningCommands.values) {
      timer.cancel();
    }
    _runningCommands.clear();
  }
}