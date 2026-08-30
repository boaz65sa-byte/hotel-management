// lib/features/tickets/presentation/ticket_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';
import 'package:hotel_app/core/connectivity/connectivity_service.dart';
import '../providers/ticket_detail_provider.dart';
import '../data/ticket_repository.dart';
import '../data/photo_upload_service.dart';
import '../domain/ticket_model.dart';
import 'approval_sheet.dart';
import 'assign_staff_screen.dart';

// ── Priority / Status helpers ─────────────────────────────────────────────────
const _priorityColors = {
  'urgent': Color(0xFFF87171),
  'high':   Color(0xFFFB923C),
  'normal': Color(0xFF4ADE80),
  'low':    Color(0xFF94A3B8),
};
const _priorityLabels = {
  'urgent': 'חירום',
  'high':   'דחוף',
  'normal': 'רגיל',
  'low':    'נמוך',
};
const _statusLabels = {
  'open':             'פתוח',
  'in_progress':      'בטיפול',
  'pending_approval': 'ממתין אישור',
  'resolved':         'נפתר',
  'closed':           'סגור',
};
const _deptIcons = {
  'maintenance': '🔧',
  'reception':   '🛎️',
  'security':    '🔒',
  'housekeeping':'🧹',
};

class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final ticketAsync  = ref.watch(ticketDetailProvider(ticketId));
    final photosAsync  = ref.watch(ticketPhotosProvider(ticketId));
    final user         = ref.watch(currentUserProvider);
    final isOnline     = ref.watch(isOnlineProvider);
    final role = UserRole.fromString(
        (user?.appMetadata['role'] as String?) ?? 'receptionist');

    return ticketAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(e.toString())),
      ),
      data: (ticket) => _TicketDetailView(
        ticket: ticket,
        photosAsync: photosAsync,
        user: user,
        isOnline: isOnline,
        role: role,
        l: l,
        ref: ref,
        ticketId: ticketId,
      ),
    );
  }
}

class _TicketDetailView extends StatelessWidget {
  final Ticket ticket;
  final AsyncValue photosAsync;
  final dynamic user;
  final bool isOnline;
  final UserRole role;
  final AppLocalizations l;
  final WidgetRef ref;
  final String ticketId;

  const _TicketDetailView({
    required this.ticket,
    required this.photosAsync,
    required this.user,
    required this.isOnline,
    required this.role,
    required this.l,
    required this.ref,
    required this.ticketId,
  });

  // SLA helpers
  double get _slaProgress {
    if (ticket.slaDeadline == null) return 0;
    final total = ticket.slaDeadline!.difference(ticket.createdAt).inMinutes;
    if (total <= 0) return 1;
    final elapsed = DateTime.now().difference(ticket.createdAt).inMinutes;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Color get _slaColor {
    if (ticket.slaDeadline == null) return const Color(0xFF4ADE80);
    final remaining = ticket.slaDeadline!.difference(DateTime.now());
    if (remaining.isNegative)      return const Color(0xFFF87171);
    if (remaining.inMinutes < 30)  return const Color(0xFFFB923C);
    return const Color(0xFF4ADE80);
  }

  String get _slaLabel {
    if (ticket.slaDeadline == null) return 'ללא SLA';
    final remaining = ticket.slaDeadline!.difference(DateTime.now());
    if (remaining.isNegative) return 'חריגת SLA!';
    if (remaining.inMinutes < 60) return '${remaining.inMinutes} דק׳ נותרו';
    return '${remaining.inHours} ש׳ נותרו';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final priorityColor = _priorityColors[ticket.priority] ?? const Color(0xFF94A3B8);
    final deptIcon = _deptIcons[ticket.assignedDept] ?? '📋';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero header ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: cs.surface,
            foregroundColor: cs.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.surface, cs.primaryContainer],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ticket# + room
                    Text(
                      '← #${ticket.id.substring(0, 6).toUpperCase()} · חדר ${ticket.roomNumber ?? "?"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.primary.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // title
                    Text(
                      ticket.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    // chips row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _HeroChip(
                          label: _priorityLabels[ticket.priority] ?? ticket.priority,
                          color: priorityColor,
                          filled: true,
                        ),
                        _HeroChip(
                          label: '$deptIcon ${ticket.assignedDept}',
                          color: const Color(0xFF2563EB),
                          filled: false,
                        ),
                        _HeroChip(
                          label: _statusLabels[ticket.status] ?? ticket.status,
                          color: cs.primary,
                          filled: false,
                        ),
                        if (ticket.pendingClose)
                          const _HeroChip(
                            label: 'ממתין סגירה',
                            color: Colors.teal,
                            filled: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Info card ─────────────────────────────────────────────
                _InfoCard(
                  children: [
                    if (ticket.openerName != null)
                      _InfoRow(label: 'נפתח ע"י', value: ticket.openerName!),
                    if (ticket.claimerName != null)
                      _InfoRow(label: 'תפס', value: ticket.claimerName!),
                    if (ticket.assigneeName != null)
                      _InfoRow(label: 'מטפל', value: ticket.assigneeName!),
                    if (ticket.description != null && ticket.description!.isNotEmpty)
                      _InfoRow(label: 'תיאור', value: ticket.description!),
                  ],
                ),

                // ── SLA bar ───────────────────────────────────────────────
                if (ticket.slaDeadline != null) ...[
                  const SizedBox(height: 12),
                  _SlaBar(
                    label: _slaLabel,
                    progress: _slaProgress,
                    color: _slaColor,
                  ),
                ],

                // ── Photos ────────────────────────────────────────────────
                const SizedBox(height: 12),
                _PhotoSection(
                  ticket: ticket,
                  photosAsync: photosAsync,
                  isOnline: isOnline,
                  user: user,
                  ref: ref,
                  ticketId: ticketId,
                  l: l,
                ),

                // ── Action buttons ────────────────────────────────────────
                const SizedBox(height: 16),
                _ActionButtons(
                  ticket: ticket,
                  role: role,
                  user: user,
                  isOnline: isOnline,
                  ref: ref,
                  ticketId: ticketId,
                  l: l,
                ),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),

      // ── Chat FAB ──────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(
          '/tickets/${ticket.id}/chat',
          extra: ticket.title,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }
}

// ── Hero chip ─────────────────────────────────────────────────────────────────
class _HeroChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  const _HeroChip({required this.label, required this.color, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SLA bar ───────────────────────────────────────────────────────────────────
class _SlaBar extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;
  const _SlaBar({required this.label, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                'SLA',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photos section ────────────────────────────────────────────────────────────
class _PhotoSection extends StatelessWidget {
  final Ticket ticket;
  final AsyncValue photosAsync;
  final bool isOnline;
  final dynamic user;
  final WidgetRef ref;
  final String ticketId;
  final AppLocalizations l;

  const _PhotoSection({
    required this.ticket,
    required this.photosAsync,
    required this.isOnline,
    required this.user,
    required this.ref,
    required this.ticketId,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canAddPhoto = ticket.status == 'in_progress' && isOnline && ticket.claimedBy == user?.id;

    final hasPhoto = ticket.photoBeforeUrl != null;
    final extraPhotos = photosAsync.maybeWhen(
      data: (p) => (p as List).isNotEmpty,
      orElse: () => false,
    );

    if (!hasPhoto && !extraPhotos && !canAddPhoto) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📷 תיעוד',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Before photo
              if (ticket.photoBeforeUrl != null)
                _PhotoThumb(url: ticket.photoBeforeUrl!, label: 'לפני'),
              if (ticket.photoBeforeUrl == null && canAddPhoto)
                const _PhotoThumb(url: null, label: 'לפני'),

              const SizedBox(width: 8),

              // After photo / add button
              if (ticket.photoAfterUrl != null)
                _PhotoThumb(url: ticket.photoAfterUrl!, label: 'אחרי'),

              // Extra photos
              ...photosAsync.maybeWhen(
                data: (photos) => (photos as List).take(3).map((p) =>
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _PhotoThumb(url: p.photoUrl as String, label: ''),
                  ),
                ).toList(),
                orElse: () => [],
              ),

              // Add photo button
              if (canAddPhoto)
                GestureDetector(
                  onTap: () async {
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
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: cs.outline, style: BorderStyle.solid),
                    ),
                    child: Icon(Icons.add_a_photo_outlined,
                        size: 22, color: cs.onSurfaceVariant),
                  ),
                ),
            ],
          ),
          if (ticket.requiresMedia && ticket.photoBeforeUrl == null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF87171).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF87171).withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: Color(0xFFF87171)),
                  SizedBox(width: 6),
                  Text(
                    'נדרשת תמונה לפני סגירה',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFF87171),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final String? url;
  final String label;
  const _PhotoThumb({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.hardEdge,
      child: url != null
          ? Image.network(url!, fit: BoxFit.cover)
          : Center(
              child: Icon(Icons.image_outlined,
                  size: 24, color: cs.onSurfaceVariant)),
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final Ticket ticket;
  final UserRole role;
  final dynamic user;
  final bool isOnline;
  final WidgetRef ref;
  final String ticketId;
  final AppLocalizations l;

  const _ActionButtons({
    required this.ticket,
    required this.role,
    required this.user,
    required this.isOnline,
    required this.ref,
    required this.ticketId,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    // Claim button
    if (role.canClaimAndUpdate &&
        ticket.claimedBy == null &&
        ticket.status == 'open') {
      buttons.add(FilledButton.icon(
        onPressed: isOnline
            ? () async {
                final repo = TicketRepository(
                    isOnline: () => ref.read(isOnlineProvider));
                await repo.claimTicket(ticket.id, user!.id);
                ref.invalidate(ticketDetailProvider(ticketId));
              }
            : null,
        icon: const Icon(Icons.assignment_ind),
        label: Text(isOnline ? l.claimTicket : l.claimRequiresConnection),
      ));
    }

    // Assign staff button (managers)
    if (role.isManager &&
        ticket.status != 'resolved' &&
        ticket.status != 'closed') {
      buttons.add(OutlinedButton.icon(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => AssignStaffScreen(ticket: ticket)),
          );
          if (result == true) ref.invalidate(ticketDetailProvider(ticketId));
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(ticket.assignedTo == null ? 'שבץ מטפל' : 'שנה מטפל'),
      ));
    }

    // Mark done (assigned tech)
    if (ticket.assignedTo == user?.id &&
        ticket.status == 'in_progress' &&
        !ticket.pendingClose) {
      buttons.add(FilledButton.icon(
        onPressed: isOnline
            ? () async {
                final repo = TicketRepository(
                    isOnline: () => ref.read(isOnlineProvider));
                await repo.markDone(ticket.id);
                ref.invalidate(ticketDetailProvider(ticketId));
              }
            : null,
        icon: const Icon(Icons.done_all),
        label: const Text('בוצע — ממתין לאישור מנהל'),
        style: FilledButton.styleFrom(backgroundColor: Colors.teal),
      ));
    }

    // Manager close (when pendingClose)
    if (role.isManager && ticket.pendingClose) {
      buttons.add(FilledButton.icon(
        onPressed: isOnline
            ? () async {
                final repo = TicketRepository(
                    isOnline: () => ref.read(isOnlineProvider));
                await repo.managerClose(ticket.id);
                ref.invalidate(ticketDetailProvider(ticketId));
              }
            : null,
        icon: const Icon(Icons.check_circle),
        label: const Text('סגור קריאה'),
        style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white),
      ));
    }

    // Resolve buttons (claimer in_progress)
    if (role.canClaimAndUpdate &&
        ticket.claimedBy == user?.id &&
        ticket.status == 'in_progress' &&
        isOnline) {
      buttons.add(Row(children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () async {
              final repo = TicketRepository(
                  isOnline: () => ref.read(isOnlineProvider));
              await repo.resolveTicket(
                  ticket.id, ticket.hotelId, user!.id, 'fixed');
              ref.invalidate(ticketDetailProvider(ticketId));
            },
            icon: const Icon(Icons.check),
            label: Text(l.ticketFixed),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final repo = TicketRepository(
                  isOnline: () => ref.read(isOnlineProvider));
              await repo.resolveTicket(
                  ticket.id, ticket.hotelId, user!.id, 'on_hold');
              ref.invalidate(ticketDetailProvider(ticketId));
            },
            icon: const Icon(Icons.pause),
            label: Text(l.ticketOnHold),
          ),
        ),
      ]));
    }

    // Approval button
    if (role.isRequiredApprover && ticket.status == 'pending_approval') {
      buttons.add(FutureBuilder<Map<String, dynamic>?>(
        future: supabase
            .from('ticket_approvals')
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
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          buttons[i],
          if (i < buttons.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
