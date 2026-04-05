// test/features/tickets/presentation/ticket_card_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/tickets/presentation/ticket_card.dart';
import 'package:hotel_app/features/tickets/domain/ticket_model.dart';

void main() {
  Ticket makeTicket({String status = 'open', DateTime? slaDeadline, String? photoAfterUrl, bool requiresMedia = false}) =>
      Ticket(
        id: '1',
        hotelId: 'h1',
        roomId: 'r1',
        openedBy: 'u1',
        assignedDept: 'maintenance',
        title: 'Broken AC',
        priority: 'normal',
        status: status,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        slaDeadline: slaDeadline,
        roomNumber: '101',
        photoAfterUrl: photoAfterUrl,
        requiresMedia: requiresMedia,
      );

  testWidgets('TicketCard shows title and room number', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: TicketCard(ticket: makeTicket(), onTap: () {})),
        ),
      ),
    );
    expect(find.text('Broken AC'), findsOneWidget);
    expect(find.text('Room 101 • maintenance'), findsOneWidget);
  });

  testWidgets('TicketCard shows SLA badge when sla_deadline is in the past', (tester) async {
    final pastDeadline = DateTime(2020);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: TicketCard(ticket: makeTicket(slaDeadline: pastDeadline), onTap: () {})),
        ),
      ),
    );
    expect(find.text('חריגת SLA'), findsOneWidget);
  });

  test('canResolve is false when photoAfterUrl is null and requiresMedia is true', () {
    expect(makeTicket(requiresMedia: true).canResolve, false);
  });

  test('canResolve is true when photoAfterUrl is set', () {
    expect(makeTicket(photoAfterUrl: 'https://example.com/a.jpg').canResolve, true);
  });
}
