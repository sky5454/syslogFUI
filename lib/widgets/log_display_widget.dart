import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/syslog_bloc.dart';
import '../bloc/syslog_event.dart';
import '../bloc/syslog_state.dart';
import '../models/syslog_message.dart';
import '../theme/app_theme.dart';

class LogDisplayWidget extends StatefulWidget {
  const LogDisplayWidget({super.key});

  @override
  State<LogDisplayWidget> createState() => _LogDisplayWidgetState();
}

class _LogDisplayWidgetState extends State<LogDisplayWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToIndex(int index) {
    if (_scrollController.hasClients && index >= 0) {
      final offset = index * 28.0;
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SyslogBloc, SyslogState>(
      listenWhen: (previous, current) =>
          (current.autoScroll &&
           current.filteredMessages.length > previous.filteredMessages.length) ||
          (current.currentSearchIndex != previous.currentSearchIndex) ||
          (current.isSearchHighlightMode != previous.isSearchHighlightMode) ||
          (current.filteredMessages.length != previous.filteredMessages.length),
      listener: (context, state) {
        if (state.isSearchHighlightMode && state.currentSearchIndex >= 0 && state.searchMatchIndices.isNotEmpty) {
          final targetIndex = state.searchMatchIndices[state.currentSearchIndex];
          _scrollToIndex(targetIndex);
        } else if (state.currentSearchIndex >= 0) {
          _scrollToIndex(state.currentSearchIndex);
        } else if (!state.isSearchHighlightMode && state.filteredMessages.isNotEmpty) {
          // In filter mode, scroll to top when list changes
          _scrollToIndex(0);
        } else {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        if (state.filteredMessages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                Text(
                  state.messages.isEmpty
                      ? 'No log messages yet'
                      : 'No messages match the current filter',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            if (state.isMultiSelectMode)
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.blue.withOpacity(0.2),
                child: Row(
                  children: [
                    Text(
                      '${state.selectedIndices.length} selected',
                      style: const TextStyle(color: Colors.blue, fontSize: 13),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        context.read<SyslogBloc>().add(ClearSelectionEvent());
                      },
                      child: const Text('Clear', style: TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: state.filteredMessages.length,
                  itemExtent: 28.0,
                  itemBuilder: (context, index) {
                    final message = state.filteredMessages[index];
                    final isSelected = state.selectedIndices.contains(index);
                    final isSearchHighlight = state.isSearchHighlightMode &&
                        state.searchMatchIndices.contains(index);
                    return _LogEntryRow(
                      message: message,
                      index: index,
                      isMultiSelectMode: state.isMultiSelectMode,
                      isSelected: isSelected,
                      isSearchHighlight: isSearchHighlight,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LogEntryRow extends StatelessWidget {
  final SyslogMessage message;
  final int index;
  final bool isMultiSelectMode;
  final bool isSelected;
  final bool isSearchHighlight;

  const _LogEntryRow({
    required this.message,
    required this.index,
    required this.isMultiSelectMode,
    required this.isSelected,
    this.isSearchHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = AppTheme.getSeverityColor(message.severity);

    return GestureDetector(
      onTap: isMultiSelectMode
          ? () => context.read<SyslogBloc>().add(ToggleSelectionEvent(index))
          : null,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withOpacity(0.15)
              : isSearchHighlight
                  ? Colors.yellow.withOpacity(0.3)
                  : null,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            if (isMultiSelectMode)
              SizedBox(
                width: 24,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) =>
                      context.read<SyslogBloc>().add(ToggleSelectionEvent(index)),
                ),
              ),
            SizedBox(
              width: 180,
              child: Text(
                _formatTimestamp(message.timestamp),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                message.host.isNotEmpty ? message.host : '-',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                message.severity,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: severityColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: Text(
                message.facility,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.message,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.year}-${_pad(timestamp.month)}-${_pad(timestamp.day)} '
           '${_pad(timestamp.hour)}:${_pad(timestamp.minute)}:${_pad(timestamp.second)}';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}
