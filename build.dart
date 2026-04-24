import 'dart:io';

void main(List<String> args) async {
  print('=== Build Script ===\n');

  // Step 1: Build Go backend
  print('Step 1: Building Go backend...');
  final goResult = await Process.run('go', ['build', '-o', 'bin/syslog_viewer.exe', '.'], workingDirectory: 'go');
  if (goResult.exitCode != 0) {
    print('Error building Go: ${goResult.stderr}');
    exit(1);
  }
  print('Go backend built: go/bin/syslog_viewer.exe');

  // Step 2: Copy to Flutter directories
  print('\nStep 2: Copying to Flutter directories...');

  // Kill any running instances of the app
  print('Killing any running instances...');
  if (Platform.isWindows) {
    await Process.run('taskkill', ['/F', '/IM', 'go_backend.exe']);
    await Process.run('taskkill', ['/F', '/IM', 'syslog_viewer.exe']);
    await Future.delayed(Duration(milliseconds: 200));
  }

  final sourceFile = File('go/bin/syslog_viewer.exe');

  Future<void> copyWithRetry(String dest) async {
    for (int i = 0; i < 3; i++) {
      try {
        final bytes = await sourceFile.readAsBytes();
        final destFile = File(dest);
        await destFile.writeAsBytes(bytes, mode: FileMode.write);
        return;
      } catch (e) {
        if (i == 2) rethrow;
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
  }

  await copyWithRetry('build/windows/x64/runner/Debug/go_backend.exe');
  await copyWithRetry('build/windows/x64/runner/Release/go_backend.exe');
  print('Copied to Release and Debug directories');

  // Step 3: Build Flutter
  print('\nStep 3: Building Flutter...');
  String buildType = args.contains('--debug') ? 'debug' : 'release';

  // Find flutter using where
  String flutterCmd = Platform.isWindows ? 'flutter.bat' : 'flutter';
  if (Platform.isWindows) {
    final whereResult = await Process.run('where', ['flutter']);
    if (whereResult.exitCode == 0) {
      final paths = (whereResult.stdout as String).trim().split('\n');
      if (paths.isNotEmpty) {
        String path = paths.first.trim();
        if (!path.endsWith('.bat')) {
          path = '$path.bat';
        }
        flutterCmd = path;
      }
    }
  }

  final flutterResult = await Process.run(flutterCmd, ['build', 'windows', '--$buildType']);
  if (flutterResult.exitCode != 0) {
    print('Error building Flutter: ${flutterResult.stderr}');
    exit(1);
  }
  print('Flutter $buildType built successfully');

  print('\n=== Build Complete ===');
  print('');
  print('=== How to Run ===');
  print('');
  print('Run the built application:');
  print('  build\\windows\\x64\\runner\\Release\\syslogfui.exe');
  print('');
  print('Or run from project root:');
  print('  .\\build\\windows\\x64\\runner\\Release\\syslogfui.exe');
  print('');
  print('Debug build:');
  print('  .\\build\\windows\\x64\\runner\\Debug\\syslogfui.exe');
}
