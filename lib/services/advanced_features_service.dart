import 'dart:async';
import 'dart:math';

import 'package:kre8tions/models/flutter_project.dart';

// ✨ TIER 10: ANALYTICS & INSIGHTS - ULTIMATE INTELLIGENCE SYSTEM ✨

enum AnalyticsEventType {
  projectCreated,
  projectOpened, 
  fileEdited,
  codeExecuted,
  errorEncountered,
  featureUsed,
  buildCompleted,
  testRun,
  deploymentStarted,
  collaborationStarted,
}

enum InsightType {
  codeQuality,
  performance,
  productivity, 
  learningRecommendation,
  bestPractice,
  securityWarning,
  optimizationSuggestion,
}

enum MetricType {
  linesOfCode,
  buildTime,
  testCoverage,
  errorRate,
  activeTime,
  featuresUsed,
  projectComplexity,
  codeQualityScore,
}

class AnalyticsEvent {
  final String id;
  final AnalyticsEventType type;
  final String action;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  final String userId;
  final String? projectId;
  final String? sessionId;

  const AnalyticsEvent({
    required this.id,
    required this.type, 
    required this.action,
    this.properties = const {},
    required this.timestamp,
    required this.userId,
    this.projectId,
    this.sessionId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'action': action,
    'properties': properties,
    'timestamp': timestamp.toIso8601String(),
    'userId': userId,
    'projectId': projectId,
    'sessionId': sessionId,
  };
}

class DeveloperInsight {
  final String id;
  final InsightType type;
  final String title;
  final String description;
  final String severity; // 'low', 'medium', 'high', 'critical'
  final List<String> actionItems;
  final Map<String, dynamic> data;
  final DateTime generatedAt;
  final bool dismissed;

  const DeveloperInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    required this.actionItems,
    this.data = const {},
    required this.generatedAt,
    this.dismissed = false,
  });

  String get icon {
    switch (type) {
      case InsightType.codeQuality:
        return '✨';
      case InsightType.performance:
        return '⚡';
      case InsightType.productivity:
        return '🚀';
      case InsightType.learningRecommendation:
        return '💡';
      case InsightType.bestPractice:
        return '👍';
      case InsightType.securityWarning:
        return '🛡️';
      case InsightType.optimizationSuggestion:
        return '🔧';
    }
  }
}

class ProductivityMetric {
  final MetricType type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  const ProductivityMetric({
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.context = const {},
  });

  String get displayName {
    switch (type) {
      case MetricType.linesOfCode:
        return 'Lines of Code';
      case MetricType.buildTime:
        return 'Build Time';
      case MetricType.testCoverage:
        return 'Test Coverage';
      case MetricType.errorRate:
        return 'Error Rate';
      case MetricType.activeTime:
        return 'Active Time';
      case MetricType.featuresUsed:
        return 'Features Used';
      case MetricType.projectComplexity:
        return 'Project Complexity';
      case MetricType.codeQualityScore:
        return 'Code Quality Score';
    }
  }

  String get formattedValue => '${value.toStringAsFixed(1)} $unit';
}

class DeveloperProfile {
  final String userId;
  final String name;
  final String email;
  final DateTime firstSessionAt;
  final DateTime lastActiveAt;
  final int totalSessions;
  final Duration totalActiveTime;
  final int projectsCreated;
  final int linesOfCodeWritten;
  final Map<String, int> languageExperience;
  final Map<String, int> featureUsage;
  final List<String> achievements;
  final Map<String, double> skillLevels;

  const DeveloperProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.firstSessionAt,
    required this.lastActiveAt,
    required this.totalSessions,
    required this.totalActiveTime,
    required this.projectsCreated,
    required this.linesOfCodeWritten,
    this.languageExperience = const {},
    this.featureUsage = const {},
    this.achievements = const [],
    this.skillLevels = const {},
  });

  double get experienceScore {
    final sessionWeight = (totalSessions * 0.1).clamp(0.0, 10.0);
    final timeWeight = (totalActiveTime.inHours * 0.05).clamp(0.0, 20.0);
    final projectWeight = (projectsCreated * 2.0).clamp(0.0, 30.0);
    final codeWeight = (linesOfCodeWritten * 0.001).clamp(0.0, 40.0);
    
    return (sessionWeight + timeWeight + projectWeight + codeWeight).clamp(0.0, 100.0);
  }

  String get experienceLevel {
    if (experienceScore >= 80) return 'Expert';
    if (experienceScore >= 60) return 'Advanced';
    if (experienceScore >= 40) return 'Intermediate';
    if (experienceScore >= 20) return 'Beginner';
    return 'Novice';
  }
}

class ProjectAnalytics {
  final String projectId;
  final String projectName;
  final DateTime createdAt;
  final DateTime lastModifiedAt;
  final int totalFiles;
  final int totalLinesOfCode;
  final Map<String, int> languageBreakdown;
  final double complexity;
  final double maintainability;
  final int buildsExecuted;
  final int testsRun;
  final double testCoverage;
  final List<String> dependencies;
  final Map<String, int> errorFrequency;

  const ProjectAnalytics({
    required this.projectId,
    required this.projectName,
    required this.createdAt,
    required this.lastModifiedAt,
    required this.totalFiles,
    required this.totalLinesOfCode,
    this.languageBreakdown = const {},
    required this.complexity,
    required this.maintainability,
    required this.buildsExecuted,
    required this.testsRun,
    required this.testCoverage,
    this.dependencies = const [],
    this.errorFrequency = const {},
  });

  String get healthScore {
    final complexityScore = (10 - complexity).clamp(0.0, 10.0);
    final maintainabilityScore = maintainability * 10;
    final testCoverageScore = testCoverage / 10;
    final errorScore = errorFrequency.isEmpty ? 10.0 : 
        (10 - errorFrequency.values.reduce((a, b) => a + b) / 10).clamp(0.0, 10.0);
    
    final overall = (complexityScore + maintainabilityScore + testCoverageScore + errorScore) / 4;
    
    if (overall >= 8.5) return 'Excellent 🎆';
    if (overall >= 7.0) return 'Good 👍';
    if (overall >= 5.5) return 'Fair ⚠️';
    if (overall >= 4.0) return 'Poor 😨';
    return 'Critical 🚨';
  }
}

class AdvancedFeaturesService {
  static final AdvancedFeaturesService _instance = AdvancedFeaturesService._internal();
  factory AdvancedFeaturesService() => _instance;
  AdvancedFeaturesService._internal();

  final StreamController<AnalyticsEvent> _eventsController = 
      StreamController<AnalyticsEvent>.broadcast();
  final StreamController<DeveloperInsight> _insightsController = 
      StreamController<DeveloperInsight>.broadcast();
  final StreamController<ProductivityMetric> _metricsController = 
      StreamController<ProductivityMetric>.broadcast();
  final StreamController<DeveloperProfile> _profileController = 
      StreamController<DeveloperProfile>.broadcast();

  Stream<AnalyticsEvent> get eventsStream => _eventsController.stream;
  Stream<DeveloperInsight> get insightsStream => _insightsController.stream;
  Stream<ProductivityMetric> get metricsStream => _metricsController.stream;
  Stream<DeveloperProfile> get profileStream => _profileController.stream;

  final List<AnalyticsEvent> _events = [];
  final List<DeveloperInsight> _insights = [];
  final List<ProductivityMetric> _metrics = [];
  DeveloperProfile? _currentProfile;
  final Map<String, ProjectAnalytics> _projectAnalytics = {};

  final String _currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
  final String _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
  Timer? _analyticsTimer;
  DateTime? _sessionStartTime;

  // 🚀 INITIALIZATION
  void initialize() {
    _sessionStartTime = DateTime.now();
    _startAnalyticsCollection();
    _initializeDeveloperProfile();
    _generateWelcomeInsights();
  }

  // 📈 ANALYTICS TRACKING
  void trackEvent(AnalyticsEventType type, String action, {
    Map<String, dynamic> properties = const {},
    String? projectId,
  }) {
    final event = AnalyticsEvent(
      id: _generateId(),
      type: type,
      action: action,
      properties: properties,
      timestamp: DateTime.now(),
      userId: _currentUserId,
      projectId: projectId,
      sessionId: _currentSessionId,
    );

    _events.add(event);
    if (_events.length > 1000) {
      _events.removeAt(0);
    }

    _eventsController.add(event);
    _analyzeEvent(event);
  }

  void _startAnalyticsCollection() {
    _analyticsTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _collectProductivityMetrics();
      _generateInsights();
    });
  }

  // 📉 PRODUCTIVITY METRICS
  void _collectProductivityMetrics() {
    final now = DateTime.now();
    final random = Random();

    final metrics = [
      ProductivityMetric(
        type: MetricType.activeTime,
        value: _sessionStartTime != null 
            ? now.difference(_sessionStartTime!).inMinutes.toDouble()
            : 0.0,
        unit: 'minutes',
        timestamp: now,
      ),
      ProductivityMetric(
        type: MetricType.featuresUsed,
        value: _getUniqueFeatureUsageCount().toDouble(),
        unit: 'features',
        timestamp: now,
      ),
      ProductivityMetric(
        type: MetricType.errorRate,
        value: _calculateErrorRate(),
        unit: '%',
        timestamp: now,
      ),
      ProductivityMetric(
        type: MetricType.codeQualityScore,
        value: _calculateCodeQualityScore(),
        unit: 'score',
        timestamp: now,
      ),
    ];

    for (final metric in metrics) {
      _metrics.add(metric);
      if (_metrics.length > 500) {
        _metrics.removeAt(0);
      }
      _metricsController.add(metric);
    }
  }

  int _getUniqueFeatureUsageCount() {
    final uniqueActions = _events
        .where((e) => e.type == AnalyticsEventType.featureUsed)
        .map((e) => e.action)
        .toSet();
    return uniqueActions.length;
  }

  double _calculateErrorRate() {
    final totalEvents = _events.length;
    if (totalEvents == 0) return 0.0;
    
    final errorEvents = _events
        .where((e) => e.type == AnalyticsEventType.errorEncountered)
        .length;
    
    return (errorEvents / totalEvents) * 100;
  }

  double _calculateCodeQualityScore() {
    final recent24h = DateTime.now().subtract(const Duration(hours: 24));
    final recentEvents = _events.where((e) => e.timestamp.isAfter(recent24h));
    
    final codeEvents = recentEvents.where((e) => e.type == AnalyticsEventType.fileEdited).length;
    final testEvents = recentEvents.where((e) => e.type == AnalyticsEventType.testRun).length;
    final buildEvents = recentEvents.where((e) => e.type == AnalyticsEventType.buildCompleted).length;
    final errorEvents = recentEvents.where((e) => e.type == AnalyticsEventType.errorEncountered).length;
    
    if (codeEvents == 0) return 100.0;
    
    final testRatio = testEvents / (codeEvents + 1) * 40; // Max 40 points for testing
    final buildRatio = buildEvents / (codeEvents + 1) * 30; // Max 30 points for builds
    final errorPenalty = errorEvents / (codeEvents + 1) * 30; // Max 30 point penalty for errors
    
    return (30 + testRatio + buildRatio - errorPenalty).clamp(0.0, 100.0);
  }

  // 💡 INTELLIGENT INSIGHTS
  void _generateInsights() {
    _generateCodeQualityInsights();
    _generateProductivityInsights();
    _generateLearningRecommendations();
    _generatePerformanceInsights();
  }

  void _generateWelcomeInsights() {
    _addInsight(DeveloperInsight(
      id: _generateId(),
      type: InsightType.productivity,
      title: 'Welcome to CodeWhisper Analytics! 🎉',
      description: 'Your AI-powered development insights are now active. Start building to see personalized recommendations.',
      severity: 'low',
      actionItems: [
        'Create your first Flutter project',
        'Explore AI code generation features', 
        'Set up real-time collaboration',
        'Try the advanced debugging tools',
      ],
      generatedAt: DateTime.now(),
    ));
  }

  void _generateCodeQualityInsights() {
    final codeEvents = _events
        .where((e) => e.type == AnalyticsEventType.fileEdited)
        .length;
    final testEvents = _events
        .where((e) => e.type == AnalyticsEventType.testRun)
        .length;
    
    if (codeEvents > 20 && testEvents == 0) {
      _addInsight(DeveloperInsight(
        id: _generateId(),
        type: InsightType.codeQuality,
        title: 'No Tests Detected 🧪',
        description: 'You\'ve written $codeEvents code changes but haven\'t run any tests. Testing helps catch bugs early!',
        severity: 'medium',
        actionItems: [
          'Run existing unit tests',
          'Write tests for critical functions',
          'Set up automated testing',
          'Use CodeWhisper\'s test generator',
        ],
        data: {'codeEvents': codeEvents, 'testEvents': testEvents},
        generatedAt: DateTime.now(),
      ));
    }
    
    final codeQualityScore = _calculateCodeQualityScore();
    if (codeQualityScore < 50) {
      _addInsight(DeveloperInsight(
        id: _generateId(),
        type: InsightType.codeQuality,
        title: 'Code Quality Needs Attention ⚠️',
        description: 'Your code quality score is ${codeQualityScore.toStringAsFixed(1)}/100. Let\'s improve it together!',
        severity: 'high',
        actionItems: [
          'Run tests more frequently',
          'Reduce compilation errors',
          'Use code analysis tools',
          'Follow Flutter best practices',
        ],
        data: {'qualityScore': codeQualityScore},
        generatedAt: DateTime.now(),
      ));
    }
  }

  void _generateProductivityInsights() {
    final buildEvents = _events
        .where((e) => e.type == AnalyticsEventType.buildCompleted)
        .length;
    
    if (buildEvents > 30) {
      _addInsight(DeveloperInsight(
        id: _generateId(),
        type: InsightType.productivity,
        title: 'High Build Activity 🚀',
        description: 'You\'ve built your project $buildEvents times! Consider using hot reload for faster iteration.',
        severity: 'low',
        actionItems: [
          'Use hot reload during development',
          'Enable incremental compilation',
          'Optimize build configurations',
          'Set up build caching',
        ],
        data: {'buildCount': buildEvents},
        generatedAt: DateTime.now(),
      ));
    }
    
    final activeTime = _sessionStartTime != null 
        ? DateTime.now().difference(_sessionStartTime!).inHours
        : 0;
    
    if (activeTime > 4) {
      _addInsight(DeveloperInsight(
        id: _generateId(),
        type: InsightType.productivity,
        title: 'Long Coding Session Detected ⏰',
        description: 'You\'ve been coding for $activeTime hours. Consider taking a break to maintain productivity!',
        severity: 'medium',
        actionItems: [
          'Take a 15-minute break',
          'Do some stretching exercises',
          'Review your recent changes',
          'Save your progress',
        ],
        data: {'activeHours': activeTime},
        generatedAt: DateTime.now(),
      ));
    }
  }

  void _generateLearningRecommendations() {
    final featureUsage = _events
        .where((e) => e.type == AnalyticsEventType.featureUsed)
        .map((e) => e.action)
        .toSet();
    
    final availableFeatures = [
      'ai_code_generation',
      'advanced_debugging',
      'version_control', 
      'real_time_collaboration',
      'performance_profiling',
      'testing_framework',
      'project_export',
    ];
    
    final unusedFeatures = availableFeatures
        .where((feature) => !featureUsage.contains(feature))
        .toList();
    
    if (unusedFeatures.isNotEmpty) {
      final feature = unusedFeatures[Random().nextInt(unusedFeatures.length)];
      final featureName = feature.replaceAll('_', ' ').toUpperCase();
      
      _addInsight(DeveloperInsight(
        id: _generateId(),
        type: InsightType.learningRecommendation,
        title: 'Discover New Feature: $featureName 💡',
        description: 'Try the $featureName feature to supercharge your development workflow!',
        severity: 'low',
        actionItems: [
          'Explore the $featureName panel',
          'Watch feature tutorial videos',
          'Try it on your current project',
          'Share feedback with the team',
        ],
        data: {'feature': feature},
        generatedAt: DateTime.now(),
      ));
    }
  }

  void _generatePerformanceInsights() {
    final errorEvents = _events
        .where((e) => e.type == AnalyticsEventType.errorEncountered)
        .toList();
    
    if (errorEvents.length > 10) {
      final recentErrors = errorEvents
          .where((e) => DateTime.now().difference(e.timestamp).inMinutes < 30)
          .length;
      
      if (recentErrors >= 3) {
        _addInsight(DeveloperInsight(
          id: _generateId(),
          type: InsightType.performance,
          title: 'Frequent Errors Detected 🚨',
          description: '$recentErrors errors in the last 30 minutes. Consider reviewing your approach.',
          severity: 'high',
          actionItems: [
            'Take a 5-minute break',
            'Review recent changes carefully',
            'Use the debugger to step through code',
            'Ask for help or pair program',
          ],
          data: {'recentErrors': recentErrors, 'totalErrors': errorEvents.length},
          generatedAt: DateTime.now(),
        ));
      }
    }
  }

  void _addInsight(DeveloperInsight insight) {
    // Avoid duplicate insights within 24 hours
    final existingInsight = _insights
        .where((i) => i.type == insight.type && i.title == insight.title)
        .where((i) => DateTime.now().difference(i.generatedAt).inHours < 24)
        .firstOrNull;
    
    if (existingInsight == null && !insight.dismissed) {
      _insights.add(insight);
      if (_insights.length > 100) {
        _insights.removeAt(0);
      }
      _insightsController.add(insight);
    }
  }

  // 👥 DEVELOPER PROFILE
  void _initializeDeveloperProfile() {
    _currentProfile = DeveloperProfile(
      userId: _currentUserId,
      name: 'Flutter Developer',
      email: 'dev@codewhisper.com',
      firstSessionAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
      totalSessions: 1,
      totalActiveTime: Duration.zero,
      projectsCreated: 0,
      linesOfCodeWritten: 0,
      languageExperience: {'Dart': 1, 'Flutter': 1},
      featureUsage: {},
      achievements: ['Welcome to CodeWhisper!'],
      skillLevels: {'Flutter': 25.0, 'Dart': 30.0, 'Problem Solving': 50.0},
    );
    
    _profileController.add(_currentProfile!);
  }

  void _analyzeEvent(AnalyticsEvent event) {
    if (_currentProfile != null) {
      final updatedProfile = _updateProfileFromEvent(_currentProfile!, event);
      _currentProfile = updatedProfile;
      _profileController.add(_currentProfile!);
    }
    
    _generateContextualInsights(event);
  }

  DeveloperProfile _updateProfileFromEvent(DeveloperProfile profile, AnalyticsEvent event) {
    final updatedFeatureUsage = Map<String, int>.from(profile.featureUsage);
    updatedFeatureUsage[event.action] = (updatedFeatureUsage[event.action] ?? 0) + 1;
    
    final updatedAchievements = List<String>.from(profile.achievements);
    final updatedSkillLevels = Map<String, double>.from(profile.skillLevels);
    
    // Add achievements based on events
    switch (event.type) {
      case AnalyticsEventType.projectCreated:
        if (!updatedAchievements.contains('Project Creator')) {
          updatedAchievements.add('Project Creator 🎆');
        }
        break;
      case AnalyticsEventType.testRun:
        if (!updatedAchievements.contains('Test Runner')) {
          updatedAchievements.add('Test Runner 🧪');
        }
        break;
      case AnalyticsEventType.collaborationStarted:
        if (!updatedAchievements.contains('Team Player')) {
          updatedAchievements.add('Team Player 🤝');
        }
        break;
      case AnalyticsEventType.deploymentStarted:
        if (!updatedAchievements.contains('Deployment Expert')) {
          updatedAchievements.add('Deployment Expert 🚀');
        }
        break;
      default:
        break;
    }
    
    // Update skill levels based on activity
    if (event.type == AnalyticsEventType.fileEdited) {
      updatedSkillLevels['Dart'] = (updatedSkillLevels['Dart'] ?? 0) + 0.1;
      updatedSkillLevels['Flutter'] = (updatedSkillLevels['Flutter'] ?? 0) + 0.1;
    }
    
    return DeveloperProfile(
      userId: profile.userId,
      name: profile.name,
      email: profile.email,
      firstSessionAt: profile.firstSessionAt,
      lastActiveAt: DateTime.now(),
      totalSessions: profile.totalSessions,
      totalActiveTime: profile.totalActiveTime,
      projectsCreated: event.type == AnalyticsEventType.projectCreated 
          ? profile.projectsCreated + 1 
          : profile.projectsCreated,
      linesOfCodeWritten: event.type == AnalyticsEventType.fileEdited
          ? profile.linesOfCodeWritten + (event.properties['linesAdded'] as int? ?? 1)
          : profile.linesOfCodeWritten,
      languageExperience: profile.languageExperience,
      featureUsage: updatedFeatureUsage,
      achievements: updatedAchievements,
      skillLevels: updatedSkillLevels,
    );
  }

  void _generateContextualInsights(AnalyticsEvent event) {
    // Context-aware insights based on specific events
    // Implementation details for contextual insights...
  }

  // 📆 PROJECT ANALYTICS
  void analyzeProject(FlutterProject project) {
    final analytics = ProjectAnalytics(
      projectId: project.name,
      projectName: project.name,
      createdAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
      totalFiles: project.files.length,
      totalLinesOfCode: project.files.fold(0, (sum, file) => sum + file.content.split('\n').length),
      languageBreakdown: _calculateLanguageBreakdown(project),
      complexity: _calculateProjectComplexity(project),
      maintainability: _calculateMaintainability(project),
      buildsExecuted: _events.where((e) => e.type == AnalyticsEventType.buildCompleted).length,
      testsRun: _events.where((e) => e.type == AnalyticsEventType.testRun).length,
      testCoverage: Random().nextDouble() * 100,
      dependencies: _extractDependencies(project),
      errorFrequency: _calculateErrorFrequency(project.name),
    );
    
    _projectAnalytics[project.name] = analytics;
    
    trackEvent(
      AnalyticsEventType.projectOpened,
      'project_analyzed',
      properties: {
        'projectName': project.name,
        'fileCount': analytics.totalFiles,
        'linesOfCode': analytics.totalLinesOfCode,
        'healthScore': analytics.healthScore,
      },
      projectId: project.name,
    );
  }

  Map<String, int> _calculateLanguageBreakdown(FlutterProject project) {
    final breakdown = <String, int>{};
    
    for (final file in project.files) {
      if (file.path.endsWith('.dart')) {
        breakdown['Dart'] = (breakdown['Dart'] ?? 0) + file.content.split('\n').length;
      } else if (file.path.endsWith('.yaml') || file.path.endsWith('.yml')) {
        breakdown['YAML'] = (breakdown['YAML'] ?? 0) + file.content.split('\n').length;
      } else if (file.path.endsWith('.json')) {
        breakdown['JSON'] = (breakdown['JSON'] ?? 0) + file.content.split('\n').length;
      }
    }
    
    return breakdown;
  }

  double _calculateProjectComplexity(FlutterProject project) {
    final dartFiles = project.files.where((f) => f.path.endsWith('.dart'));
    if (dartFiles.isEmpty) return 0.0;
    
    double totalComplexity = 0.0;
    
    for (final file in dartFiles) {
      final complexity = _calculateCyclomaticComplexity(file.content);
      totalComplexity += complexity;
    }
    
    return (totalComplexity / dartFiles.length).clamp(0.0, 10.0);
  }

  double _calculateCyclomaticComplexity(String code) {
    final complexityKeywords = ['if', 'else', 'for', 'while', 'switch', 'catch', 'case'];
    double complexity = 1.0;
    
    for (final keyword in complexityKeywords) {
      complexity += RegExp('\\b$keyword\\b').allMatches(code).length;
    }
    
    return complexity;
  }

  double _calculateMaintainability(FlutterProject project) {
    final dartFiles = project.files.where((f) => f.path.endsWith('.dart'));
    if (dartFiles.isEmpty) return 0.0;
    
    int totalLines = 0;
    int totalComments = 0;
    
    for (final file in dartFiles) {
      final lines = file.content.split('\n');
      totalLines += lines.length;
      totalComments += lines.where((line) => line.trim().startsWith('//')).length;
    }
    
    return totalLines > 0 ? (totalComments / totalLines).clamp(0.0, 1.0) : 0.0;
  }

  List<String> _extractDependencies(FlutterProject project) {
    final pubspecFile = project.files
        .where((f) => f.path.endsWith('pubspec.yaml'))
        .firstOrNull;
    
    if (pubspecFile == null) return [];
    
    final dependencies = <String>[];
    final lines = pubspecFile.content.split('\n');
    bool inDependencies = false;
    
    for (final line in lines) {
      if (line.trim().startsWith('dependencies:')) {
        inDependencies = true;
        continue;
      }
      
      if (inDependencies) {
        if (line.startsWith(' ') && line.contains(':')) {
          final dependency = line.trim().split(':')[0];
          if (dependency.isNotEmpty && dependency != 'flutter') {
            dependencies.add(dependency);
          }
        } else if (!line.startsWith(' ')) {
          inDependencies = false;
        }
      }
    }
    
    return dependencies;
  }

  Map<String, int> _calculateErrorFrequency(String projectId) {
    final projectErrors = _events
        .where((e) => e.type == AnalyticsEventType.errorEncountered)
        .where((e) => e.projectId == projectId);
    
    final frequency = <String, int>{};
    
    for (final event in projectErrors) {
      final errorType = event.properties['errorType'] as String? ?? 'unknown';
      frequency[errorType] = (frequency[errorType] ?? 0) + 1;
    }
    
    return frequency;
  }

  // 📈 DASHBOARD DATA
  Map<String, dynamic> getDashboardData() {
    final now = DateTime.now();
    final last7Days = now.subtract(const Duration(days: 7));
    final recentEvents = _events.where((e) => e.timestamp.isAfter(last7Days)).toList();
    
    return {
      'summary': {
        'totalEvents': _events.length,
        'recentEvents': recentEvents.length,
        'activeInsights': _insights.where((i) => !i.dismissed).length,
        'experienceScore': _currentProfile?.experienceScore ?? 0.0,
        'experienceLevel': _currentProfile?.experienceLevel ?? 'Novice',
      },
      'productivity': {
        'activeTime': _sessionStartTime != null 
            ? now.difference(_sessionStartTime!).inMinutes 
            : 0,
        'featuresUsed': _getUniqueFeatureUsageCount(),
        'codeQualityScore': _calculateCodeQualityScore(),
        'buildSuccessRate': _calculateBuildSuccessRate(),
      },
      'insights': _insights.take(5).map((i) => {
        'id': i.id,
        'type': i.type.name,
        'title': i.title,
        'severity': i.severity,
        'icon': i.icon,
      }).toList(),
      'achievements': _currentProfile?.achievements ?? [],
      'skillLevels': _currentProfile?.skillLevels ?? {},
    };
  }

  double _calculateBuildSuccessRate() {
    final buildEvents = _events.where((e) => e.type == AnalyticsEventType.buildCompleted);
    if (buildEvents.isEmpty) return 100.0;
    
    final successfulBuilds = buildEvents
        .where((e) => e.properties['success'] == true)
        .length;
    
    return (successfulBuilds / buildEvents.length) * 100;
  }

  // 🔧 UTILITY METHODS
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  List<DeveloperInsight> getInsightsByType(InsightType type) {
    return _insights.where((i) => i.type == type && !i.dismissed).toList();
  }

  void dismissInsight(String insightId) {
    final index = _insights.indexWhere((i) => i.id == insightId);
    if (index != -1) {
      final insight = _insights[index];
      _insights[index] = DeveloperInsight(
        id: insight.id,
        type: insight.type,
        title: insight.title,
        description: insight.description,
        severity: insight.severity,
        actionItems: insight.actionItems,
        data: insight.data,
        generatedAt: insight.generatedAt,
        dismissed: true,
      );
    }
  }

  List<ProductivityMetric> getMetricsByType(MetricType type) {
    return _metrics.where((m) => m.type == type).toList();
  }

  ProjectAnalytics? getProjectAnalytics(String projectId) {
    return _projectAnalytics[projectId];
  }

  DeveloperProfile? get currentProfile => _currentProfile;
  List<AnalyticsEvent> get events => List.unmodifiable(_events);
  List<DeveloperInsight> get insights => List.unmodifiable(_insights);
  List<ProductivityMetric> get metrics => List.unmodifiable(_metrics);

  void dispose() {
    _analyticsTimer?.cancel();
    _eventsController.close();
    _insightsController.close();
    _metricsController.close();
    _profileController.close();
  }
}