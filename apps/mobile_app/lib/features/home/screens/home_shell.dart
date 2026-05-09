import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/tokens/app_colors.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static const _tabs = [
    (label: 'Maintenance', icon: Icons.build_outlined, active: Icons.build, path: '/maintenance'),
    (label: 'Inventory', icon: Icons.inventory_2_outlined, active: Icons.inventory_2, path: '/inventory'),
    (label: 'Borrowing', icon: Icons.assignment_outlined, active: Icons.assignment, path: '/borrowing'),
    (label: 'Profile', icon: Icons.person_outline, active: Icons.person, path: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: current,
          onDestinationSelected: (i) => context.go(_tabs[i].path),
          backgroundColor: cs.surface,
          indicatorColor: AppColors.primary.withOpacity(0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: _tabs
              .asMap()
              .entries
              .map(
                (e) => NavigationDestination(
                  icon: Icon(e.value.icon),
                  selectedIcon: Icon(
                    e.value.active,
                    color: AppColors.primary,
                  ),
                  label: e.value.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
