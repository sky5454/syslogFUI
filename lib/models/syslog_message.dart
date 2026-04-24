import 'package:equatable/equatable.dart';

class SyslogMessage extends Equatable {
  final DateTime timestamp;
  final String host;
  final String severity;
  final int severityCode;
  final String facility;
  final int facilityCode;
  final String message;
  final String rawMessage;

  const SyslogMessage({
    required this.timestamp,
    required this.host,
    required this.severity,
    required this.severityCode,
    required this.facility,
    required this.facilityCode,
    required this.message,
    required this.rawMessage,
  });

  factory SyslogMessage.fromJson(Map<String, dynamic> json) {
    return SyslogMessage(
      timestamp: DateTime.parse(json['timestamp'] as String),
      host: json['host'] as String? ?? '',
      severity: json['severity'] as String? ?? 'Unknown',
      severityCode: json['severity_code'] as int? ?? 0,
      facility: json['facility'] as String? ?? 'Unknown',
      facilityCode: json['facility_code'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      rawMessage: json['raw_message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'host': host,
    'severity': severity,
    'severity_code': severityCode,
    'facility': facility,
    'facility_code': facilityCode,
    'message': message,
    'raw_message': rawMessage,
  };

  @override
  List<Object?> get props => [timestamp, host, severity, severityCode, facility, facilityCode, message, rawMessage];
}

enum Severity {
  emergency(0, 'Emergency', 0xFFFF5252),
  alert(1, 'Alert', 0xFFFF5252),
  critical(2, 'Critical', 0xFFFF5252),
  error(3, 'Error', 0xFFFF9800),
  warning(4, 'Warning', 0xFFFFEB3B),
  notice(5, 'Notice', 0xFF2196F3),
  info(6, 'Info', 0xFF9E9E9E),
  debug(7, 'Debug', 0xFF4CAF50);

  final int code;
  final String label;
  final int color;

  const Severity(this.code, this.label, this.color);

  static Severity fromCode(int code) {
    return Severity.values.firstWhere(
      (s) => s.code == code,
      orElse: () => Severity.info,
    );
  }
}
