// lib/features/tickets/presentation/ticket_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import '../providers/tickets_provider.dart';
import '../domain/ticket_model.dart';

final _messagesStreamProvider =
    StreamProvider.family<List<TicketMessage>, String>((ref, ticketId) {
  return ref
      .watch(ticketRepoProvider)
      .watchMessages(ticketId)
      .map((rows) => rows
          .map((r) => TicketMessage.fromJson(r))
          .toList());
});

class TicketChatScreen extends ConsumerStatefulWidget {
  final String ticketId;
  final String ticketTitle;
  const TicketChatScreen(
      {super.key, required this.ticketId, required this.ticketTitle});

  @override
  ConsumerState<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends ConsumerState<TicketChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final me = ref.read(currentUserProvider)?.id;
    if (me == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(ticketRepoProvider).sendMessage(
            ticketId: widget.ticketId,
            senderId: me,
            body: text,
          );
      _ctrl.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final messagesAsync = ref.watch(_messagesStreamProvider(widget.ticketId));
    final myId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('צ\'אט קריאה',
                style: TextStyle(fontWeight: FontWeight.w800)),
            Text(
              widget.ticketTitle,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (messages) => messages.isEmpty
                  ? Center(
                      child: Text(
                        'אין הודעות עדיין',
                        style: TextStyle(
                            color: cs.onSurface.withOpacity(0.4)),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final msg = messages[i];
                        final isMe = msg.senderId == myId;
                        return _MessageBubble(
                            msg: msg, isMe: isMe, cs: cs);
                      },
                    ),
            ),
          ),
          _InputBar(ctrl: _ctrl, sending: _sending, onSend: _send, cs: cs),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TicketMessage msg;
  final bool isMe;
  final ColorScheme cs;
  const _MessageBubble(
      {required this.msg, required this.isMe, required this.cs});

  @override
  Widget build(BuildContext context) {
    final time =
        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.primaryContainer,
              child: Text(
                (msg.senderName?.isNotEmpty == true)
                    ? msg.senderName!.characters.first
                    : '?',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: cs.onPrimaryContainer),
              ),
            ),
          if (!isMe) const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? cs.primary : cs.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe && msg.senderName != null)
                    Text(
                      msg.senderName!,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cs.primary),
                    ),
                  Text(
                    msg.body,
                    style: TextStyle(
                      color: isMe ? cs.onPrimary : cs.onSurface,
                      fontSize: 13,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 9,
                      color: (isMe ? cs.onPrimary : cs.onSurface)
                          .withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool sending;
  final VoidCallback onSend;
  final ColorScheme cs;
  const _InputBar(
      {required this.ctrl,
      required this.sending,
      required this.onSend,
      required this.cs});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                textDirection: TextDirection.rtl,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'הקלד הודעה...',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: cs.surfaceVariant,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: sending
                  ? SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.primary))
                  : IconButton.filled(
                      onPressed: onSend,
                      icon: const Icon(Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
