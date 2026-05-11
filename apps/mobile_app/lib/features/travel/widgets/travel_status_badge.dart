import 'package:flutter/material.dart';
import '../../../core/tokens/app_colors.dart';

class TravelStatusBadge extends StatelessWidget {
  final String status;
  const TravelStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _statusColor(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return AppColors.statusPending;
      case 'approved':
      case 'scheduled':
        return AppColors.statusInProgress;
      case 'ongoing':
        return AppColors.secondary;
      case 'completed':
        return AppColors.statusCompleted;
      case 'rejected':
      case 'cancelled':
        return AppColors.statusRejected;
      default:
        return AppColors.neutral500;
    }
  }
}
