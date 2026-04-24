import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'bloc/syslog_bloc.dart';
import 'services/websocket_service.dart';
import 'services/go_backend_service.dart';
import 'theme/app_theme.dart';
import 'widgets/toolbar_widget.dart';
import 'widgets/log_display_widget.dart';
import 'widgets/filter_panel_widget.dart';
import 'widgets/status_bar_widget.dart';
import 'bloc/syslog_event.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const SyslogViewerApp());
}

class SyslogViewerApp extends StatelessWidget {
  const SyslogViewerApp({super.key});

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
        )..add(ConnectEvent()),
        child: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: const [
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
          StatusBarWidget(),
        ],
      ),
    );
  }
}
