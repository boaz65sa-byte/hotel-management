// lib/features/home/presentation/custom_department_home.dart
//
// Generic home screen for custom_dept_manager/custom_dept_staff — anyone
// belonging to a hotel_departments row that isn't one of the 5 fixed
// departments (which each get their own bespoke home screen, e.g.
// kitchen_home.dart). Label/icon come from the department row itself
// instead of being hardcoded, since a new department can be named
// anything.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/features/home/providers/custom_department_home_provider.dart';
import 'package:hotel_app/features/tickets/domain/ticket_model.dart';
import 'package:hotel_app/features/tickets/presentation/ticket_card.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';
import 'package:hotel_app/features/guest_requests/presentation/staff_requests_screen.dart';

const _priorityFilters = ['הכל', 'urgent', 'high', 'normal', 'low'];
const _priorityLabels = {
  'הכל':   'הכל',
  'urgent': '🔴 חירום',
  'high':   '🟠 דחוף',
  'normal': '⚪ רגיל',
  'low':    '🟢 נמוך',
};

class CustomDepartmentHomeScreen extends ConsumerStatefulWidget {
  const CustomDepartmentHomeScreen({super.key});
  @override
  ConsumerState<CustomDepartmentHomeScreen> createState() =>
      _CustomDepartmentHomeScreenState();
}

class _CustomDepartmentHomeScreenState
    extends ConsumerState<CustomDepartmentHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (icon: Icons.queue,        label: 'קריאות',  screen: const _CustomDeptQueue()),
      (icon: Icons.room_service, label: 'בקשות',   screen: const StaffRequestsScreen()),
      (icon: Icons.person,       label: 'פרופיל',  screen: const ProfileScreen()),
    ];
    return Scaffold(
      body: tabs[_tab].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _CustomDeptQueue extends ConsumerStatefulWidget {
  const _CustomDeptQueue();

  @override
  ConsumerState<_CustomDeptQueue> createState() => _CustomDeptQueueState();
}

class _CustomDeptQueueState extends ConsumerState<_CustomDeptQueue> {
  String _filter = 'הכל';

  List<Ticket> _apply(List<Ticket> tickets) {
    if (_filter == 'הכל') return tickets;
    return tickets.where((t) => t.priority == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final deptAsync = ref.watch(myCustomDepartmentProvider);
    final ticketsAsync = ref.watch(customDepartmentTicketsProvider);

    return Scaffold(
      body: Column(
        children: [
          deptAsync.maybeWhen(
            data: (dept) => ticketsAsync.maybeWhen(
              data: (tickets) => _Header(dept: dept, tickets: tickets),
              orElse: () => _Header(dept: dept, tickets: const []),
            ),
            orElse: () => const _Header(dept: null, tickets: []),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _priorityFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _priorityFilters[i];
                final selected = _filter == f;
                return ChoiceChip(
                  label: Text(_priorityLabels[f] ?? f),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = f),
                  selectedColor: cs.primaryContainer,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? cs.onPrimaryContainer : cs.onSurface,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ticketsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('שגיאה: $e')),
              data: (tickets) {
                final filtered = _apply(tickets);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _filter == 'הכל' ? 'אין קריאות פתוחות' : 'אין קריאות בעדיפות זו',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => TicketCard(
                    ticket: filtered[i],
                    onTap: () => context.push('/tickets/${filtered[i].id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tickets/new'),
        icon: const Icon(Icons.add),
        label: const Text('קריאה חדשה'),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final CustomDepartment? dept;
  final List<Ticket> tickets;
  const _Header({required this.dept, required this.tickets});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = tickets.where((t) => t.status == 'open' || t.status == 'in_progress').length;
    final emergency = tickets.where((t) => t.priority == 'urgent').length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.surface, cs.primaryContainer],
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${dept?.icon ?? '🏷️'} קריאות ${dept?.label ?? ''}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              _Pill(label: '$active פעילות', color: cs.primary),
              if (emergency > 0)
                _Pill(label: '$emergency חירום', color: const Color(0xFFF87171)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
