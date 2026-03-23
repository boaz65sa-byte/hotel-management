// lib/features/tickets/presentation/ticket_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';
import 'package:hotel_app/core/connectivity/connectivity_service.dart';
import '../providers/ticket_detail_provider.dart';
import '../data/ticket_repository.dart';
import '../data/photo_upload_service.dart';
import 'timeline_entry.dart';
import 'approval_sheet.dart';

class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final ticketAsync = ref.watch(ticketDetailProvider(ticketId));
    final updatesAsync = ref.watch(ticketUpdatesProvider(ticketId));
    final photosAsync = ref.watch(ticketPhotosProvider(ticketId));
    final user = ref.watch(currentUserProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final role = UserRole.fromString(
      (user?.appMetadata['role'] as String?) ?? 'receptionist');

    return Scaffold(
      appBar: AppBar(title: Text(ticketAsync.value?.title ?? l.myTickets)),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (ticket) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(ticket.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Room ${ticket.roomNumber} • ${ticket.assignedDept} • ${ticket.priority}',
              style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            _statusChip(ticket.status),
            const Divider(height: 32),

            Text('Timeline', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...updatesAsync.maybeWhen(
              data: (updates) => updates.map((u) => TimelineEntry(update: u)).toList(),
              orElse: () => [const CircularProgressIndicator()],
            ),

            if (photosAsync.maybeWhen(data: (p) => p.isNotEmpty, orElse: () => false)) ...[
              const Divider(height: 32),
              Text('Photos', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              photosAsync.maybeWhen(
                data: (photos) => Wrap(
                  spacing: 8, runSpacing: 8,
                  children: photos.map((p) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(p.photoUrl, width: 100, height: 100, fit: BoxFit.cover),
                  )).toList(),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],

            const SizedBox(height: 32),

            // Claim button
            if (role.canClaimAndUpdate && ticket.claimedBy == null && ticket.status == 'open')
              FilledButton(
                onPressed: isOnline ? () async {
                  final repo = TicketRepository(isOnline: () => ref.read(isOnlineProvider));
                  await repo.claimTicket(ticket.id, user!.id);
                  ref.invalidate(ticketDetailProvider(ticketId));
                } : null,
                child: Text(isOnline ? l.claimTicket : l.claimRequiresConnection),
              ),

            // Resolve buttons (for the claimer while in_progress)
            if (role.canClaimAndUpdate && ticket.claimedBy == user?.id &&
                ticket.status == 'in_progress') ...[
              if (isOnline) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    final svc = PhotoUploadService(isOnline: isOnline);
                    final photo = await svc.pickPhoto();
                    if (photo != null) {
                      await svc.uploadPhoto(
                        ticketId: ticket.id,
                        hotelId: ticket.hotelId,
                        uploadedBy: user!.id,
                        photo: photo,
                      );
                      ref.invalidate(ticketPhotosProvider(ticketId));
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: Text(l.addPhoto),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: FilledButton.icon(
                    onPressed: () async {
                      final repo = TicketRepository(isOnline: () => ref.read(isOnlineProvider));
                      await repo.resolveTicket(ticket.id, ticket.hotelId, user!.id, 'fixed');
                      ref.invalidate(ticketDetailProvider(ticketId));
                    },
                    icon: const Icon(Icons.check),
                    label: Text(l.ticketFixed),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () async {
                      final repo = TicketRepository(isOnline: () => ref.read(isOnlineProvider));
                      await repo.resolveTicket(ticket.id, ticket.hotelId, user!.id, 'on_hold');
                      ref.invalidate(ticketDetailProvider(ticketId));
                    },
                    icon: const Icon(Icons.pause),
                    label: Text(l.ticketOnHold),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () async {
                      final repo = TicketRepository(isOnline: () => ref.read(isOnlineProvider));
                      await repo.resolveTicket(ticket.id, ticket.hotelId, user!.id, 'room_closed');
                      ref.invalidate(ticketDetailProvider(ticketId));
                    },
                    icon: const Icon(Icons.lock),
                    label: Text(l.ticketRoomClosed),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  )),
                ]),
              ] else
                Text(
                  'Connection required to resolve or add photos',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
            ],

            // Approval button for managers
            if (role.isRequiredApprover && ticket.status == 'pending_approval')
              FutureBuilder<Map<String, dynamic>?>(
                future: supabase.from('ticket_approvals')
                  .select()
                  .eq('ticket_id', ticketId)
                  .eq('approver_id', user!.id)
                  .isFilter('approved', null)
                  .maybeSingle(),
                builder: (_, snap) {
                  if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
                  final row = snap.data!;
                  return FilledButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ApprovalSheet(
                        ticketId: ticketId,
                        approvalId: row['id'] as String,
                      ),
                    ),
                    child: Text(l.pendingApproval),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final colors = {
      'open': Colors.orange, 'in_progress': Colors.blue,
      'pending_approval': Colors.red, 'resolved': Colors.green, 'closed': Colors.grey,
    };
    return Chip(
      label: Text(status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 11)),
      backgroundColor: colors[status] ?? Colors.grey,
    );
  }
}
