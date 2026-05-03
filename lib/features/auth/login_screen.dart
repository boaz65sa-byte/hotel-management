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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

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
