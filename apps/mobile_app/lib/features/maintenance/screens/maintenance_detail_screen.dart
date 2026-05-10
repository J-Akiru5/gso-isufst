import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/maintenance/providers/maintenance_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MaintenanceDetailScreen extends ConsumerWidget {
  final String id;

  const MaintenanceDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(maintenanceDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Detail'),
      ),
      body: detailAsync.when(
        data: (request) => _DetailBody(request: request),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (request) => Consumer(
          builder: (context, ref, child) => _buildActionButtons(context, ref, request),
        ),
        orElse: () => null,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Map<String, dynamic> request) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.maybeWhen(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final roles = (profile['user_roles'] as List)
            .map((ur) => ur['roles']['name'] as String)
            .toList();
        
        final isHOD = roles.contains('department_head');
        final isGSO = roles.contains('gso_staff') || roles.contains('super_admin');
        final isTechnician = roles.contains('technician');
        final userId = profile['id'];

        if (isHOD && request['status'] == 'Pending_HOD') {
          return _HODActions(request: request, userId: userId);
        }

        // Default "Update" button for others or technicians
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement more actions
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF142D55),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Update Status'),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _HODActions extends ConsumerStatefulWidget {
  final Map<String, dynamic> request;
  final String userId;

  const _HODActions({required this.request, required this.userId});

  @override
  ConsumerState<_HODActions> createState() => _HODActionsState();
}

class _HODActionsState extends ConsumerState<_HODActions> {
  bool _isSubmitting = false;

  Future<void> _updateStatus(String newStatus, String title, [String? description]) async {
    setState(() => _isSubmitting = true);
    try {
      final supabase = Supabase.instance.client;
      
      await supabase.from('maintenance_requests').update({
        'status': newStatus,
      }).eq('id', widget.request['id']);

      await supabase.from('maintenance_timeline').insert({
        'request_id': widget.request['id'],
        'status': newStatus,
        'title': title,
        'description': description,
        'performed_by': widget.userId,
      });

      if (mounted) {
        ref.refresh(maintenanceDetailProvider(widget.request['id']));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $title')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => _showRejectDialog(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _updateStatus('HOD_Approved', 'HOD Approved'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Approve'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason for rejection...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus('HOD_Rejected', 'HOD Rejected', controller.text);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final Map<String, dynamic> request;

  const _DetailBody({required this.request});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderSection(request: request),
          const Divider(height: 32),
          _InfoSection(request: request),
          const SizedBox(height: 24),
          _DescriptionSection(request: request),
          const SizedBox(height: 24),
          if (request['attachments'] != null && (request['attachments'] as List).isNotEmpty)
            _AttachmentsSection(attachments: request['attachments']),
          const SizedBox(height: 24),
          const Text(
            'Timeline',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, child) {
              final timelineAsync = ref.watch(maintenanceTimelineStreamProvider(request['id']));
              return timelineAsync.when(
                data: (timeline) => _TimelineSection(timeline: timeline),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading timeline: $err'),
              );
            },
          ),
          const SizedBox(height: 80), // Space for bottom button
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final Map<String, dynamic> request;

  const _HeaderSection({required this.request});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              request['request_number'] ?? '',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            _StatusBadge(status: request['status']),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          request['title'] ?? '',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Map<String, dynamic> request;

  const _InfoSection({required this.request});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow(
          icon: Icons.category_outlined,
          label: 'Category',
          value: request['category']?['name'] ?? 'Uncategorized',
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: '${request['building']?['name'] ?? ''} ${request['room']?['name'] ?? ''}',
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.person_outline,
          label: 'Requester',
          value: request['requester']?['full_name'] ?? '',
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.calendar_today_outlined,
          label: 'Submitted',
          value: DateFormat('MMMM d, yyyy').format(DateTime.parse(request['created_at'])),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final Map<String, dynamic> request;

  const _DescriptionSection({required this.request});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          request['description'] ?? '',
          style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.5),
        ),
      ],
    );
  }
}

class _AttachmentsSection extends StatelessWidget {
  final List attachments;

  const _AttachmentsSection({required this.attachments});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachments',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: attachments.length,
            itemBuilder: (context, index) {
              final url = attachments[index]['file_url'];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[100]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final List timeline;

  const _TimelineSection({required this.timeline});

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) return const Text('No history available.');

    final sorted = List.from(timeline)..sort((a, b) => b['created_at'].compareTo(a['created_at']));

    return Column(
      children: sorted.map((entry) {
        return _TimelineItem(entry: entry);
      }).toList(),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _TimelineItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFF142D55),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 40,
              color: Colors.grey[200],
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    DateFormat('h:mm a').format(DateTime.parse(entry['created_at'])),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
              if (entry['description'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    entry['description'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Submitted': color = Colors.blue; break;
      case 'Pending_HOD': color = Colors.orange; break;
      case 'HOD_Approved': color = Colors.green; break;
      case 'In_Progress': color = Colors.purple; break;
      case 'Completed': color = Colors.teal; break;
      case 'Closed': color = Colors.grey; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
