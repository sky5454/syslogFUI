import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/syslog_bloc.dart';

class ConsoleLogsPanel extends StatefulWidget {
  final VoidCallback onClear;
  final VoidCallback onClose;

  const ConsoleLogsPanel({
    super.key,
    required this.onClear,
    required this.onClose,
  });

  @override
  State<ConsoleLogsPanel> createState() => _ConsoleLogsPanelState();
}

class _ConsoleLogsPanelState extends State<ConsoleLogsPanel> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<String>? _logSubscription;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _subscribeToLogs();
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _subscribeToLogs() {
    if (!mounted) return;

    final bloc = context.read<SyslogBloc>();
    final service = bloc.goBackendService;

    _logSubscription = service.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.add(log);
          if (_logs.length > 500) {
            _logs.removeAt(0);
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    });

    _logs.addAll(service.logLines);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildLogContent()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
      ),
      child: Row(
        children: [
          const Icon(Icons.terminal, size: 14, color: Colors.white70),
          const SizedBox(width: 8),
          const Text(
            'Console Logs',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 14),
            color: Colors.white54,
            onPressed: () {
              setState(() {
                _logs.clear();
              });
              widget.onClear();
            },
            tooltip: 'Clear logs',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 14),
            color: Colors.white54,
            onPressed: widget.onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildLogContent() {
    if (_logs.isEmpty) {
      return const Center(
        child: Text(
          'No logs yet',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        Color color = Colors.white70;
        if (log.contains('[ERROR]')) {
          color = Colors.red[300]!;
        } else if (log.contains('[WARN]')) {
          color = Colors.orange[300]!;
        } else if (log.contains('[INFO]')) {
          color = Colors.green[300]!;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(
            log,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

class ConsoleLogsButton extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onPressed;

  const ConsoleLogsButton({
    super.key,
    required this.isExpanded,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isExpanded ? Icons.expand_less : Icons.terminal,
                size: 14,
                color: isExpanded ? Colors.white : Colors.white54,
              ),
              const SizedBox(width: 4),
              Text(
                'Console Logs',
                style: TextStyle(
                  fontSize: 12,
                  color: isExpanded ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}