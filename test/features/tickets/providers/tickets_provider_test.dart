// test/features/tickets/providers/tickets_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/tickets/providers/tickets_provider.dart';
import 'package:hotel_app/features/tickets/data/ticket_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('ticketRepoProvider returns a TicketRepository', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final repo = container.read(ticketRepoProvider);
    expect(repo, isA<TicketRepository>());
  });
}
