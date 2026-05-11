import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/tokens/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/home_provider.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
    final isDriver = roles.contains('driver');
    final isGso = roles.contains('gso_staff') || roles.contains('super_admin');
    final isTechnician = roles.contains('technician');
    final isHod = roles.contains('department_head');

    if (isDriver) return const _DriverDashboard();
    if (isGso) return const _GsoDashboard();
    if (isTechnician) return const _TechnicianDashboard();
    if (isHod) return const _HodDashboard();
    return const _StandardDashboard();
  }
}

// ── Shared Greeting ───────────────────────────────────────────

class _GreetingHeader extends ConsumerWidget {
  final String subtitle;
  const _GreetingHeader({required this.subtitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final name = (profile?['full_name'] as String?)?.split(' ').first ?? 'there';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final avatarUrl = profile?['avatar_url'] as String?;
    final initials = (profile?['full_name'] as String? ?? 'U').split(' ').take(2).map((n) => n[0]).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.white.withOpacity(0.2),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null ? Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)) : null,
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$greeting, $name!', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
        ])),
        Text(DateFormat('MMM d').format(DateTime.now()), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
      ]),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────

// ── Shimmer Loading Skeleton ──────────────────────────────────

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.neutral200,
      highlightColor: AppColors.neutral100,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              height: 100,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                    height: 100,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  ),
                )),
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(3, (i) => Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              height: 70,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            )),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral500,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ───────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const Spacer(),
        if (actionLabel != null) GestureDetector(onTap: onAction, child: Text(actionLabel!, style: const TextStyle(fontSize: 12, color: AppColors.secondary))),
      ]),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final List<({String label, IconData icon, String path})> actions;
  const _QuickActions({required this.actions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 80,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: actions.length,
        itemBuilder: (context, i) {
          final a = actions[i];
          return GestureDetector(
            onTap: () => context.push(a.path),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(a.icon, size: 20, color: AppColors.primary),
                const SizedBox(height: 4),
                Text(a.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ── Standard Dashboard ───────────────────────────────────────

class _StandardDashboard extends ConsumerWidget {
  const _StandardDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(myStatsProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(myStatsProvider.future),
      child: statsAsync.when(
        loading: () => const _DashboardShimmer(),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Error: $e'))),
        data: (stats) {
          final maintenance = stats['maintenance'] as List;
          final loans = stats['loans'] as List;
          final bookings = stats['bookings'] as List;
          
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _GreetingHeader(subtitle: 'Here\'s your activity overview'),
              _QuickActions(actions: [
                (label: 'New Request', icon: Icons.build_outlined, path: '/maintenance/new'),
                (label: 'Borrow Item', icon: Icons.assignment_outlined, path: '/borrowing'),
                (label: 'Book Room', icon: Icons.meeting_room_outlined, path: '/bookings/new'),
                (label: 'Travel', icon: Icons.directions_car_outlined, path: '/travel/new'),
              ]),
              const _SectionHeader(title: 'My Activity'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: _StatCard(label: 'Active Requests', value: '${maintenance.length}', icon: Icons.build, color: AppColors.statusPending, onTap: () => context.go('/maintenance'))),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Active Loans', value: '${loans.length}', icon: Icons.assignment, color: AppColors.secondary, onTap: () => context.go('/borrowing'))),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Bookings', value: '${bookings.length}', icon: Icons.meeting_room, color: AppColors.statusCompleted, onTap: () => context.go('/bookings'))),
                ]),
              ),
              if (maintenance.isEmpty && loans.isEmpty && bookings.isEmpty)
                const _EmptyDashboard()
              else ...[
                if (maintenance.isNotEmpty) ...[
                  _SectionHeader(title: 'Recent Maintenance', actionLabel: 'View all', onAction: () => context.go('/maintenance')),
                  ...maintenance.map((m) => _ActivityTile(icon: Icons.build_outlined, title: m['title'] ?? 'Request', subtitle: m['status'] ?? '', color: AppColors.statusPending)),
                ],
                if (loans.isNotEmpty) ...[
                  _SectionHeader(title: 'Active Loans', actionLabel: 'View all', onAction: () => context.go('/borrowing')),
                  ...loans.map((l) => _ActivityTile(icon: Icons.assignment_outlined, title: l['loan_number'] ?? 'Loan', subtitle: l['status'] ?? '', color: AppColors.secondary)),
                ],
                if (bookings.isNotEmpty) ...[
                  _SectionHeader(title: 'Upcoming Bookings', actionLabel: 'View all', onAction: () => context.go('/bookings')),
                  ...bookings.map((b) => _ActivityTile(icon: Icons.meeting_room_outlined, title: b['title'] ?? 'Booking', subtitle: DateFormat('MMM d, h:mm a').format(DateTime.parse(b['start_time'])), color: AppColors.statusCompleted)),
                ],
              ],
              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, size: 48, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('All caught up!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'You don\'t have any active requests or loans at the moment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.neutral500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Activity Tile ─────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _ActivityTile({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle.replaceAll('_', ' '), style: const TextStyle(fontSize: 11, color: AppColors.neutral500)),
        ])),
        Icon(Icons.chevron_right, size: 16, color: AppColors.neutral400),
      ]),
    );
  }
}

// ── GSO Dashboard ─────────────────────────────────────────────

class _GsoDashboard extends ConsumerWidget {
  const _GsoDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(gsoStatsProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(gsoStatsProvider.future),
      child: statsAsync.when(
        loading: () => const _DashboardShimmer(),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Error: $e'))),
        data: (s) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _GreetingHeader(subtitle: 'System wide overview'),
            _QuickActions(actions: [
              (label: 'Requests', icon: Icons.build_outlined, path: '/maintenance'),
              (label: 'Borrowing', icon: Icons.assignment_outlined, path: '/borrowing'),
              (label: 'Fleet', icon: Icons.local_shipping_outlined, path: '/fleet'),
              (label: 'Travel', icon: Icons.directions_car_outlined, path: '/travel'),
              (label: 'Inventory', icon: Icons.inventory_2_outlined, path: '/inventory'),
            ]),
            const _SectionHeader(title: 'System KPIs'),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
              children: [
                _StatCard(label: 'Open Requests', value: '${s['openMaintenance']}', icon: Icons.build, color: AppColors.statusPending, onTap: () => context.go('/maintenance')),
                _StatCard(label: 'Active Borrows', value: '${s['activeBorrows']}', icon: Icons.assignment, color: AppColors.secondary, onTap: () => context.go('/borrowing')),
                _StatCard(label: 'Overdue Items', value: '${s['overdueItems']}', icon: Icons.warning_amber, color: AppColors.statusRejected, onTap: () => context.go('/borrowing')),
                _StatCard(label: 'Pending Approvals', value: '${s['pendingApprovals']}', icon: Icons.pending_actions, color: AppColors.statusUrgent, onTap: () => context.go('/admin/bookings')),
              ],
            )),
            if ((s['recentMaintenance'] as List).isNotEmpty) ...[
              _SectionHeader(title: 'Recent Requests', actionLabel: 'View all', onAction: () => context.go('/maintenance')),
              ...(s['recentMaintenance'] as List).map((m) => _ActivityTile(
                icon: Icons.build_outlined,
                title: m['title'] ?? 'Request',
                subtitle: '${m['status'] ?? ''} • ${(m['requester'] as Map?)?['full_name'] ?? ''}',
                color: AppColors.statusPending,
              )),
            ],
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

// ── Driver Dashboard ─────────────────────────────────────────

class _DriverDashboard extends ConsumerWidget {
  const _DriverDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(driverDashboardProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(driverDashboardProvider.future),
      child: dataAsync.when(
        loading: () => const _DashboardShimmer(),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Error: $e'))),
        data: (data) {
          final todayTrip = data['todayTrip'] as Map<String, dynamic>?;
          final upcoming = data['upcomingTrips'] as List<dynamic>;
          final completedCount = data['completedCount'] as int;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _GreetingHeader(subtitle: "Here's your driving schedule"),
              const _SectionHeader(title: "Today's Trip"),
              _TodayTripCard(trip: todayTrip),
              Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Row(children: [
                Expanded(child: _StatCard(label: 'Completed Trips', value: '$completedCount', icon: Icons.check_circle, color: AppColors.statusCompleted)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'Upcoming', value: '${upcoming.length}', icon: Icons.schedule, color: AppColors.statusPending)),
              ])),
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(title: 'Upcoming Trips', actionLabel: 'View all', onAction: () => context.go('/driver/trips')),
                ...upcoming.map((t) => _UpcomingTripTile(trip: t)),
              ] else if (todayTrip == null) ...[
                const SizedBox(height: 20),
                const _EmptyDashboard(),
              ],
              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }
}

class _TodayTripCard extends StatelessWidget {
  final Map<String, dynamic>? trip;
  const _TodayTripCard({this.trip});

  @override
  Widget build(BuildContext context) {
    if (trip == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.neutral200)),
        child: const Center(child: Column(children: [
          Icon(Icons.event_available, size: 40, color: AppColors.neutral400),
          SizedBox(height: 8),
          Text('No trips scheduled for today', style: TextStyle(color: AppColors.neutral500, fontSize: 13)),
        ])),
      );
    }
    final vehicle = trip!['vehicle'] as Map<String, dynamic>?;
    final requester = trip!['requester'] as Map<String, dynamic>?;
    final departureTime = DateTime.tryParse(trip!['departure_time'] ?? '');
    final status = trip!['status'] ?? '';
    final isOngoing = status == 'Ongoing';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOngoing 
            ? [const Color(0xFF0E6655), const Color(0xFF1D8348)]
            : [const Color(0xFF1a5276), const Color(0xFF2e86c1)], 
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isOngoing ? Colors.green : AppColors.primary).withOpacity(0.3), 
            blurRadius: 20, 
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOngoing) ...[
                  const SizedBox(
                    width: 8, height: 8,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white, valueColor: AlwaysStoppedAnimation(Colors.white)),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ],
            ),
          ),
          const Spacer(),
          if (departureTime != null) Text(DateFormat('h:mm a').format(departureTime.toLocal()),
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 18),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.location_on, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trip!['destination'] ?? '—', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5), maxLines: 2),
              const SizedBox(height: 4),
              Text('ISUFST Official Travel', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          )),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            if (requester != null) Row(children: [
              const Icon(Icons.person, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(requester['full_name'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
            if (vehicle != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.local_shipping, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text('${vehicle['brand']} ${vehicle['model']} • ${vehicle['plate_number']}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: ElevatedButton.icon(
            onPressed: () async {
              final dest = Uri.encodeComponent(trip!['destination'] ?? '');
              final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$dest');
              if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.map, size: 18),
            label: const Text('Navigation', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, 
              foregroundColor: isOngoing ? const Color(0xFF0E6655) : AppColors.primary, 
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton(
            onPressed: () => context.push('/driver/trips/${trip!['id']}'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white38, width: 1.5), 
              foregroundColor: Colors.white, 
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
          )),
        ]),
      ]),
    );
  }
}

class _UpcomingTripTile extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _UpcomingTripTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(trip['departure_time'] ?? '');
    return _ActivityTile(
      icon: Icons.route_outlined,
      title: trip['destination'] ?? '—',
      subtitle: dt != null ? DateFormat('MMM d, h:mm a').format(dt.toLocal()) : '—',
      color: AppColors.secondary,
    );
  }
}

// ── Technician Dashboard ─────────────────────────────────────

class _TechnicianDashboard extends ConsumerWidget {
  const _TechnicianDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(technicianDashboardProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(technicianDashboardProvider.future),
      child: dataAsync.when(
        loading: () => const _DashboardShimmer(),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Error: $e'))),
        data: (data) {
          final tasks = data['tasks'] as List;
          final done = data['completedCount'] as int;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _GreetingHeader(subtitle: "Here's your assigned workload"),
              Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Row(children: [
                Expanded(child: _StatCard(label: 'Active Tasks', value: '${tasks.length}', icon: Icons.build, color: AppColors.statusPending)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'Completed Today', value: '$done', icon: Icons.check_circle, color: AppColors.statusCompleted)),
              ])),
              _SectionHeader(title: 'My Tasks (${tasks.length})', actionLabel: 'View all', onAction: () => context.go('/maintenance')),
              if (tasks.isEmpty) 
                const _EmptyDashboard()
              else ...tasks.map((t) {
                final priority = t['priority_level'] as String? ?? 'Low';
                final building = (t['building'] as Map?)?['name'] ?? 'Main Bldg';
                final room = (t['room'] as Map?)?['name'] ?? 'General';
                return _ActivityTile(
                  icon: Icons.build_outlined, 
                  title: t['title'] ?? 'Task', 
                  subtitle: '$building • $room • $priority Priority', 
                  color: AppColors.priorityColor(priority),
                );
              }),
              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }
}

// ── HOD Dashboard ─────────────────────────────────────────────

class _HodDashboard extends ConsumerWidget {
  const _HodDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(hodPendingProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(hodPendingProvider.future),
      child: loansAsync.when(
        loading: () => const _DashboardShimmer(),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Error: $e'))),
        data: (loans) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _GreetingHeader(subtitle: 'Departmental approvals pending'),
            _QuickActions(actions: [
              (label: 'Maintenance', icon: Icons.build_outlined, path: '/maintenance'),
              (label: 'Borrow Mgmt', icon: Icons.manage_accounts_outlined, path: '/borrowing/management'),
              (label: 'Book Room', icon: Icons.meeting_room_outlined, path: '/bookings/new'),
              (label: 'Travel', icon: Icons.directions_car_outlined, path: '/travel/new'),
            ]),
            Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: _StatCard(
              label: 'Pending HOD Approvals', value: '${loans.length}',
              icon: Icons.pending_actions, color: AppColors.statusUrgent,
              onTap: () => context.go('/borrowing/management'),
            )),
            _SectionHeader(title: 'Loan Requests (${loans.length})', actionLabel: 'View all', onAction: () => context.go('/borrowing/management')),
            if (loans.isEmpty) 
              const _EmptyDashboard()
            else ...loans.map((l) {
              final item = l['item'] as Map?;
              final borrower = l['borrower'] as Map?;
              return _ActivityTile(
                icon: Icons.assignment_outlined,
                title: item?['name'] ?? 'Item Request',
                subtitle: 'By ${borrower?['full_name'] ?? 'User'} • ${l['purpose'] ?? 'No purpose'}',
                color: AppColors.statusUrgent,
              );
            }),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
