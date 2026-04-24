import 'package:equatable/equatable.dart';
import '../models/syslog_message.dart';
import 'syslog_state.dart';

abstract class SyslogEvent extends Equatable {
  const SyslogEvent();

  @override
  List<Object?> get props => [];
}

class ConnectEvent extends SyslogEvent {}

class DisconnectEvent extends SyslogEvent {}

class ConnectionStatusChangedEvent extends SyslogEvent {
  final ConnectionStatus status;

  const ConnectionStatusChangedEvent(this.status);

  @override
  List<Object?> get props => [status];
}

class MessageReceivedEvent extends SyslogEvent {
  final SyslogMessage message;

  const MessageReceivedEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class ClearMessagesEvent extends SyslogEvent {}

class SetAutoScrollEvent extends SyslogEvent {
  final bool enabled;

  const SetAutoScrollEvent(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class FilterChangedEvent extends SyslogEvent {
  final SeverityFilter? severityFilter;
  final String? facilityFilter;
  final String? searchQuery;

  const FilterChangedEvent({
    this.severityFilter,
    this.facilityFilter,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [severityFilter, facilityFilter, searchQuery];
}

class ExportMessagesEvent extends SyslogEvent {}

class ExportCompleteEvent extends SyslogEvent {
  final bool success;
  final String message;
  final String? filePath;

  const ExportCompleteEvent({
    required this.success,
    required this.message,
    this.filePath,
  });

  @override
  List<Object?> get props => [success, message, filePath];
}

class ServerConfigChangedEvent extends SyslogEvent {
  final String? syslogAddress;
  final String? websocketUrl;

  const ServerConfigChangedEvent({
    this.syslogAddress,
    this.websocketUrl,
  });

  @override
  List<Object?> get props => [syslogAddress, websocketUrl];
}

class ToggleMultiSelectEvent extends SyslogEvent {}

class ToggleSelectionEvent extends SyslogEvent {
  final int index;

  const ToggleSelectionEvent(this.index);

  @override
  List<Object?> get props => [index];
}

class ClearSelectionEvent extends SyslogEvent {}

class JumpToTopEvent extends SyslogEvent {}

class JumpToBottomEvent extends SyslogEvent {}

class SetSearchModeEvent extends SyslogEvent {
  final bool isHighlightMode;

  const SetSearchModeEvent(this.isHighlightMode);

  @override
  List<Object?> get props => [isHighlightMode];
}

class NavigateSearchEvent extends SyslogEvent {
  final bool forward;

  const NavigateSearchEvent(this.forward);

  @override
  List<Object?> get props => [forward];
}

class SeverityFilter extends Equatable {
  final Set<Severity> enabledSeverities;

  const SeverityFilter(this.enabledSeverities);

  bool contains(int severityCode) {
    return enabledSeverities.any((s) => s.code == severityCode);
  }

  @override
  List<Object?> get props => [enabledSeverities];
}
