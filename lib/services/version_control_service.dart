import 'dart:async';

import 'package:kre8tions/models/flutter_project.dart';

enum ChangeType { added, modified, deleted, renamed }
enum CommitStatus { staged, unstaged, committed }
enum BranchStatus { local, remote, both }
enum MergeStatus { noConflicts, hasConflicts, merged, failed }

class FileChange {
  final String filePath;
  final ChangeType changeType;
  final CommitStatus status;
  final int linesAdded;
  final int linesDeleted;
  final String? oldFilePath; // For renamed files
  final DateTime modifiedAt;

  const FileChange({
    required this.filePath,
    required this.changeType,
    required this.status,
    this.linesAdded = 0,
    this.linesDeleted = 0,
    this.oldFilePath,
    required this.modifiedAt,
  });

  String get changeIcon {
    switch (changeType) {
      case ChangeType.added:
        return '➕';
      case ChangeType.modified:
        return '✏️';
      case ChangeType.deleted:
        return '❌';
      case ChangeType.renamed:
        return '🔄';
    }
  }

  String get statusIcon {
    switch (status) {
      case CommitStatus.staged:
        return '📋';
      case CommitStatus.unstaged:
        return '📝';
      case CommitStatus.committed:
        return '✅';
    }
  }
}

class GitCommit {
  final String hash;
  final String shortHash;
  final String message;
  final String author;
  final String email;
  final DateTime timestamp;
  final List<FileChange> changes;
  final List<String> tags;
  final String? parentHash;

  const GitCommit({
    required this.hash,
    required this.shortHash,
    required this.message,
    required this.author,
    required this.email,
    required this.timestamp,
    required this.changes,
    this.tags = const [],
    this.parentHash,
  });

  int get totalLinesAdded => changes.fold(0, (sum, change) => sum + change.linesAdded);
  int get totalLinesDeleted => changes.fold(0, (sum, change) => sum + change.linesDeleted);
  int get filesChanged => changes.length;
}

class GitBranch {
  final String name;
  final String fullName;
  final BranchStatus status;
  final String? upstreamBranch;
  final int commitsAhead;
  final int commitsBehind;
  final GitCommit? lastCommit;
  final DateTime? lastModified;
  final bool isCurrent;

  const GitBranch({
    required this.name,
    required this.fullName,
    required this.status,
    this.upstreamBranch,
    this.commitsAhead = 0,
    this.commitsBehind = 0,
    this.lastCommit,
    this.lastModified,
    this.isCurrent = false,
  });

  String get statusIcon {
    if (isCurrent) return '👉';
    switch (status) {
      case BranchStatus.local:
        return '📱';
      case BranchStatus.remote:
        return '☁️';
      case BranchStatus.both:
        return '🔄';
    }
  }
}

class GitRepository {
  final String name;
  final String path;
  final String? remoteUrl;
  final GitBranch currentBranch;
  final List<GitBranch> branches;
  final List<GitCommit> commitHistory;
  final List<FileChange> workingChanges;
  final List<FileChange> stagedChanges;
  final bool hasUncommittedChanges;

  const GitRepository({
    required this.name,
    required this.path,
    this.remoteUrl,
    required this.currentBranch,
    required this.branches,
    required this.commitHistory,
    required this.workingChanges,
    required this.stagedChanges,
    this.hasUncommittedChanges = false,
  });

  int get totalBranches => branches.length;
  int get localBranches => branches.where((b) => b.status == BranchStatus.local).length;
  int get remoteBranches => branches.where((b) => b.status == BranchStatus.remote).length;
}

class MergeConflict {
  final String filePath;
  final List<String> conflictLines;
  final String currentBranchContent;
  final String incomingBranchContent;
  final int startLine;
  final int endLine;

  const MergeConflict({
    required this.filePath,
    required this.conflictLines,
    required this.currentBranchContent,
    required this.incomingBranchContent,
    required this.startLine,
    required this.endLine,
  });
}

class PullRequest {
  final String id;
  final String title;
  final String description;
  final String author;
  final String sourceBranch;
  final String targetBranch;
  final String status; // 'open', 'merged', 'closed'
  final DateTime createdAt;
  final DateTime? mergedAt;
  final List<GitCommit> commits;
  final List<FileChange> changes;
  final int commentsCount;
  final List<String> reviewers;

  const PullRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.sourceBranch,
    required this.targetBranch,
    required this.status,
    required this.createdAt,
    this.mergedAt,
    required this.commits,
    required this.changes,
    this.commentsCount = 0,
    this.reviewers = const [],
  });

  String get statusIcon {
    switch (status) {
      case 'open':
        return '🔓';
      case 'merged':
        return '✅';
      case 'closed':
        return '❌';
      default:
        return '📋';
    }
  }
}

class VersionControlService {
  static final VersionControlService _instance = VersionControlService._internal();
  factory VersionControlService() => _instance;
  VersionControlService._internal();

  final StreamController<GitRepository> _repositoryController = 
      StreamController<GitRepository>.broadcast();
  final StreamController<List<FileChange>> _changesController = 
      StreamController<List<FileChange>>.broadcast();
  final StreamController<GitCommit> _commitController = 
      StreamController<GitCommit>.broadcast();
  final StreamController<String> _statusController = 
      StreamController<String>.broadcast();

  Stream<GitRepository> get repositoryStream => _repositoryController.stream;
  Stream<List<FileChange>> get changesStream => _changesController.stream;
  Stream<GitCommit> get commitStream => _commitController.stream;
  Stream<String> get statusStream => _statusController.stream;

  GitRepository? _currentRepository;
  final List<FileChange> _workingChanges = [];
  final List<FileChange> _stagedChanges = [];

  GitRepository? get currentRepository => _currentRepository;
  List<FileChange> get workingChanges => List.unmodifiable(_workingChanges);
  List<FileChange> get stagedChanges => List.unmodifiable(_stagedChanges);

  // Repository Initialization
  Future<GitRepository> initializeRepository(FlutterProject project) async {
    _log('Initializing Git repository for: ${project.name}');

    // Simulate git init
    await Future.delayed(const Duration(milliseconds: 500));

    // Create main branch
    final mainBranch = GitBranch(
      name: 'main',
      fullName: 'refs/heads/main',
      status: BranchStatus.local,
      isCurrent: true,
      lastModified: DateTime.now(),
    );

    // Create initial commit
    final initialCommit = GitCommit(
      hash: _generateHash(),
      shortHash: _generateHash().substring(0, 7),
      message: 'Initial commit',
      author: 'CodeWhisper User',
      email: 'user@codewhisper.dev',
      timestamp: DateTime.now(),
      changes: [],
    );

    final repository = GitRepository(
      name: project.name,
      path: '/${project.name}',
      currentBranch: mainBranch,
      branches: [mainBranch],
      commitHistory: [initialCommit],
      workingChanges: [],
      stagedChanges: [],
    );

    _currentRepository = repository;
    _repositoryController.add(repository);
    _log('Repository initialized successfully');

    return repository;
  }

  Future<void> cloneRepository(String url, String name) async {
    _log('Cloning repository from: $url');
    
    // Simulate git clone
    await Future.delayed(const Duration(seconds: 2));

    // Create mock repository data
    final branches = [
      GitBranch(
        name: 'main',
        fullName: 'refs/heads/main',
        status: BranchStatus.both,
        upstreamBranch: 'origin/main',
        isCurrent: true,
        lastModified: DateTime.now(),
      ),
      GitBranch(
        name: 'develop',
        fullName: 'refs/heads/develop',
        status: BranchStatus.remote,
        upstreamBranch: 'origin/develop',
        lastModified: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    final commits = _generateMockCommitHistory();

    final repository = GitRepository(
      name: name,
      path: '/$name',
      remoteUrl: url,
      currentBranch: branches.first,
      branches: branches,
      commitHistory: commits,
      workingChanges: [],
      stagedChanges: [],
    );

    _currentRepository = repository;
    _repositoryController.add(repository);
    _log('Repository cloned successfully');
  }

  // File Change Tracking
  void trackFileChanges(FlutterProject project) {
    _log('Tracking file changes...');
    
    // Simulate detecting changes
    _workingChanges.clear();
    _stagedChanges.clear();

    // Mock some changes
    final mockChanges = [
      FileChange(
        filePath: 'lib/main.dart',
        changeType: ChangeType.modified,
        status: CommitStatus.unstaged,
        linesAdded: 5,
        linesDeleted: 2,
        modifiedAt: DateTime.now(),
      ),
      FileChange(
        filePath: 'lib/widgets/new_widget.dart',
        changeType: ChangeType.added,
        status: CommitStatus.unstaged,
        linesAdded: 25,
        modifiedAt: DateTime.now(),
      ),
    ];

    _workingChanges.addAll(mockChanges);
    _changesController.add(_workingChanges);
    _updateRepository();
  }

  Future<void> addFileToStaging(String filePath) async {
    _log('Adding file to staging: $filePath');

    final changeIndex = _workingChanges.indexWhere((change) => change.filePath == filePath);
    if (changeIndex != -1) {
      final change = _workingChanges[changeIndex];
      _workingChanges.removeAt(changeIndex);
      
      _stagedChanges.add(FileChange(
        filePath: change.filePath,
        changeType: change.changeType,
        status: CommitStatus.staged,
        linesAdded: change.linesAdded,
        linesDeleted: change.linesDeleted,
        oldFilePath: change.oldFilePath,
        modifiedAt: change.modifiedAt,
      ));

      _changesController.add(_workingChanges);
      _updateRepository();
      _log('File staged: $filePath');
    }
  }

  Future<void> unstageFile(String filePath) async {
    _log('Unstaging file: $filePath');

    final changeIndex = _stagedChanges.indexWhere((change) => change.filePath == filePath);
    if (changeIndex != -1) {
      final change = _stagedChanges[changeIndex];
      _stagedChanges.removeAt(changeIndex);
      
      _workingChanges.add(FileChange(
        filePath: change.filePath,
        changeType: change.changeType,
        status: CommitStatus.unstaged,
        linesAdded: change.linesAdded,
        linesDeleted: change.linesDeleted,
        oldFilePath: change.oldFilePath,
        modifiedAt: change.modifiedAt,
      ));

      _changesController.add(_workingChanges);
      _updateRepository();
      _log('File unstaged: $filePath');
    }
  }

  Future<void> stageAllChanges() async {
    _log('Staging all changes');

    for (final change in _workingChanges) {
      _stagedChanges.add(FileChange(
        filePath: change.filePath,
        changeType: change.changeType,
        status: CommitStatus.staged,
        linesAdded: change.linesAdded,
        linesDeleted: change.linesDeleted,
        oldFilePath: change.oldFilePath,
        modifiedAt: change.modifiedAt,
      ));
    }

    _workingChanges.clear();
    _changesController.add(_workingChanges);
    _updateRepository();
    _log('All changes staged');
  }

  // Commit Management
  Future<GitCommit> createCommit(String message, {String? author, String? email}) async {
    if (_stagedChanges.isEmpty) {
      throw Exception('No staged changes to commit');
    }

    _log('Creating commit: $message');

    final commit = GitCommit(
      hash: _generateHash(),
      shortHash: _generateHash().substring(0, 7),
      message: message,
      author: author ?? 'CodeWhisper User',
      email: email ?? 'user@codewhisper.dev',
      timestamp: DateTime.now(),
      changes: List.from(_stagedChanges),
      parentHash: _currentRepository?.commitHistory.isNotEmpty == true 
          ? _currentRepository!.commitHistory.first.hash 
          : null,
    );

    // Move staged changes to committed
    final committedChanges = _stagedChanges.map((change) => FileChange(
      filePath: change.filePath,
      changeType: change.changeType,
      status: CommitStatus.committed,
      linesAdded: change.linesAdded,
      linesDeleted: change.linesDeleted,
      oldFilePath: change.oldFilePath,
      modifiedAt: change.modifiedAt,
    )).toList();

    _stagedChanges.clear();
    
    // Add to commit history
    if (_currentRepository != null) {
      final updatedHistory = [commit, ..._currentRepository!.commitHistory];
      _currentRepository = GitRepository(
        name: _currentRepository!.name,
        path: _currentRepository!.path,
        remoteUrl: _currentRepository!.remoteUrl,
        currentBranch: _currentRepository!.currentBranch,
        branches: _currentRepository!.branches,
        commitHistory: updatedHistory,
        workingChanges: _workingChanges,
        stagedChanges: _stagedChanges,
      );
      
      _repositoryController.add(_currentRepository!);
    }

    _commitController.add(commit);
    _changesController.add(_workingChanges);
    _log('Commit created: ${commit.shortHash} - $message');

    return commit;
  }

  List<GitCommit> getCommitHistory({int limit = 50}) {
    return _currentRepository?.commitHistory.take(limit).toList() ?? [];
  }

  GitCommit? getCommit(String hash) {
    return _currentRepository?.commitHistory
        .where((commit) => commit.hash == hash || commit.shortHash == hash)
        .firstOrNull;
  }

  // Branch Management
  Future<GitBranch> createBranch(String branchName, {String? fromCommit}) async {
    _log('Creating branch: $branchName');

    if (_currentRepository == null) {
      throw Exception('No repository initialized');
    }

    // Check if branch already exists
    final existingBranch = _currentRepository!.branches
        .where((branch) => branch.name == branchName)
        .firstOrNull;
    
    if (existingBranch != null) {
      throw Exception('Branch $branchName already exists');
    }

    final newBranch = GitBranch(
      name: branchName,
      fullName: 'refs/heads/$branchName',
      status: BranchStatus.local,
      lastModified: DateTime.now(),
      lastCommit: _currentRepository!.commitHistory.isNotEmpty 
          ? _currentRepository!.commitHistory.first 
          : null,
    );

    final updatedBranches = [..._currentRepository!.branches, newBranch];
    
    _currentRepository = GitRepository(
      name: _currentRepository!.name,
      path: _currentRepository!.path,
      remoteUrl: _currentRepository!.remoteUrl,
      currentBranch: _currentRepository!.currentBranch,
      branches: updatedBranches,
      commitHistory: _currentRepository!.commitHistory,
      workingChanges: _currentRepository!.workingChanges,
      stagedChanges: _currentRepository!.stagedChanges,
    );

    _repositoryController.add(_currentRepository!);
    _log('Branch created: $branchName');

    return newBranch;
  }

  Future<void> switchBranch(String branchName) async {
    _log('Switching to branch: $branchName');

    if (_currentRepository == null) {
      throw Exception('No repository initialized');
    }

    final targetBranch = _currentRepository!.branches
        .where((branch) => branch.name == branchName)
        .firstOrNull;

    if (targetBranch == null) {
      throw Exception('Branch $branchName not found');
    }

    // Update current branch
    final updatedBranches = _currentRepository!.branches.map((branch) {
      return GitBranch(
        name: branch.name,
        fullName: branch.fullName,
        status: branch.status,
        upstreamBranch: branch.upstreamBranch,
        commitsAhead: branch.commitsAhead,
        commitsBehind: branch.commitsBehind,
        lastCommit: branch.lastCommit,
        lastModified: branch.lastModified,
        isCurrent: branch.name == branchName,
      );
    }).toList();

    _currentRepository = GitRepository(
      name: _currentRepository!.name,
      path: _currentRepository!.path,
      remoteUrl: _currentRepository!.remoteUrl,
      currentBranch: targetBranch.copyWith(isCurrent: true),
      branches: updatedBranches,
      commitHistory: _currentRepository!.commitHistory,
      workingChanges: _currentRepository!.workingChanges,
      stagedChanges: _currentRepository!.stagedChanges,
    );

    _repositoryController.add(_currentRepository!);
    _log('Switched to branch: $branchName');
  }

  Future<void> deleteBranch(String branchName) async {
    _log('Deleting branch: $branchName');

    if (_currentRepository == null) {
      throw Exception('No repository initialized');
    }

    if (_currentRepository!.currentBranch.name == branchName) {
      throw Exception('Cannot delete current branch');
    }

    final updatedBranches = _currentRepository!.branches
        .where((branch) => branch.name != branchName)
        .toList();

    _currentRepository = GitRepository(
      name: _currentRepository!.name,
      path: _currentRepository!.path,
      remoteUrl: _currentRepository!.remoteUrl,
      currentBranch: _currentRepository!.currentBranch,
      branches: updatedBranches,
      commitHistory: _currentRepository!.commitHistory,
      workingChanges: _currentRepository!.workingChanges,
      stagedChanges: _currentRepository!.stagedChanges,
    );

    _repositoryController.add(_currentRepository!);
    _log('Branch deleted: $branchName');
  }

  // Merge Operations
  Future<MergeStatus> mergeBranch(String sourceBranch, String targetBranch) async {
    _log('Merging $sourceBranch into $targetBranch');

    // Simulate merge process
    await Future.delayed(const Duration(milliseconds: 1000));

    // Random merge result for simulation
    final hasConflicts = DateTime.now().millisecond % 3 == 0; // ~33% chance of conflicts

    if (hasConflicts) {
      _log('Merge conflicts detected');
      return MergeStatus.hasConflicts;
    } else {
      _log('Merge completed successfully');
      
      // Create merge commit
      await createCommit('Merge branch \'$sourceBranch\' into $targetBranch');
      
      return MergeStatus.merged;
    }
  }

  List<MergeConflict> getMergeConflicts() {
    // Mock merge conflicts for demonstration
    return [
      const MergeConflict(
        filePath: 'lib/main.dart',
        conflictLines: [
          '<<<<<<< HEAD',
          '  title: "My App",',
          '=======',
          '  title: "CodeWhisper App",',
          '>>>>>>> feature/new-title',
        ],
        currentBranchContent: '  title: "My App",',
        incomingBranchContent: '  title: "CodeWhisper App",',
        startLine: 15,
        endLine: 15,
      ),
    ];
  }

  Future<void> resolveConflict(String filePath, String resolution) async {
    _log('Resolving conflict in: $filePath');
    
    // Simulate conflict resolution
    await Future.delayed(const Duration(milliseconds: 500));
    
    _log('Conflict resolved in: $filePath');
  }

  // Remote Operations
  Future<void> push({String? remoteName, String? branchName}) async {
    remoteName ??= 'origin';
    branchName ??= _currentRepository?.currentBranch.name ?? 'main';
    
    _log('Pushing to $remoteName/$branchName...');
    
    // Simulate push
    await Future.delayed(const Duration(seconds: 2));
    
    _log('Push completed successfully');
  }

  Future<void> pull({String? remoteName, String? branchName}) async {
    remoteName ??= 'origin';
    branchName ??= _currentRepository?.currentBranch.name ?? 'main';
    
    _log('Pulling from $remoteName/$branchName...');
    
    // Simulate pull
    await Future.delayed(const Duration(seconds: 1));
    
    // Add some mock incoming commits
    final incomingCommits = _generateMockCommitHistory(count: 2);
    
    if (_currentRepository != null) {
      final updatedHistory = [...incomingCommits, ..._currentRepository!.commitHistory];
      
      _currentRepository = GitRepository(
        name: _currentRepository!.name,
        path: _currentRepository!.path,
        remoteUrl: _currentRepository!.remoteUrl,
        currentBranch: _currentRepository!.currentBranch,
        branches: _currentRepository!.branches,
        commitHistory: updatedHistory,
        workingChanges: _currentRepository!.workingChanges,
        stagedChanges: _currentRepository!.stagedChanges,
      );
      
      _repositoryController.add(_currentRepository!);
    }
    
    _log('Pull completed successfully');
  }

  Future<void> fetch({String? remoteName}) async {
    remoteName ??= 'origin';
    
    _log('Fetching from $remoteName...');
    
    // Simulate fetch
    await Future.delayed(const Duration(milliseconds: 800));
    
    _log('Fetch completed successfully');
  }

  // Utility Methods
  List<GitCommit> _generateMockCommitHistory({int count = 10}) {
    final commits = <GitCommit>[];
    final messages = [
      'Fix navigation bug in home screen',
      'Add user authentication service',
      'Update UI components styling',
      'Implement data caching mechanism',
      'Add unit tests for user service',
      'Fix memory leak in image loader',
      'Update dependencies to latest versions',
      'Improve app performance',
      'Add dark theme support',
      'Fix crash on startup',
    ];

    final authors = [
      {'name': 'Alice Johnson', 'email': 'alice@example.com'},
      {'name': 'Bob Smith', 'email': 'bob@example.com'},
      {'name': 'Charlie Brown', 'email': 'charlie@example.com'},
    ];

    for (int i = 0; i < count; i++) {
      final author = authors[i % authors.length];
      final timestamp = DateTime.now().subtract(Duration(days: i, hours: i * 2));
      
      commits.add(GitCommit(
        hash: _generateHash(),
        shortHash: _generateHash().substring(0, 7),
        message: messages[i % messages.length],
        author: author['name']!,
        email: author['email']!,
        timestamp: timestamp,
        changes: _generateMockFileChanges(),
        parentHash: i < count - 1 ? _generateHash() : null,
      ));
    }

    return commits;
  }

  List<FileChange> _generateMockFileChanges() {
    final files = [
      'lib/main.dart',
      'lib/screens/home_screen.dart',
      'lib/services/auth_service.dart',
      'lib/widgets/custom_button.dart',
      'lib/models/user.dart',
    ];

    final changeTypes = [ChangeType.added, ChangeType.modified, ChangeType.deleted];
    final changes = <FileChange>[];

    final changeCount = 1 + DateTime.now().millisecond % 3; // 1-3 changes
    
    for (int i = 0; i < changeCount; i++) {
      changes.add(FileChange(
        filePath: files[i % files.length],
        changeType: changeTypes[i % changeTypes.length],
        status: CommitStatus.committed,
        linesAdded: DateTime.now().microsecond % 20,
        linesDeleted: DateTime.now().microsecond % 10,
        modifiedAt: DateTime.now(),
      ));
    }

    return changes;
  }

  String _generateHash() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.toString() + DateTime.now().microsecond.toString();
    return random.hashCode.toRadixString(16).padLeft(40, '0');
  }

  void _updateRepository() {
    if (_currentRepository != null) {
      _currentRepository = GitRepository(
        name: _currentRepository!.name,
        path: _currentRepository!.path,
        remoteUrl: _currentRepository!.remoteUrl,
        currentBranch: _currentRepository!.currentBranch,
        branches: _currentRepository!.branches,
        commitHistory: _currentRepository!.commitHistory,
        workingChanges: _workingChanges,
        stagedChanges: _stagedChanges,
        hasUncommittedChanges: _workingChanges.isNotEmpty || _stagedChanges.isNotEmpty,
      );
      
      _repositoryController.add(_currentRepository!);
    }
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] Git: $message';
    _statusController.add(logMessage);
  }

  // Diff utilities
  String generateDiff(String oldContent, String newContent) {
    final oldLines = oldContent.split('\n');
    final newLines = newContent.split('\n');
    final diff = StringBuffer();

    diff.writeln('--- a/file');
    diff.writeln('+++ b/file');
    
    // Simple diff implementation
    final maxLines = oldLines.length > newLines.length ? oldLines.length : newLines.length;
    
    for (int i = 0; i < maxLines; i++) {
      final oldLine = i < oldLines.length ? oldLines[i] : null;
      final newLine = i < newLines.length ? newLines[i] : null;
      
      if (oldLine == null) {
        diff.writeln('+$newLine');
      } else if (newLine == null) {
        diff.writeln('-$oldLine');
      } else if (oldLine != newLine) {
        diff.writeln('-$oldLine');
        diff.writeln('+$newLine');
      } else {
        diff.writeln(' $oldLine');
      }
    }
    
    return diff.toString();
  }

  void dispose() {
    _repositoryController.close();
    _changesController.close();
    _commitController.close();
    _statusController.close();
  }
}

extension GitBranchExtension on GitBranch {
  GitBranch copyWith({
    String? name,
    String? fullName,
    BranchStatus? status,
    String? upstreamBranch,
    int? commitsAhead,
    int? commitsBehind,
    GitCommit? lastCommit,
    DateTime? lastModified,
    bool? isCurrent,
  }) {
    return GitBranch(
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      status: status ?? this.status,
      upstreamBranch: upstreamBranch ?? this.upstreamBranch,
      commitsAhead: commitsAhead ?? this.commitsAhead,
      commitsBehind: commitsBehind ?? this.commitsBehind,
      lastCommit: lastCommit ?? this.lastCommit,
      lastModified: lastModified ?? this.lastModified,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}