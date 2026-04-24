import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/syslog_bloc.dart';
import '../bloc/syslog_event.dart';
import '../bloc/syslog_state.dart';
import '../models/syslog_message.dart';

class FilterPanelWidget extends StatefulWidget {
  const FilterPanelWidget({super.key});

  @override
  State<FilterPanelWidget> createState() => _FilterPanelWidgetState();
}

class _FilterPanelWidgetState extends State<FilterPanelWidget> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyslogBloc, SyslogState>(
      builder: (context, state) {
        return Container(
          width: 250,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search messages...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<SyslogBloc>().add(
                                    const FilterChangedEvent(searchQuery: ''),
                                  );
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onChanged: (value) {
                        context.read<SyslogBloc>().add(
                          FilterChangedEvent(searchQuery: value),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Mode:', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Filter', style: TextStyle(fontSize: 11)),
                          selected: !state.isSearchHighlightMode,
                          onSelected: (_) {
                            context.read<SyslogBloc>().add(const SetSearchModeEvent(false));
                          },
                        ),
                        const SizedBox(width: 4),
                        ChoiceChip(
                          label: const Text('Highlight', style: TextStyle(fontSize: 11)),
                          selected: state.isSearchHighlightMode,
                          onSelected: (_) {
                            if (_searchController.text.isNotEmpty) {
                              context.read<SyslogBloc>().add(const SetSearchModeEvent(true));
                            }
                          },
                        ),
                      ],
                    ),
                    if (state.isSearchHighlightMode && state.searchMatchIndices.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${state.currentSearchIndex + 1}/${state.searchMatchIndices.length}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.arrow_upward, size: 18),
                            onPressed: () {
                              context.read<SyslogBloc>().add(const NavigateSearchEvent(false));
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.arrow_downward, size: 18),
                            onPressed: () {
                              context.read<SyslogBloc>().add(const NavigateSearchEvent(true));
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Severity',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...Severity.values.map((severity) {
                      final isEnabled = state.severityFilter.enabledSeverities.contains(severity);
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(severity.color),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              severity.label,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        value: isEnabled,
                        onChanged: (value) {
                          final newSet = Set<Severity>.from(
                            state.severityFilter.enabledSeverities,
                          );
                          if (value == true) {
                            newSet.add(severity);
                          } else {
                            newSet.remove(severity);
                          }
                          context.read<SyslogBloc>().add(
                            FilterChangedEvent(
                              severityFilter: SeverityFilter(newSet),
                            ),
                          );
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    context.read<SyslogBloc>().add(
                      FilterChangedEvent(
                        severityFilter: SeverityFilter(Severity.values.toSet()),
                        facilityFilter: '',
                        searchQuery: '',
                      ),
                    );
                  },
                  child: const Text('Reset Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
