import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class GoBackendService {
  Process? _process;
  static const String _executableName = 'go_backend.exe';

  Future<String> _extractAsset() async {
    try {
      final ByteData data = await rootBundle.load('bin/$_executableName');
      final Uint8List bytes = data.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final exePath = path.join(tempDir.path, _executableName);
      final file = File(exePath);
      await file.writeAsBytes(bytes);

      debugPrint('Extracted Go backend to: $exePath');
      return exePath;
    } catch (e) {
      debugPrint('Failed to extract asset: $e');
      rethrow;
    }
  }

  String _findExePath() {
    debugPrint('=== Go Backend Service Debug ===');
    debugPrint('Platform.resolvedExecutable: ${Platform.resolvedExecutable}');
    debugPrint('Directory.current.path: ${Directory.current.path}');

    final List<String> searchPaths = [];

    if (Platform.resolvedExecutable.isNotEmpty) {
      final exeDir = path.dirname(Platform.resolvedExecutable);
      searchPaths.add(path.join(exeDir, _executableName));
    }

    final currentDirPath = path.join(Directory.current.path, _executableName);
    searchPaths.add(currentDirPath);

    var current = Directory.current.path;
    for (int i = 0; i < 4; i++) {
      final parentPath = path.join(current, _executableName);
      searchPaths.add(parentPath);
      final parent = path.dirname(current);
      if (parent == current) break;
      current = parent;
    }

    debugPrint('All search paths:');
    for (final p in searchPaths) {
      final exists = File(p).existsSync();
      debugPrint('  $p - exists: $exists');
    }

    for (final exePath in searchPaths) {
      if (File(exePath).existsSync()) {
        debugPrint('Found executable at: $exePath');
        return exePath;
      }
    }

    debugPrint('WARNING: go_backend.exe not found');
    return searchPaths.first;
  }

  Future<void> start() async {
    String exePath;

    // Try to find existing exe first
    final existingPath = _findExePath();
    if (File(existingPath).existsSync()) {
      exePath = existingPath;
      debugPrint('Using existing executable: $exePath');
    } else {
      // Extract from asset
      debugPrint('No existing executable found, extracting from asset...');
      exePath = await _extractAsset();
    }

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
