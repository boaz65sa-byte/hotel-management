// lib/features/tickets/presentation/tickets_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/shared/widgets/offline_banner.dart';
import '../providers/tickets_provider.dart';
import 'ticket_card.dart';

class TicketsListScreen extends ConsumerWidget {
  const TicketsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final myTickets = ref.watch(myTicketsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.myTickets)),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(
          child: myTickets.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (tickets) => tickets.isEmpty
              ? Center(child: Text(l.noTickets))
              : ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (_, i) => TicketCard(
                    ticket: tickets[i],
                    onTap: () => context.push('/tickets/${tickets[i].id}'),
                  ),
                ),
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
