import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/appointment_slots.dart';
import '../../domain/doctor.dart';
import '../providers/appointment_providers.dart';

class AppointmentForm extends ConsumerStatefulWidget {
  const AppointmentForm({super.key});

  @override
  ConsumerState<AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends ConsumerState<AppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final TextEditingController _dateController;

  Doctor? _selectedDoctor;
  DateTime _selectedDate = _dateOnly(DateTime.now());
  String? _selectedTime;
  bool _isSubmitting = false;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: _formattedDate);
  }

  String get _formattedDate =>
      DateFormat('EEE, d MMM yyyy').format(_selectedDate);

  @override
  void dispose() {
    _patientNameController.dispose();
    _mobileController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _normalizedMobile(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    return digits;
  }

  Future<void> _pickDate() async {
    final today = _dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 9)),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formattedDate;
        _selectedTime = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDoctor == null || _selectedTime == null) {
      _showMessage('Please select a doctor and an available time.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(appointmentsProvider.notifier)
          .createAppointment(
            patientName: _patientNameController.text,
            mobileNumber: _normalizedMobile(_mobileController.text),
            doctorId: _selectedDoctor!.id,
            date: _selectedDate,
            startTime: _selectedTime!,
            description: _descriptionController.text,
          );

      if (!mounted) return;
      _formKey.currentState!.reset();
      _patientNameController.clear();
      _mobileController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedDoctor = null;
        _selectedDate = _dateOnly(DateTime.now());
        _dateController.text = _formattedDate;
        _selectedTime = null;
      });
      _showMessage('Appointment booked successfully.', isSuccess: true);
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? Colors.green.shade700 : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final doctors = ref.watch(doctorsProvider);
    final slotRequest = _selectedDoctor == null
        ? null
        : (doctorId: _selectedDoctor!.id, date: _selectedDate);
    final reservedSlots = slotRequest == null
        ? null
        : ref.watch(reservedSlotsProvider(slotRequest));

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Book an appointment',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Enter patient details and choose a free slot.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _patientNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Patient name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.isEmpty) return 'Patient name is required.';
                  if (name.length < 2) return 'Enter at least 2 characters.';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  hintText: '10-digit Indian mobile number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final mobile = _normalizedMobile(value ?? '');
                  if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile)) {
                    return 'Enter a valid Indian mobile number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              doctors.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => OutlinedButton.icon(
                  onPressed: () => ref.invalidate(doctorsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry loading doctors'),
                ),
                data: (items) => DropdownButtonFormField<Doctor>(
                  initialValue: _selectedDoctor,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Doctor',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: items
                      .map(
                        (doctor) => DropdownMenuItem(
                          value: doctor,
                          child: Text(
                            '${doctor.name} — ${doctor.specialization}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (doctor) {
                    setState(() {
                      _selectedDoctor = doctor;
                      _selectedTime = null;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Select a doctor.' : null,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                readOnly: true,
                onTap: _pickDate,
                decoration: InputDecoration(
                  labelText: 'Appointment date',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: const OutlineInputBorder(),
                  hintText: DateFormat('EEE, d MMM yyyy').format(_selectedDate),
                ),
                controller: _dateController,
              ),
              const SizedBox(height: 14),
              _TimeSlotField(
                reservedSlots: reservedSlots,
                selectedDate: _selectedDate,
                selectedTime: _selectedTime,
                enabled: _selectedDoctor != null,
                onChanged: (time) => setState(() => _selectedTime = time),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Reason for visit or notes',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isSubmitting ? 'Booking…' : 'Book appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeSlotField extends StatelessWidget {
  const _TimeSlotField({
    required this.reservedSlots,
    required this.selectedDate,
    required this.selectedTime,
    required this.enabled,
    required this.onChanged,
  });

  final AsyncValue<Set<String>>? reservedSlots;
  final DateTime selectedDate;
  final String? selectedTime;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Appointment time',
          prefixIcon: Icon(Icons.schedule_outlined),
          border: OutlineInputBorder(),
        ),
        child: Text('Select a doctor first'),
      );
    }

    return reservedSlots!.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, stackTrace) => InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Appointment time',
          errorText: 'Could not load available times.',
          border: OutlineInputBorder(),
        ),
        child: const Text('Try selecting the doctor again'),
      ),
      data: (reserved) {
        final available = AppointmentSlots.available(
          date: selectedDate,
          reserved: reserved,
        );
        final validValue = available.any((slot) => slot.value == selectedTime)
            ? selectedTime
            : null;

        if (available.isEmpty) {
          return const InputDecorator(
            decoration: InputDecoration(
              labelText: 'Appointment time',
              border: OutlineInputBorder(),
            ),
            child: Text('No free slots for this date'),
          );
        }

        return DropdownButtonFormField<String>(
          initialValue: validValue,
          decoration: const InputDecoration(
            labelText: 'Appointment time',
            prefixIcon: Icon(Icons.schedule_outlined),
            border: OutlineInputBorder(),
          ),
          items: available
              .map(
                (slot) => DropdownMenuItem(
                  value: slot.value,
                  child: Text(slot.label),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: (value) => value == null ? 'Select a time.' : null,
        );
      },
    );
  }
}
