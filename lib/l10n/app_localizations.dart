import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

abstract class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? instance(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Syslog Viewer',
      'startServer': 'Start Server',
      'stopServer': 'Stop Server',
      'clearLogs': 'Clear Logs',
      'exportCsv': 'Export CSV',
      'autoScroll': 'Auto-scroll',
      'select': 'Select',
      'copy': 'Copy',
      'top': 'Top',
      'bottom': 'Bottom',
      'filters': 'Filters',
      'searchMessages': 'Search messages...',
      'severity': 'Severity',
      'facility': 'Facility',
      'resetFilters': 'Reset Filters',
      'noLogMessages': 'No log messages yet',
      'noMessagesMatchFilter': 'No messages match the current filter',
      'messages': 'messages',
      'shown': 'shown',
      'connected': 'Connected',
      'connecting': 'Connecting...',
      'disconnected': 'Disconnected',
      'error': 'Error',
      'localhost514Udp': 'localhost:514 (UDP)',
      'wsLocalhost8765Ws': 'ws://localhost:8765/ws',
      'syslogAddress': 'Syslog Address',
      'websocketUrl': 'WebSocket URL',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'exportSuccessful': 'Export successful',
      'exportFailed': 'Export failed',
      'openFolder': 'Open Folder',
      'clear': 'Clear',
      'filter': 'Filter',
      'highlight': 'Highlight',
      'of': 'of',
    },
    'zh': {
      'appTitle': 'Syslog 查看器',
      'startServer': '启动服务器',
      'stopServer': '停止服务器',
      'clearLogs': '清除日志',
      'exportCsv': '导出 CSV',
      'autoScroll': '自动滚动',
      'select': '选择',
      'copy': '复制',
      'top': '顶部',
      'bottom': '底部',
      'filters': '过滤器',
      'searchMessages': '搜索消息...',
      'severity': '严重级别',
      'facility': '设施',
      'resetFilters': '重置过滤器',
      'noLogMessages': '暂无日志消息',
      'noMessagesMatchFilter': '没有符合当前过滤条件的消息',
      'messages': '条消息',
      'shown': '显示',
      'connected': '已连接',
      'connecting': '连接中...',
      'disconnected': '已断开',
      'error': '错误',
      'localhost514Udp': 'localhost:514 (UDP)',
      'wsLocalhost8765Ws': 'ws://localhost:8765/ws',
      'syslogAddress': 'Syslog 地址',
      'websocketUrl': 'WebSocket URL',
      'cancel': '取消',
      'confirm': '确定',
      'exportSuccessful': '导出成功',
      'exportFailed': '导出失败',
      'openFolder': '打开文件夹',
      'clear': '清除',
      'filter': '过滤',
      'highlight': '高亮',
      'of': '/',
    },
  };

  String _translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  String get appTitle => _translate('appTitle');
  String get startServer => _translate('startServer');
  String get stopServer => _translate('stopServer');
  String get clearLogs => _translate('clearLogs');
  String get exportCsv => _translate('exportCsv');
  String get autoScroll => _translate('autoScroll');
  String get select => _translate('select');
  String get copy => _translate('copy');
  String get top => _translate('top');
  String get bottom => _translate('bottom');
  String get filters => _translate('filters');
  String get searchMessages => _translate('searchMessages');
  String get severity => _translate('severity');
  String get facility => _translate('facility');
  String get resetFilters => _translate('resetFilters');
  String get noLogMessages => _translate('noLogMessages');
  String get noMessagesMatchFilter => _translate('noMessagesMatchFilter');
  String get messages => _translate('messages');
  String get shown => _translate('shown');
  String get connected => _translate('connected');
  String get connecting => _translate('connecting');
  String get disconnected => _translate('disconnected');
  String get error => _translate('error');
  String get localhost514Udp => _translate('localhost514Udp');
  String get wsLocalhost8765Ws => _translate('wsLocalhost8765Ws');
  String get syslogAddress => _translate('syslogAddress');
  String get websocketUrl => _translate('websocketUrl');
  String get cancel => _translate('cancel');
  String get confirm => _translate('confirm');
  String get exportSuccessful => _translate('exportSuccessful');
  String get exportFailed => _translate('exportFailed');
  String get openFolder => _translate('openFolder');
  String get copiedLinesToClipboard => _translate('copiedLinesToClipboard');
  String selected(int count) =>
      locale.languageCode == 'zh' ? '已选择 $count 项' : '$count selected';
  String get clear => _translate('clear');
  String get filter => _translate('filter');
  String get highlight => _translate('highlight');
  String get of => _translate('of');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(_AppLocalizationsImpl(locale));
  }

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class _AppLocalizationsImpl extends AppLocalizations {
  _AppLocalizationsImpl(Locale locale) : super(locale);
}