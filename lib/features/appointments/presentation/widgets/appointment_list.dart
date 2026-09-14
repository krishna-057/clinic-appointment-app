import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/appointment.dart';
import '../../domain/appointment_slots.dart';
import '../../domain/appointment_status.dart';
import '../providers/appointment_providers.dart';

enum AppointmentFilter { today, upcoming, completed, cancelled, all }

extension on AppointmentFilter {
  String get label => switch (this) {
    AppointmentFilter.today => 'Today',
    AppointmentFilter.upcoming => 'Upcoming',
    AppointmentFilter.completed => 'Completed',
    AppointmentFilter.cancelled => 'Cancelled',
    AppointmentFilter.all => 'All',
  };
}

class AppointmentList extends ConsumerStatefulWidget {
  const AppointmentList({super.key});

  @override
  ConsumerState<AppointmentList> createState() => _AppointmentListState();
}

class _AppointmentListState extends ConsumerState<AppointmentList> {
  AppointmentFilter _filter = AppointmentFilter.all;
  String _search = '';

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Appointment> _visibleAppointments(List<Appointment> source) {
    final now = DateTime.now();
    final query = _search.trim().toLowerCase();

    return source.where((appointment) {
      final matchesFilter = switch (_filter) {
        AppointmentFilter.today => _sameDate(appointment.date, now),
        AppointmentFilter.upcoming =>
          appointment.status == AppointmentStatus.scheduled &&
              appointment.startsAt.isAfter(now),
        AppointmentFilter.completed =>
          appointment.status == AppointmentStatus.completed,
        AppointmentFilter.cancelled =>
          appointment.status == AppointmentStatus.cancelled,
        AppointmentFilter.all => true,
      };

      final searchable = [
        appointment.patient.name,
        appointment.patient.mobileNumber,
        appointment.doctor.name,
        appointment.referenceCode,
      ].join(' ').toLowerCase();

      return matchesFilter && (query.isEmpty || searchable.contains(query));
    }).toList();
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Back'),
              ),
              FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(backgroundColor: Colors.red)
                    : null,
                onPressed: () => Navigator.pop(context, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _complete(Appointment appointment) async {
    final confirmed = await _confirm(
      title: 'Complete appointment?',
      message: '${appointment.referenceCode} will be marked as completed.',
      action: 'Complete',
    );
    if (!confirmed) return;

    await _runAction(
      () => ref
          .read(appointmentsProvider.notifier)
          .updateStatus(
            appointmentId: appointment.id,
            status: AppointmentStatus.completed,
          ),
      'Appointment marked as completed.',
    );
  }

  Future<void> _cancel(Appointment appointment) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: TextField(
          controller: reasonController,
          maxLength: 200,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null) return;

    await _runAction(
      () => ref
          .read(appointmentsProvider.notifier)
          .updateStatus(
            appointmentId: appointment.id,
            status: AppointmentStatus.cancelled,
            cancellationReason: reason,
          ),
      'Appointment cancelled. The slot is available again.',
    );
  }

  Future<void> _delete(Appointment appointment) async {
    final confirmed = await _confirm(
      title: 'Delete appointment permanently?',
      message:
          '${appointment.referenceCode} will be permanently removed. '
          'Use this only for an incorrectly created record.',
      action: 'Delete permanently',
      destructive: true,
    );
    if (!confirmed) return;

    await _runAction(
      () => ref
          .read(appointmentsProvider.notifier)
          .deleteAppointment(appointment.id),
      'Appointment deleted.',
    );
  }

  Future<void> _runAction(
    Future<void> Function() operation,
    String successMessage,
  ) async {
    try {
      await operation();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(appointmentsProvider);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Appointments',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: const InputDecoration(
                hintText: 'Search patient, mobile, doctor, or reference',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<AppointmentFilter>(
                segments: AppointmentFilter.values
                    .map(
                      (filter) => ButtonSegment(
                        value: filter,
                        label: Text(filter.label),
                      ),
                    )
                    .toList(),
                selected: {_filter},
                onSelectionChanged: (selection) {
                  setState(() => _filter = selection.first);
                },
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: appointments.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _ListMessage(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load appointments',
                  subtitle: error.toString(),
                  action: OutlinedButton.icon(
                    onPressed: () => ref.invalidate(appointmentsProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ),
                data: (items) {
                  final visible = _visibleAppointments(items);
                  if (visible.isEmpty) {
                    return const _ListMessage(
                      icon: Icons.event_available_outlined,
                      title: 'No appointments found',
                      subtitle: 'Book an appointment or change the filter.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(appointmentsProvider);
                      await ref.read(appointmentsProvider.future);
                    },
                    child: ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _AppointmentCard(
                        appointment: visible[index],
                        onComplete: _complete,
                        onCancel: _cancel,
                        onDelete: _delete,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onComplete,
    required this.onCancel,
    required this.onDelete,
  });

  final Appointment appointment;
  final ValueChanged<Appointment> onComplete;
  final ValueChanged<Appointment> onCancel;
  final ValueChanged<Appointment> onDelete;

  @override
  Widget build(BuildContext context) {
    final canComplete =
        appointment.status == AppointmentStatus.scheduled &&
        !appointment.startsAt.isAfter(DateTime.now());
    final canCancel = appointment.status == AppointmentStatus.scheduled;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        shape: const Border(),
        leading: CircleAvatar(
          child: Text(appointment.patient.name.substring(0, 1).toUpperCase()),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                appointment.patient.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            _StatusChip(status: appointment.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${appointment.doctor.name} • '
            '${DateFormat('d MMM').format(appointment.date)} • '
            '${AppointmentSlots.formatStoredTime(context, appointment.startTime)}',
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          _Detail(label: 'Reference', value: appointment.referenceCode),
          _Detail(label: 'Mobile', value: appointment.patient.mobileNumber),
          _Detail(
            label: 'Specialization',
            value: appointment.doctor.specialization,
          ),
          _Detail(
            label: 'Description',
            value: appointment.description?.trim().isNotEmpty == true
                ? appointment.description!
                : 'No description',
          ),
          if (appointment.status == AppointmentStatus.cancelled)
            _Detail(
              label: 'Cancellation reason',
              value: appointment.cancellationReason?.trim().isNotEmpty == true
                  ? appointment.cancellationReason!
                  : 'No reason provided',
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (appointment.status == AppointmentStatus.scheduled)
                  FilledButton.tonalIcon(
                    onPressed: canComplete
                        ? () => onComplete(appointment)
                        : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      canComplete ? 'Complete' : 'Complete after visit',
                    ),
                  ),
                if (canCancel)
                  OutlinedButton.icon(
                    onPressed: () => onCancel(appointment),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                  ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => onDelete(appointment),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AppointmentStatus.scheduled => Colors.blue,
      AppointmentStatus.completed => Colors.green,
      AppointmentStatus.cancelled => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ListMessage extends StatelessWidget {
  const _ListMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}
