import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/syslog_message.dart';
import '../services/websocket_service.dart';
import '../services/go_backend_service.dart';
import 'syslog_event.dart';
import 'syslog_state.dart';

class SyslogBloc extends Bloc<SyslogEvent, SyslogState> {
  final WebSocketService _webSocketService;
  final GoBackendService _goBackendService;
  StreamSubscription<SyslogMessage>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  final List<SyslogMessage> _messages = [];
  static const int _maxMessages = 100000;

  SyslogBloc({
    required WebSocketService webSocketService,
    required GoBackendService goBackendService,
    String? savedSyslogAddress,
    String? savedWebsocketUrl,
  })  : _webSocketService = webSocketService,
        _goBackendService = goBackendService,
        super(SyslogState(
          syslogAddress: savedSyslogAddress ?? '0.0.0.0:514',
          websocketUrl: savedWebsocketUrl ?? 'ws://localhost:8765/ws',
        )) {
    on<ConnectEvent>(_onConnect);
    on<DisconnectEvent>(_onDisconnect);
    on<ConnectionStatusChangedEvent>(_onConnectionStatusChanged);
    on<MessageReceivedEvent>(_onMessageReceived);
    on<ClearMessagesEvent>(_onClearMessages);
    on<SetAutoScrollEvent>(_onSetAutoScroll);
    on<FilterChangedEvent>(_onFilterChanged);
    on<ExportMessagesEvent>(_onExportMessages);
    on<ServerConfigChangedEvent>(_onServerConfigChanged);
    on<ToggleMultiSelectEvent>(_onToggleMultiSelect);
    on<ToggleSelectionEvent>(_onToggleSelection);
    on<ClearSelectionEvent>(_onClearSelection);
    on<SetSearchModeEvent>(_onSetSearchMode);
    on<NavigateSearchEvent>(_onNavigateSearch);
    on<JumpToTopEvent>(_onJumpToTop);
    on<JumpToBottomEvent>(_onJumpToBottom);
  }

  Future<void> _onConnect(ConnectEvent event, Emitter<SyslogState> emit) async {
    emit(state.copyWith(connectionStatus: ConnectionStatus.connecting));

    try {
      await _goBackendService.start(state.syslogAddress);

      _messageSubscription?.cancel();
      _connectionSubscription?.cancel();

      _messageSubscription = _webSocketService.messageStream.listen(
        (message) => add(MessageReceivedEvent(message)),
      );

      _connectionSubscription = _webSocketService.connectionStream.listen(
        (connected) => add(ConnectionStatusChangedEvent(
          connected ? ConnectionStatus.connected : ConnectionStatus.disconnected,
        )),
      );

      _webSocketService.connect();
    } catch (e) {
      emit(state.copyWith(
        connectionStatus: ConnectionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onConnectionStatusChanged(ConnectionStatusChangedEvent event, Emitter<SyslogState> emit) {
    emit(state.copyWith(connectionStatus: event.status));
  }

  Future<void> _onDisconnect(DisconnectEvent event, Emitter<SyslogState> emit) async {
    _webSocketService.disconnect();
    await _goBackendService.stop();
    emit(state.copyWith(connectionStatus: ConnectionStatus.disconnected));
  }

  void _onMessageReceived(MessageReceivedEvent event, Emitter<SyslogState> emit) {
    _messages.add(event.message);

    if (_messages.length > _maxMessages) {
      _messages.removeAt(0);
    }

    final filtered = _applyFilters(_messages);

    emit(state.copyWith(
      messages: List.from(_messages),
      filteredMessages: filtered,
      severityCounts: _computeSeverityCounts(_messages),
    ));
  }

  void _onClearMessages(ClearMessagesEvent event, Emitter<SyslogState> emit) {
    _messages.clear();
    emit(state.copyWith(
      messages: [],
      filteredMessages: [],
      severityCounts: {},
    ));
  }

  void _onSetAutoScroll(SetAutoScrollEvent event, Emitter<SyslogState> emit) {
    emit(state.copyWith(autoScroll: event.enabled));
  }

  void _onFilterChanged(FilterChangedEvent event, Emitter<SyslogState> emit) {
    final newSeverityFilter = event.severityFilter ?? state.severityFilter;
    final newFacilityFilter = event.facilityFilter ?? state.facilityFilter;
    final newSearchQuery = event.searchQuery ?? state.searchQuery;

    final newFilteredMessages = _applyFiltersWithParams(
      _messages,
      newSeverityFilter,
      newFacilityFilter,
      newSearchQuery,
      isHighlightMode: state.isSearchHighlightMode,
    );

    // Recalculate search match indices for highlight mode
    List<int> matches = [];
    if (state.isSearchHighlightMode && newSearchQuery != null && newSearchQuery.isNotEmpty) {
      final query = newSearchQuery.toLowerCase();
      for (int i = 0; i < newFilteredMessages.length; i++) {
        if (newFilteredMessages[i].message.toLowerCase().contains(query) ||
            newFilteredMessages[i].host.toLowerCase().contains(query)) {
          matches.add(i);
        }
      }
    }

    emit(state.copyWith(
      severityFilter: newSeverityFilter,
      facilityFilter: newFacilityFilter,
      searchQuery: newSearchQuery,
      filteredMessages: newFilteredMessages,
      searchMatchIndices: matches,
      currentSearchIndex: matches.isNotEmpty ? 0 : -1,
    ));
  }

  Future<void> _onExportMessages(ExportMessagesEvent event, Emitter<SyslogState> emit) async {
    try {
      final csvData = csv.encode([
        ['Timestamp', 'Host', 'Severity', 'SeverityCode', 'Facility', 'Message'],
        ..._messages.map((m) => [
          m.timestamp.toIso8601String(),
          m.host,
          m.severity,
          m.severityCode,
          m.facility,
          m.message,
        ]),
      ]);

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final dir = Directory.current.path;
      final file = File('$dir/syslog_export_$timestamp.csv');
      await file.writeAsString(csvData);
      emit(state.copyWith(exportMessage: 'Export successful: ${file.path}'));
    } catch (e) {
      emit(state.copyWith(exportMessage: 'Export failed: $e'));
    }
  }

  Future<void> _onServerConfigChanged(ServerConfigChangedEvent event, Emitter<SyslogState> emit) async {
    final newSyslogAddress = event.syslogAddress ?? state.syslogAddress;
    final newWebsocketUrl = event.websocketUrl ?? state.websocketUrl;

    emit(state.copyWith(
      syslogAddress: newSyslogAddress,
      websocketUrl: newWebsocketUrl,
    ));

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('syslog_address', newSyslogAddress);
      await prefs.setString('websocket_url', newWebsocketUrl);
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  void _onToggleMultiSelect(ToggleMultiSelectEvent event, Emitter<SyslogState> emit) {
    emit(state.copyWith(
      isMultiSelectMode: !state.isMultiSelectMode,
      selectedIndices: state.isMultiSelectMode ? [] : state.selectedIndices,
    ));
  }

  void _onToggleSelection(ToggleSelectionEvent event, Emitter<SyslogState> emit) {
    final newSelection = List<int>.from(state.selectedIndices);
    if (newSelection.contains(event.index)) {
      newSelection.remove(event.index);
    } else {
      newSelection.add(event.index);
    }
    emit(state.copyWith(selectedIndices: newSelection));
  }

  void _onClearSelection(ClearSelectionEvent event, Emitter<SyslogState> emit) {
    emit(state.copyWith(
      isMultiSelectMode: false,
      selectedIndices: [],
    ));
  }

  void _onSetSearchMode(SetSearchModeEvent event, Emitter<SyslogState> emit) {
    // Recompute filteredMessages without search filter when entering highlight mode
    final newFilteredMessages = _applyFiltersWithParams(
      _messages,
      state.severityFilter,
      state.facilityFilter,
      event.isHighlightMode ? null : state.searchQuery,
      isHighlightMode: event.isHighlightMode,
    );

    List<int> matches = [];
    if (event.isHighlightMode && state.searchQuery != null && state.searchQuery!.isNotEmpty) {
      final query = state.searchQuery!.toLowerCase();
      for (int i = 0; i < newFilteredMessages.length; i++) {
        if (newFilteredMessages[i].message.toLowerCase().contains(query) ||
            newFilteredMessages[i].host.toLowerCase().contains(query)) {
          matches.add(i);
        }
      }
    }
    emit(state.copyWith(
      isSearchHighlightMode: event.isHighlightMode,
      filteredMessages: newFilteredMessages,
      searchMatchIndices: matches,
      currentSearchIndex: matches.isNotEmpty ? 0 : -1,
    ));
  }

  void _onNavigateSearch(NavigateSearchEvent event, Emitter<SyslogState> emit) {
    if (state.searchMatchIndices.isEmpty) return;

    int newIndex;
    if (event.forward) {
      newIndex = (state.currentSearchIndex + 1) % state.searchMatchIndices.length;
    } else {
      newIndex = state.currentSearchIndex - 1;
      if (newIndex < 0) newIndex = state.searchMatchIndices.length - 1;
    }
    emit(state.copyWith(currentSearchIndex: newIndex));
  }

  void _onJumpToTop(JumpToTopEvent event, Emitter<SyslogState> emit) {
    emit(state.copyWith(currentSearchIndex: 0));
  }

  void _onJumpToBottom(JumpToBottomEvent event, Emitter<SyslogState> emit) {
    emit(state.copyWith(currentSearchIndex: state.filteredMessages.length - 1));
  }

  List<SyslogMessage> _applyFilters(List<SyslogMessage> messages) {
    return _applyFiltersWithParams(
      messages,
      state.severityFilter,
      state.facilityFilter,
      state.searchQuery,
      isHighlightMode: state.isSearchHighlightMode,
    );
  }

  List<SyslogMessage> _applyFiltersWithParams(
    List<SyslogMessage> messages,
    SeverityFilter severityFilter,
    String? facilityFilter,
    String? searchQuery, {
    bool isHighlightMode = false,
  }) {
    return messages.where((msg) {
      if (!severityFilter.contains(msg.severityCode)) {
        return false;
      }

      if (facilityFilter != null && facilityFilter.isNotEmpty &&
          msg.facility != facilityFilter) {
        return false;
      }

      // In highlight mode, don't filter by search query - only filter by severity/facility
      if (searchQuery != null && searchQuery.isNotEmpty && !isHighlightMode) {
        final query = searchQuery.toLowerCase();
        return msg.message.toLowerCase().contains(query) ||
               msg.host.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  Map<String, int> _computeSeverityCounts(List<SyslogMessage> messages) {
    final counts = <String, int>{};
    for (final msg in messages) {
      counts[msg.severity] = (counts[msg.severity] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _goBackendService.stop();
    _webSocketService.dispose();
    return super.close();
  }
}
