import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class GoBackendService {
  Process? _process;
  final _logController = StreamController<String>.broadcast();
  static const int _maxLogLines = 500;
  final List<String> _logLines = [];

  Stream<String> get logStream => _logController.stream;
  List<String> get logLines => List.unmodifiable(_logLines);

  void _addLog(String line) {
    _logLines.add(line);
    if (_logLines.length > _maxLogLines) {
      _logLines.removeAt(0);
    }
    _logController.add(line);
  }

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
      _addLog('[INFO] Using existing executable: $exePath');
    } else {
      // Extract from asset
      _addLog('[INFO] No existing executable found, extracting from asset...');
      exePath = await _extractAsset();
    }

    _addLog('[INFO] Starting Go backend from: $exePath with syslog address: $syslogAddress');

    try {
      _process = await Process.start(exePath, ['--syslog=$syslogAddress', '--protocol=all', '--http=localhost:8765']);

      _process!.stderr.transform(const SystemEncoding().decoder).listen((data) {
        _addLog('[ERROR] $data');
      });

      _process!.stdout.transform(const SystemEncoding().decoder).listen((data) {
        _addLog('[INFO] $data');
      });

      // Wait for HTTP server to be ready by polling
      final httpReady = await _waitForHttpServer('localhost', 8765, timeout: const Duration(seconds: 10));
      if (!httpReady) {
        _addLog('[ERROR] Go backend HTTP server failed to start - port 8765 may still be in use');
        throw Exception('Go backend HTTP server failed to start');
      }

      _addLog('[INFO] Go backend started successfully with PID: ${_process!.pid}');
    } catch (e) {
      _addLog('[ERROR] Failed to start Go backend: $e');
      rethrow;
    }
  }

  Future<bool> _waitForHttpServer(String host, int port, {required Duration timeout}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final socket = await Socket.connect(host, port, timeout: const Duration(milliseconds: 500));
        socket.destroy();
        return true;
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    return false;
  }

  Future<void> stop() async {
    if (_process != null) {
      _addLog('[INFO] Stopping Go backend (PID: ${_process!.pid})');
      _process!.kill(ProcessSignal.sigkill);
      await _process!.exitCode;
      _process = null;
      await Future.delayed(const Duration(milliseconds: 500));
      _addLog('[INFO] Go backend stopped');
    }
  }

  void clearLogs() {
    _logLines.clear();
  }

  bool get isRunning => _process != null;

  void dispose() {
    _logController.close();
  }
}
