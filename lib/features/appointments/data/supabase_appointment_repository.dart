import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/appointment.dart';
import '../domain/appointment_status.dart';
import '../domain/doctor.dart';
import 'appointment_repository.dart';

class SupabaseAppointmentRepository implements AppointmentRepository {
  const SupabaseAppointmentRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Doctor>> getDoctors() async {
    final rows = await _client.from('doctors').select().order('name');
    return rows.map(Doctor.fromJson).toList();
  }

  @override
  Future<List<Appointment>> getAppointments() async {
    final rows = await _client
        .from('appointments')
        .select(
          'id, reference_code, appointment_date, start_time, status, '
          'description, cancellation_reason, '
          'patient:patients(id, name, mobile_number), '
          'doctor:doctors(id, name, specialization)',
        )
        .order('appointment_date')
        .order('start_time');

    return rows.map(Appointment.fromJson).toList();
  }

  @override
  Future<Set<String>> getReservedStartTimes({
    required String doctorId,
    required DateTime date,
  }) async {
    final rows = await _client
        .from('appointments')
        .select('start_time')
        .eq('doctor_id', doctorId)
        .eq('appointment_date', DateFormat('yyyy-MM-dd').format(date))
        .eq('status', AppointmentStatus.scheduled.name);

    return rows.map((row) => row['start_time'] as String).toSet();
  }

  @override
  Future<void> createAppointment({
    required String patientName,
    required String mobileNumber,
    required String doctorId,
    required DateTime date,
    required String startTime,
    String? description,
  }) async {
    final existingPatients = await _client
        .from('patients')
        .select('id')
        .eq('mobile_number', mobileNumber)
        .ilike('name', patientName.trim())
        .limit(1);

    final String patientId;
    if (existingPatients.isEmpty) {
      final patient = await _client
          .from('patients')
          .insert({'name': patientName.trim(), 'mobile_number': mobileNumber})
          .select('id')
          .single();
      patientId = patient['id'] as String;
    } else {
      patientId = existingPatients.first['id'] as String;
    }

    try {
      await _client.from('appointments').insert({
        'patient_id': patientId,
        'doctor_id': doctorId,
        'appointment_date': DateFormat('yyyy-MM-dd').format(date),
        'start_time': startTime,
        'description': description?.trim().isEmpty ?? true
            ? null
            : description!.trim(),
      });
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const AppointmentConflictException();
      }
      rethrow;
    }
  }

  @override
  Future<void> updateStatus({
    required String appointmentId,
    required AppointmentStatus status,
    String? cancellationReason,
  }) => _client
      .from('appointments')
      .update({
        'status': status.name,
        'cancellation_reason': status == AppointmentStatus.cancelled
            ? cancellationReason?.trim()
            : null,
      })
      .eq('id', appointmentId);

  @override
  Future<void> deleteAppointment(String appointmentId) =>
      _client.from('appointments').delete().eq('id', appointmentId);
}
