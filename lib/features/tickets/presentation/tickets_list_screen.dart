// lib/features/tickets/presentation/tickets_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/shared/widgets/offline_banner.dart';
import '../domain/ticket_model.dart';
import '../providers/tickets_provider.dart';
import 'ticket_card.dart';

// ── Filter / sort state ────────────────────────────────────────────────────
enum _SortOption { newest, priority, sla }

const _statusFilters = [
  'הכל', 'open', 'in_progress', 'pending_close', 'resolved', 'closed'
];
const _statusLabels = {
  'הכל': 'הכל',
  'open': 'פתוח',
  'in_progress': 'בטיפול',
  'pending_close': 'ממתין לסגירה',
  'resolved': 'נפתר',
  'closed': 'סגור',
};
const _priorityOrder = {'urgent': 0, 'high': 1, 'normal': 2, 'low': 3};

class TicketsListScreen extends ConsumerStatefulWidget {
  const TicketsListScreen({super.key});

  @override
  ConsumerState<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends ConsumerState<TicketsListScreen> {
  String _filter = 'הכל';
  _SortOption _sort = _SortOption.newest;

  List<Ticket> _apply(List<Ticket> tickets) {
    var list = tickets.where((t) {
      if (_filter == 'הכל') return true;
      if (_filter == 'pending_close') return t.pendingClose;
      return t.status == _filter;
    }).toList();

    switch (_sort) {
      case _SortOption.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortOption.priority:
        list.sort((a, b) =>
            (_priorityOrder[a.priority] ?? 9)
                .compareTo(_priorityOrder[b.priority] ?? 9));
      case _SortOption.sla:
        list.sort((a, b) {
          if (a.slaDeadline == null && b.slaDeadline == null) return 0;
          if (a.slaDeadline == null) return 1;
          if (b.slaDeadline == null) return -1;
          return a.slaDeadline!.compareTo(b.slaDeadline!);
        });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final myTickets = ref.watch(myTicketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.myTickets),
        actions: [
          PopupMenuButton<_SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'מיין',
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: _SortOption.newest, child: Text('חדש לישן')),
              const PopupMenuItem(
                  value: _SortOption.priority, child: Text('עדיפות')),
              const PopupMenuItem(
                  value: _SortOption.sla, child: Text('SLA קרוב')),
            ],
          ),
        ],
      ),
      body: Column(children: [
        const OfflineBanner(),
        // ── Filter chips ───────────────────────────────────────────────
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _statusFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = _statusFilters[i];
              final selected = _filter == f;
              return ChoiceChip(
                label: Text(_statusLabels[f] ?? f),
                selected: selected,
                onSelected: (_) => setState(() => _filter = f),
                selectedColor: cs.primaryContainer,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.onPrimaryContainer : cs.onSurface,
                ),
              );
            },
          ),
        ),
        Expanded(
          child: myTickets.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (tickets) {
              final filtered = _apply(tickets);
              return filtered.isEmpty
                  ? Center(child: Text(l.noTickets))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => TicketCard(
                        ticket: filtered[i],
                        onTap: () =>
                            context.push('/tickets/${filtered[i].id}'),
                      ),
                    );
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tickets/new'),
        label: Text(l.newTicket),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
