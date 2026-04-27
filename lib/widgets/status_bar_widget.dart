import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/syslog_bloc.dart';
import '../bloc/syslog_event.dart';
import '../bloc/syslog_state.dart';
import 'log_panel_widget.dart';

class StatusBarWidget extends StatelessWidget {
  final VoidCallback onConsoleLogsPressed;
  final bool isConsoleLogsExpanded;

  const StatusBarWidget({
    super.key,
    required this.onConsoleLogsPressed,
    required this.isConsoleLogsExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyslogBloc, SyslogState>(
      builder: (context, state) {
        return Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              _StatusIndicator(
                icon: _getConnectionIcon(state.connectionStatus),
                label: _getConnectionLabel(state.connectionStatus),
                color: _getConnectionColor(state.connectionStatus),
              ),
              const VerticalDivider(indent: 6, endIndent: 6),
              ConsoleLogsButton(
                isExpanded: isConsoleLogsExpanded,
                onPressed: onConsoleLogsPressed,
              ),
              const VerticalDivider(indent: 6, endIndent: 6),
              _StatusItem(
                icon: Icons.message_outlined,
                label: '${state.messages.length} messages',
              ),
              const SizedBox(width: 12),
              _SeverityCounts(counts: state.severityCounts),
              if (state.filteredMessages.length != state.messages.length) ...[
                const VerticalDivider(indent: 6, endIndent: 6),
                _StatusItem(
                  icon: Icons.filter_list,
                  label: '${state.filteredMessages.length} shown',
                ),
              ],
              const Spacer(),
              _ClickableStatusItem(
                icon: Icons.dns_outlined,
                label: state.syslogAddress,
                onTap: () => _showConfigDialog(context, 'syslog'),
              ),
              const SizedBox(width: 16),
              _ClickableStatusItem(
                icon: Icons.webhook,
                label: state.websocketUrl,
                onTap: () => _showConfigDialog(context, 'websocket'),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getConnectionIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Icons.check_circle;
      case ConnectionStatus.connecting:
        return Icons.sync;
      case ConnectionStatus.error:
        return Icons.error;
      case ConnectionStatus.disconnected:
        return Icons.circle_outlined;
    }
  }

  String _getConnectionLabel(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.error:
        return 'Error';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
    }
  }

  void _showConfigDialog(BuildContext context, String type) {
    final bloc = context.read<SyslogBloc>();
    final state = bloc.state;
    final controller = TextEditingController(
      text: type == 'syslog' ? state.syslogAddress : state.websocketUrl,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('修改 ${type == 'syslog' ? 'Syslog' : 'WebSocket'} 地址'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: type == 'syslog' ? 'Syslog 地址' : 'WebSocket URL',
            hintText: type == 'syslog' ? '0.0.0.0:514' : 'ws://localhost:8765/ws',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (type == 'syslog') {
                bloc.add(ServerConfigChangedEvent(syslogAddress: controller.text));
              } else {
                bloc.add(ServerConfigChangedEvent(websocketUrl: controller.text));
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Color _getConnectionColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.error:
        return Colors.red;
      case ConnectionStatus.disconnected:
        return Colors.grey;
    }
  }
}

class _StatusIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusIndicator({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
      ],
    );
  }
}

class _ClickableStatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ClickableStatusItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white54),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.edit, size: 12, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class _SeverityCounts extends StatelessWidget {
  final Map<String, int> counts;

  const _SeverityCounts({required this.counts});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    final order = ['Debug', 'Info', 'Warning', 'Error'];
    final colors = {
      'Debug': const Color(0xFF4CAF50),
      'Info': const Color(0xFF9E9E9E),
      'Warning': const Color(0xFFFFEB3B),
      'Error': const Color(0xFFFF9800),
    };

    for (final sev in order) {
      final count = counts[sev] ?? 0;
      if (count > 0) {
        items.add(Text(
          '$sev:$count',
          style: TextStyle(fontSize: 11, color: colors[sev]),
        ));
        items.add(const SizedBox(width: 8));
      }
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(mainAxisSize: MainAxisSize.min, children: items);
  }
}
