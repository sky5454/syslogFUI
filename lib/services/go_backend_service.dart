import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class GoBackendService {
  Process? _process;

  Future<String> _extractAsset() async {
    final String exeName = Platform.isWindows ? 'go_backend.exe' : 'go_backend';
    final ByteData data = await rootBundle.load('bin/$exeName');
    final Uint8List bytes = data.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final exePath = path.join(tempDir.path, exeName);
    await File(exePath).writeAsBytes(bytes);

    debugPrint('Extracted Go backend to: $exePath');
    return exePath;
  }

  String _findExePath() {
    final exeDir = path.dirname(Platform.resolvedExecutable);
    final String exeName = Platform.isWindows ? 'go_backend.exe' : 'go_backend';
    return path.join(exeDir, 'data', 'flutter_assets', 'bin', exeName);
  }

  Future<void> start(String syslogAddress) async {
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

    debugPrint('Starting Go backend from: $exePath with syslog address: $syslogAddress');

    try {
      _process = await Process.start(exePath, ['--syslog=$syslogAddress', '--protocol=all', '--http=localhost:8765']);

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
