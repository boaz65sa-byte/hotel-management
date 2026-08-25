// lib/features/profile/presentation/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/core/i18n/locale_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.profile)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          CircleAvatar(radius: 40, child: Text(
            (user?.email ?? '?')[0].toUpperCase(),
            style: const TextStyle(fontSize: 32),
          )),
          const SizedBox(height: 16),
          Text(user?.email ?? '', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            (user?.appMetadata['role'] as String?) ?? '',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const Divider(height: 40),
          // Language selector
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Language'),
            value: locale.languageCode,
            items: const [
              DropdownMenuItem(value: 'he', child: Text('עברית')),
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'ar', child: Text('العربية')),
              DropdownMenuItem(value: 'ru', child: Text('🇷🇺 Русский')),
            ],
            onChanged: (lang) {
              if (lang != null) {
                ref.read(localeProvider.notifier).state = Locale(lang);
              }
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const _ChangePasswordDialog(),
            ),
            icon: const Icon(Icons.lock_outline),
            label: Text(l.changePassword),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.logout),
            label: Text(l.logout),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ]),
      ),
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    if (_newCtrl.text.length < 8) {
      setState(() => _error = l.passwordTooShort);
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = l.passwordsDoNotMatch);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).changePassword(_newCtrl.text);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.passwordChangedSuccess)),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.changePassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _newCtrl,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(labelText: l.newPassword),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            obscureText: true,
            decoration: InputDecoration(labelText: l.confirmPassword),
            onSubmitted: (_) => _loading ? null : _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l.save),
        ),
      ],
    );
  }
}
