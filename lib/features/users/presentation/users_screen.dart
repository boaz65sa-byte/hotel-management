import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/users_repository.dart';
import '../domain/user_model.dart';

final usersProvider = FutureProvider<List<HotelUser>>((ref) async {
  return UsersRepository().fetchAll();
});

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final user = list[i];
            return ListTile(
              leading: CircleAvatar(child: Text(user.fullName[0])),
              title: Text(user.fullName),
              subtitle: Text('${user.role} • ${user.email}'),
              trailing: Switch(
                value: user.isActive,
                onChanged: (val) async {
                  await UsersRepository().toggleActive(user.id, val);
                  ref.invalidate(usersProvider);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {/* navigate to user form */},
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
