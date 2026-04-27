import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bloc/syslog_bloc.dart';
import 'services/websocket_service.dart';
import 'services/go_backend_service.dart';
import 'theme/app_theme.dart';
import 'widgets/toolbar_widget.dart';
import 'widgets/log_display_widget.dart';
import 'widgets/filter_panel_widget.dart';
import 'widgets/status_bar_widget.dart';
import 'widgets/log_panel_widget.dart';
import 'bloc/syslog_event.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final savedSyslogAddress = prefs.getString('syslog_address') ?? '0.0.0.0:514';
  final savedWebsocketUrl = prefs.getString('websocket_url') ?? 'ws://localhost:8765/ws';

  print('Loaded syslog_address from prefs: $savedSyslogAddress');
  print('Loaded websocket_url from prefs: $savedWebsocketUrl');

  runApp(SyslogViewerApp(
    savedSyslogAddress: savedSyslogAddress,
    savedWebsocketUrl: savedWebsocketUrl,
  ));
}

class SyslogViewerApp extends StatelessWidget {
  final String savedSyslogAddress;
  final String savedWebsocketUrl;

  const SyslogViewerApp({
    super.key,
    required this.savedSyslogAddress,
    required this.savedWebsocketUrl,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SyslogFUI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: BlocProvider(
        create: (context) => SyslogBloc(
          webSocketService: WebSocketService(),
          goBackendService: GoBackendService(),
          savedSyslogAddress: savedSyslogAddress,
          savedWebsocketUrl: savedWebsocketUrl,
        )..add(ConnectEvent()),
        child: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _showConsoleLogs = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              ToolbarWidget(),
              Expanded(
                child: Row(
                  children: [
                    FilterPanelWidget(),
                    Expanded(
                      child: LogDisplayWidget(),
                    ),
                  ],
                ),
              ),
              StatusBarWidget(
                onConsoleLogsPressed: () {
                  setState(() {
                    _showConsoleLogs = !_showConsoleLogs;
                  });
                },
                isConsoleLogsExpanded: _showConsoleLogs,
              ),
            ],
          ),
          if (_showConsoleLogs)
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: ConsoleLogsPanel(
                onClear: () {
                  context.read<SyslogBloc>().goBackendService.clearLogs();
                },
                onClose: () {
                  setState(() {
                    _showConsoleLogs = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
