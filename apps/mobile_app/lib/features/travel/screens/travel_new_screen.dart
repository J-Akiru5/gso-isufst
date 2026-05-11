import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/tokens/app_colors.dart';
import '../providers/travel_provider.dart';

class TravelNewScreen extends ConsumerStatefulWidget {
  const TravelNewScreen({super.key});

  @override
  ConsumerState<TravelNewScreen> createState() => _TravelNewScreenState();
}

class _TravelNewScreenState extends ConsumerState<TravelNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destination = TextEditingController();
  final _purpose = TextEditingController();
  final _passengerNames = TextEditingController();
  final _passengerCount = TextEditingController(text: '1');
  DateTime? _departure;
  DateTime? _return;
  bool _saving = false;

  @override
  void dispose() {
    _destination.dispose();
    _purpose.dispose();
    _passengerNames.dispose();
    _passengerCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Travel Request')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _destination,
              decoration: const InputDecoration(labelText: 'Destination'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _purpose,
              decoration: const InputDecoration(labelText: 'Purpose'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDateTime(isDeparture: true),
                    icon: const Icon(Icons.event),
                    label: Text(_departure == null ? 'Departure Date' : _fmt(_departure!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDateTime(isDeparture: false),
                    icon: const Icon(Icons.event_available),
                    label: Text(_return == null ? 'Return Date' : _fmt(_return!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passengerCount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of Passengers'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1) return 'Enter valid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passengerNames,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Passenger Names',
                hintText: 'One name per line or comma-separated',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(_saving ? 'Submitting...' : 'Submit Request'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime({required bool isDeparture}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      initialDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;

    final value = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isDeparture) {
        _departure = value;
      } else {
        _return = value;
      }
    });
  }

  String _fmt(DateTime value) {
    final t = TimeOfDay.fromDateTime(value);
    final hh = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '${value.month}/${value.day}/${value.year} $hh:$mm $suffix';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_departure == null || _return == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select departure and return dates.')),
      );
      return;
    }
    if (_return!.isBefore(_departure!) ||
        _return!.isAtSameMomentAs(_departure!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return time must be after departure time.')),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final create = ref.read(createTravelBookingProvider);
      await create({
        'requester_id': user.id,
        'destination': _destination.text.trim(),
        'purpose': _purpose.text.trim(),
        'departure_time': _departure!.toIso8601String(),
        'return_time': _return!.toIso8601String(),
        'passenger_count': int.parse(_passengerCount.text.trim()),
        'passenger_names': _passengerNames.text.trim().isEmpty ? null : _passengerNames.text.trim(),
        'status': 'Pending',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Travel request submitted.')),
      );
      context.go('/travel');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
