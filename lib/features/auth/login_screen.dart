// lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/core/i18n/locale_provider.dart';
import 'package:hotel_app/core/theme/app_theme.dart';
import 'package:hotel_app/core/theme/theme_provider.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/core/push/push_service.dart';

class _HotelHint {
  final String name;
  final String? logoUrl;
  const _HotelHint({required this.name, this.logoUrl});
}

class LoginScreen extends ConsumerStatefulWidget {
  /// Optional hotel_id from URL query (?hotel=<id>) — used to show the hotel
  /// logo and name above the login form so staff know which hotel they're
  /// logging into.
  final String? hotelHint;
  const LoginScreen({super.key, this.hotelHint});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  _HotelHint? _hotelHint;

  @override
  void initState() {
    super.initState();
    _loadHotelHint();
  }

  Future<void> _loadHotelHint() async {
    final id = widget.hotelHint;
    if (id == null || id.isEmpty) return;
    try {
      final data = await supabase
          .rpc('get_hotel_branding', params: {'p_hotel_id': id});
      if (data is List && data.isNotEmpty) {
        final row = data.first as Map<String, dynamic>;
        final name = row['name'];
        if (name is String && name.isNotEmpty && mounted) {
          setState(() => _hotelHint = _HotelHint(
                name: name,
                logoUrl: row['logo_url'] as String?,
              ));
        }
      }
    } catch (_) {
      // silently ignore — fall back to the generic login screen
    }
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).signIn(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
      // Load hotel theme from Supabase (read hotel_id from users table, not JWT)
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final userRow = await supabase
            .from('users')
            .select('hotel_id')
            .eq('id', userId)
            .maybeSingle();
        final hotelId = userRow?['hotel_id'] as String?;
        if (hotelId != null) {
          final hotel = await supabase
              .from('hotels')
              .select('theme')
              .eq('id', hotelId)
              .single();
          final themeStr = hotel['theme'] as String? ?? 'clean_blue';
          ref.read(hotelThemeProvider.notifier).state = AppTheme.forHotel(themeStr);
        }
        // Set up push notification tags for this user
        final pushRole   = supabase.auth.currentUser?.appMetadata['role']?.toString() ?? '';
        final pushUserId = supabase.auth.currentUser?.id ?? '';
        if (mounted && hotelId != null && pushRole.isNotEmpty) {
          await PushService.setupAfterLogin(
            role:    pushRole,
            hotelId: hotelId,
            userId:  pushUserId,
            context: context,
          );
        }
        // superAdmin has no hotel_id — default clean_blue stays, no action needed
      }
      // Router redirects automatically via auth guard
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hotelHint != null) ...[
                  _HotelHeaderWidget(hint: _hotelHint!),
                  const SizedBox(height: 24),
                ],
                DropdownButton<String>(
                  value: locale.languageCode,
                  items: const [
                    DropdownMenuItem(value: 'he', child: Text('עברית')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                  ],
                  onChanged: (lang) {
                    if (lang != null) {
                      ref.read(localeProvider.notifier).state = Locale(lang);
                    }
                  },
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(labelText: l.email),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  decoration: InputDecoration(
                    labelText: l.password,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                _loading
                    ? const CircularProgressIndicator()
                    : FilledButton(
                        onPressed: _login,
                        child: Text(l.login),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HotelHeaderWidget extends StatelessWidget {
  final _HotelHint hint;
  const _HotelHeaderWidget({required this.hint});

  @override
  Widget build(BuildContext context) {
    final logo = hint.logoUrl;
    return Column(
      children: [
        if (logo != null && logo.trim().isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              logo,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _FallbackHotelBadge(),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return const SizedBox(
                  width: 88,
                  height: 88,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
          )
        else
          const _FallbackHotelBadge(),
        const SizedBox(height: 12),
        Text(
          hint.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'התחברות צוות',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _FallbackHotelBadge extends StatelessWidget {
  const _FallbackHotelBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Icon(Icons.hotel, color: Colors.grey.shade500, size: 44),
    );
  }
}
