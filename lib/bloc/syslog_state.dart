import 'package:equatable/equatable.dart';
import '../models/syslog_message.dart';
import 'syslog_event.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class SyslogState extends Equatable {
  final List<SyslogMessage> messages;
  final List<SyslogMessage> filteredMessages;
  final ConnectionStatus connectionStatus;
  final bool autoScroll;
  final SeverityFilter severityFilter;
  final String? facilityFilter;
  final String? searchQuery;
  final String? errorMessage;
  final Map<String, int> severityCounts;
  final String? exportMessage;
  final String syslogAddress;
  final String websocketUrl;
  final bool isMultiSelectMode;
  final List<int> selectedIndices;
  final bool isSearchHighlightMode;
  final List<int> searchMatchIndices;
  final int currentSearchIndex;

  SyslogState({
    this.messages = const [],
    this.filteredMessages = const [],
    this.connectionStatus = ConnectionStatus.disconnected,
    this.autoScroll = true,
    SeverityFilter? severityFilter,
    this.facilityFilter,
    this.searchQuery,
    this.errorMessage,
    this.severityCounts = const {},
    this.exportMessage,
    this.syslogAddress = '0.0.0.0:514',
    this.websocketUrl = 'ws://localhost:8765/ws',
    this.isMultiSelectMode = false,
    this.selectedIndices = const [],
    this.isSearchHighlightMode = true,
    this.searchMatchIndices = const [],
    this.currentSearchIndex = -1,
  }) : severityFilter = severityFilter ?? SeverityFilter(Severity.values.toSet());

  SyslogState copyWith({
    List<SyslogMessage>? messages,
    List<SyslogMessage>? filteredMessages,
    ConnectionStatus? connectionStatus,
    bool? autoScroll,
    SeverityFilter? severityFilter,
    String? facilityFilter,
    String? searchQuery,
    String? errorMessage,
    Map<String, int>? severityCounts,
    String? exportMessage,
    String? syslogAddress,
    String? websocketUrl,
    bool? isMultiSelectMode,
    List<int>? selectedIndices,
    bool? isSearchHighlightMode,
    List<int>? searchMatchIndices,
    int? currentSearchIndex,
  }) {
    return SyslogState(
      messages: messages ?? this.messages,
      filteredMessages: filteredMessages ?? this.filteredMessages,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      autoScroll: autoScroll ?? this.autoScroll,
      severityFilter: severityFilter ?? this.severityFilter,
      facilityFilter: facilityFilter ?? this.facilityFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      severityCounts: severityCounts ?? this.severityCounts,
      exportMessage: exportMessage,
      syslogAddress: syslogAddress ?? this.syslogAddress,
      websocketUrl: websocketUrl ?? this.websocketUrl,
      isMultiSelectMode: isMultiSelectMode ?? this.isMultiSelectMode,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      isSearchHighlightMode: isSearchHighlightMode ?? this.isSearchHighlightMode,
      searchMatchIndices: searchMatchIndices ?? this.searchMatchIndices,
      currentSearchIndex: currentSearchIndex ?? this.currentSearchIndex,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    filteredMessages,
    connectionStatus,
    autoScroll,
    severityFilter,
    facilityFilter,
    searchQuery,
    errorMessage,
    severityCounts,
    exportMessage,
    syslogAddress,
    websocketUrl,
    isMultiSelectMode,
    selectedIndices,
    isSearchHighlightMode,
    searchMatchIndices,
    currentSearchIndex,
  ];
}
