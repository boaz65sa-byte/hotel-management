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
