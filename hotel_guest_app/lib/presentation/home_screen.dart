// hotel_guest_app/lib/presentation/home_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/core/i18n/locale_provider.dart';
import 'package:hotel_guest_app/core/push_service_web.dart';
import 'package:hotel_guest_app/domain/guest_request.dart';
import 'package:hotel_guest_app/l10n/app_localizations.dart';
import 'package:hotel_guest_app/providers/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _pushEnabled = false;

  void _enablePush(String hotelId, String roomNumber) {
    PushServiceWeb.showNativePrompt();
    PushServiceWeb.setGuestTags(hotelId: hotelId, roomNumber: roomNumber);
    setState(() => _pushEnabled = true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final sessionAsync = ref.watch(sessionProvider);
    final requestsAsync = ref.watch(myRequestsProvider);

    return sessionAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A1628),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(
            child: Text(loc.errorGeneric(e.toString()),
                style: const TextStyle(color: Colors.white))),
      ),
      data: (session) {
        if (session == null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => context.go('/'));
          return const Scaffold(backgroundColor: Color(0xFF0A1628));
        }
        return Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.homeGreeting(session.guestName),
                              style: const TextStyle(
                                color: Color(0xFFC9A84C),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              loc.homeRoom(session.roomNumber),
                              style: const TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const _LanguageSwitcher(),
                    ],
                  ),
                ),
                // Feedback banner
                if (session.shouldShowFeedback)
                  GestureDetector(
                    onTap: () => context.push('/feedback'),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2F1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF4ADE80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFC9A84C)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(loc.homeFeedbackTitle,
                                    style: const TextStyle(
                                        color: Color(0xFFE2E8F0),
                                        fontWeight: FontWeight.w700)),
                                Text(loc.homeFeedbackSubtitle,
                                    style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                // Web Push opt-in banner (Web only, shown until enabled)
                if (kIsWeb && !_pushEnabled)
                  GestureDetector(
                    onTap: () =>
                        _enablePush(session.hotelId, session.roomNumber),
                    child: Container(
                      margin:
                          const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1F3D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF1E3A5F)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_outlined,
                              color: Color(0xFFC9A84C), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              loc.homePushBanner,
                              style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _enablePush(
                                session.hotelId, session.roomNumber),
                            child: Text(loc.homePushEnable,
                                style: const TextStyle(
                                    color: Color(0xFFC9A84C))),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/new'),
                      icon: const Icon(Icons.add),
                      label: Text(loc.homeNewRequest,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC9A84C),
                        foregroundColor: Colors.black,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(loc.homeMyRequests,
                      style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  child: requestsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                        child: Text('$e',
                            style: const TextStyle(
                                color: Color(0xFF94A3B8)))),
                    data: (requests) => requests.isEmpty
                        ? Center(
                            child: Text(loc.homeNoRequests,
                                style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 14)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            itemCount: requests.length,
                            itemBuilder: (_, i) =>
                                _RequestTile(request: requests[i]),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageSwitcher extends ConsumerWidget {
  const _LanguageSwitcher();

  static const _langs = [
    (Locale('he'), '🇮🇱', 'עברית'),
    (Locale('en'), '🇬🇧', 'English'),
    (Locale('ar'), '🇸🇦', 'العربية'),
    (Locale('ru'), '🇷🇺', 'Русский'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final flag = _langs
        .firstWhere((l) => l.$1.languageCode == current.languageCode,
            orElse: () => _langs[0])
        .$2;
    return PopupMenuButton<Locale>(
      onSelected: (l) => ref.read(localeProvider.notifier).setLocale(l),
      tooltip: '',
      color: const Color(0xFF0F1F3D),
      icon: Text(flag, style: const TextStyle(fontSize: 22)),
      itemBuilder: (_) => _langs
          .map((item) => PopupMenuItem<Locale>(
                value: item.$1,
                child: Row(
                  children: [
                    Text(item.$2, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(item.$3,
                        style:
                            const TextStyle(color: Color(0xFFE2E8F0))),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final GuestRequest request;
  const _RequestTile({required this.request});

  static const _statusColor = {
    'open':        Color(0xFFF87171),
    'assigned':    Color(0xFFFB923C),
    'in_progress': Color(0xFFFB923C),
    'resolved':    Color(0xFF4ADE80),
    'cancelled':   Color(0xFF64748B),
  };

  String _categoryLabel(String category, AppLocalizations loc) {
    switch (category) {
      case 'housekeeping': return '🛏️ ${loc.categoryHousekeeping}';
      case 'maintenance':  return '🔧 ${loc.categoryMaintenance}';
      case 'reception':    return '🛎️ ${loc.categoryReception}';
      default:             return category;
    }
  }

  String _statusLabel(String status, AppLocalizations loc) {
    switch (status) {
      case 'open':        return loc.statusOpen;
      case 'assigned':    return loc.statusInProgress;
      case 'in_progress': return loc.statusInProgress;
      case 'resolved':    return loc.statusResolved;
      case 'cancelled':   return loc.statusCancelled;
      default:            return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final statusColor =
        _statusColor[request.status] ?? const Color(0xFF64748B);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F3D),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: statusColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _categoryLabel(request.category, loc),
                  style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                if (request.description != null &&
                    request.description!.isNotEmpty)
                  Text(
                    request.description!,
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(request.status, loc),
              style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
