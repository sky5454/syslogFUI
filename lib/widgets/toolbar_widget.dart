import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart' as path;
import '../bloc/syslog_bloc.dart';
import '../bloc/syslog_event.dart';
import '../bloc/syslog_state.dart';

class ToolbarWidget extends StatelessWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SyslogBloc, SyslogState>(
      listenWhen: (previous, current) =>
          previous.exportMessage != current.exportMessage &&
          current.exportMessage != null,
      listener: (context, state) {
        if (state.exportMessage != null) {
          final message = state.exportMessage!;
          final isSuccess = message.startsWith('Export successful');
          String? filePath;

          if (isSuccess) {
            // Extract file path from message
            filePath = message.replaceFirst('Export successful: ', '');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    color: isSuccess ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isSuccess ? 'Export successful' : message,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              duration: Duration(seconds: isSuccess ? 5 : 3),
              behavior: SnackBarBehavior.floating,
              action: isSuccess && filePath != null
                  ? SnackBarAction(
                      label: 'Open Folder',
                      onPressed: () {
                        final dir = path.dirname(filePath!);
                        if (Platform.isWindows) {
                          Process.run('explorer', [dir]);
                        } else if (Platform.isMacOS) {
                          Process.run('open', [dir]);
                        } else {
                          Process.run('xdg-open', [dir]);
                        }
                      },
                    )
                  : null,
            ),
          );
        }
      },
      builder: (context, state) {
        final isConnected = state.connectionStatus == ConnectionStatus.connected;

        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              _ToolbarButton(
                icon: isConnected ? Icons.stop : Icons.play_arrow,
                label: isConnected ? 'Stop Server' : 'Start Server',
                color: isConnected ? Colors.red : Colors.green,
                onPressed: () {
                  if (isConnected) {
                    context.read<SyslogBloc>().add(DisconnectEvent());
                  } else {
                    context.read<SyslogBloc>().add(ConnectEvent());
                  }
                },
              ),
              const SizedBox(width: 8),
              _ToolbarButton(
                icon: Icons.delete_outline,
                label: 'Clear Logs',
                onPressed: state.messages.isNotEmpty
                    ? () => context.read<SyslogBloc>().add(ClearMessagesEvent())
                    : null,
              ),
              const SizedBox(width: 8),
              _ToolbarButton(
                icon: Icons.file_download_outlined,
                label: 'Export CSV',
                onPressed: state.messages.isNotEmpty
                    ? () => context.read<SyslogBloc>().add(ExportMessagesEvent())
                    : null,
              ),
              const SizedBox(width: 8),
              _ToolbarButton(
                icon: state.isMultiSelectMode ? Icons.check_box : Icons.check_box_outline_blank,
                label: 'Select',
                color: state.isMultiSelectMode ? Colors.blue : null,
                onPressed: () {
                  context.read<SyslogBloc>().add(ToggleMultiSelectEvent());
                },
              ),
              if (state.isMultiSelectMode && state.selectedIndices.isNotEmpty) ...[
                const SizedBox(width: 8),
                _ToolbarButton(
                  icon: Icons.copy,
                  label: 'Copy (${state.selectedIndices.length})',
                  onPressed: () => _copySelected(context, state),
                ),
              ],
              const SizedBox(width: 8),
              _ToolbarButton(
                icon: Icons.arrow_upward,
                label: 'Top',
                onPressed: () => context.read<SyslogBloc>().add(JumpToTopEvent()),
              ),
              const SizedBox(width: 4),
              _ToolbarButton(
                icon: Icons.arrow_downward,
                label: 'Bottom',
                onPressed: () => context.read<SyslogBloc>().add(JumpToBottomEvent()),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Text('Auto-scroll'),
                  Switch(
                    value: state.autoScroll,
                    onChanged: (value) {
                      context.read<SyslogBloc>().add(SetAutoScrollEvent(value));
                    },
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${state.filteredMessages.length} / ${state.messages.length} messages',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.github, size: 20),
                tooltip: 'GitHub',
                onPressed: () {
                  if (Platform.isWindows) {
                    Process.run('cmd', ['/c', 'start', '', 'https://github.com/sky5454/syslogFUI']);
                  } else if (Platform.isMacOS) {
                    Process.run('open', ['https://github.com/sky5454/syslogFUI']);
                  } else {
                    Process.run('xdg-open', ['https://github.com/sky5454/syslogFUI']);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _copySelected(BuildContext context, SyslogState state) {
    final selectedMessages = state.selectedIndices
        .map((i) => state.filteredMessages[i])
        .toList();

    final buffer = StringBuffer();
    for (final msg in selectedMessages) {
      buffer.writeln('[${msg.timestamp}] ${msg.host} ${msg.severity}: ${msg.message}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${selectedMessages.length} lines to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    context.read<SyslogBloc>().add(ClearSelectionEvent());
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: isEnabled ? (color ?? Colors.white) : Colors.white38),
      label: Text(
        label,
        style: TextStyle(color: isEnabled ? Colors.white : Colors.white38),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
