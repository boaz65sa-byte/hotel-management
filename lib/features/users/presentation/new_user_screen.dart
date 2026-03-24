// lib/features/users/presentation/new_user_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import '../data/users_repository.dart';
import 'users_screen.dart';

const _roles = [
  ('ceo', 'CEO'),
  ('reception_manager', 'Reception Manager'),
  ('maintenance_manager', 'Maintenance Manager'),
  ('housekeeping_manager', 'Housekeeping Manager'),
  ('security_manager', 'Security Manager'),
  ('deputy_reception', 'Deputy Reception'),
  ('receptionist', 'Receptionist'),
  ('security_guard', 'Security Guard'),
  ('maintenance_tech', 'Maintenance Tech'),
  ('repairman', 'Repairman'),
];

class NewUserScreen extends ConsumerStatefulWidget {
  const NewUserScreen({super.key});
  @override
  ConsumerState<NewUserScreen> createState() => _State();
}

class _State extends ConsumerState<NewUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _role = 'receptionist';
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider)!;
    final hotelId = user.appMetadata['hotel_id'] as String;
    setState(() => _loading = true);
    try {
      await UsersRepository().inviteUser(
        email: _emailCtrl.text.trim(),
        fullName: _nameCtrl.text.trim(),
        role: _role,
        hotelId: hotelId,
      );
      if (mounted) {
        ref.invalidate(usersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation sent')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite User')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email *'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Role *'),
              items: _roles
                .map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2)))
                .toList(),
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _invite,
              child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Send Invitation'),
            ),
          ],
        ),
      ),
    );
  }
}
