import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class GoBackendService {
  Process? _process;
  static const String _executableName = 'go_backend.exe';

  String _findExePath() {
    debugPrint('=== Go Backend Service Debug ===');
    debugPrint('Platform.resolvedExecutable: ${Platform.resolvedExecutable}');
    debugPrint('Directory.current.path: ${Directory.current.path}');

    // Try multiple possible locations
    final List<String> searchPaths = [];

    // 1. Same directory as the main executable
    if (Platform.resolvedExecutable.isNotEmpty) {
      final exeDir = path.dirname(Platform.resolvedExecutable);
      searchPaths.add(path.join(exeDir, _executableName));
      debugPrint('Added path (exe dir): ${path.join(exeDir, _executableName)}');
    }

    // 2. Current working directory
    final currentDirPath = path.join(Directory.current.path, _executableName);
    searchPaths.add(currentDirPath);
    debugPrint('Added path (current dir): $currentDirPath');

    // 3. Parent directories of current directory
    var current = Directory.current.path;
    for (int i = 0; i < 4; i++) {
      final parentPath = path.join(current, _executableName);
      searchPaths.add(parentPath);
      debugPrint('Added path (parent $i): $parentPath');
      final parent = path.dirname(current);
      if (parent == current) break;
      current = parent;
    }

    // Print all search paths for debugging
    debugPrint('All search paths:');
    for (final p in searchPaths) {
      final exists = File(p).existsSync();
      debugPrint('  $p - exists: $exists');
    }

    // Return first existing path
    for (final exePath in searchPaths) {
      if (File(exePath).existsSync()) {
        debugPrint('Found executable at: $exePath');
        return exePath;
      }
    }

    debugPrint('WARNING: go_backend.exe not found, returning first search path');
    // Return default path (will fail later)
    return searchPaths.first;
  }

  Future<void> start() async {
    final exePath = _findExePath();

    debugPrint('Starting Go backend from: $exePath');

    try {
      _process = await Process.start(exePath, ['--syslog=localhost:514', '--protocol=all', '--http=localhost:8765']);

      _process!.stderr.transform(const SystemEncoding().decoder).listen((data) {
        debugPrint('Go stderr: $data');
      });

      _process!.stdout.transform(const SystemEncoding().decoder).listen((data) {
        debugPrint('Go stdout: $data');
      });

      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Failed to start Go backend: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    _process?.kill();
    _process = null;
  }

  bool get isRunning => _process != null;
}
