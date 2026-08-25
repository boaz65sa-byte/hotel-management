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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface,
              scheme.brightness == Brightness.dark
                  ? Color.lerp(scheme.surface, Colors.black, 0.5)!
                  : Color.lerp(scheme.surface, scheme.primary, 0.05)!,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_hotelHint != null)
                      _HotelHeaderWidget(
                          hint: _hotelHint!, subtitle: l.staffLoginSubtitle)
                    else
                      _BrandHeader(appName: l.appName, subtitle: l.staffLoginSubtitle),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ?? scheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _LanguagePicker(
                            current: locale.languageCode,
                            onChanged: (lang) => ref
                                .read(localeProvider.notifier)
                                .state = Locale(lang),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _emailCtrl,
                            decoration: InputDecoration(
                              labelText: l.email,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passCtrl,
                            decoration: InputDecoration(
                              labelText: l.password,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            obscureText: _obscurePassword,
                            onSubmitted: (_) => _loading ? null : _login(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: TextStyle(color: scheme.error)),
                          ],
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: scheme.onPrimary,
                                      ),
                                    )
                                  : Text(
                                      l.login,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final String appName;
  final String subtitle;
  const _BrandHeader({required this.appName, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                scheme.primary.withValues(alpha: 0.22),
                scheme.primary.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/app_icon/icon_1024.png',
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.hotel, color: scheme.primary, size: 44),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          appName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: scheme.primary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _LanguagePicker({required this.current, required this.onChanged});

  static const _langs = [
    ('he', 'עברית'),
    ('en', 'EN'),
    ('ar', 'عربي'),
    ('ru', 'RU'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _langs.map((entry) {
        final (code, label) = entry;
        final selected = code == current;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => onChanged(code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outline,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HotelHeaderWidget extends StatelessWidget {
  final _HotelHint hint;
  final String subtitle;
  const _HotelHeaderWidget({required this.hint, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
              errorBuilder: (_, __, ___) => _FallbackHotelBadge(scheme: scheme),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return SizedBox(
                  width: 88,
                  height: 88,
                  child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: scheme.primary),
                  ),
                );
              },
            ),
          )
        else
          _FallbackHotelBadge(scheme: scheme),
        const SizedBox(height: 16),
        Text(
          hint.name,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: scheme.primary),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _FallbackHotelBadge extends StatelessWidget {
  final ColorScheme scheme;
  const _FallbackHotelBadge({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary, width: 2),
      ),
      child: Icon(Icons.hotel, color: scheme.primary, size: 44),
    );
  }
}
