import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/appointment_repository.dart';
import '../../data/supabase_appointment_repository.dart';
import '../../domain/appointment.dart';
import '../../domain/appointment_status.dart';
import '../../domain/doctor.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return SupabaseAppointmentRepository(Supabase.instance.client);
});

final doctorsProvider = FutureProvider<List<Doctor>>((ref) {
  return ref.watch(appointmentRepositoryProvider).getDoctors();
});

typedef SlotRequest = ({String doctorId, DateTime date});

final reservedSlotsProvider = FutureProvider.family<Set<String>, SlotRequest>((
  ref,
  request,
) {
  return ref
      .watch(appointmentRepositoryProvider)
      .getReservedStartTimes(doctorId: request.doctorId, date: request.date);
});

final appointmentsProvider =
    AsyncNotifierProvider<AppointmentsViewModel, List<Appointment>>(
      AppointmentsViewModel.new,
    );

class AppointmentsViewModel extends AsyncNotifier<List<Appointment>> {
  AppointmentRepository get _repository =>
      ref.read(appointmentRepositoryProvider);

  @override
  Future<List<Appointment>> build() => _repository.getAppointments();

  Future<void> createAppointment({
    required String patientName,
    required String mobileNumber,
    required String doctorId,
    required DateTime date,
    required String startTime,
    String? description,
  }) async {
    await _repository.createAppointment(
      patientName: patientName,
      mobileNumber: mobileNumber,
      doctorId: doctorId,
      date: date,
      startTime: startTime,
      description: description,
    );
    ref.invalidate(reservedSlotsProvider);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateStatus({
    required String appointmentId,
    required AppointmentStatus status,
    String? cancellationReason,
  }) async {
    await _repository.updateStatus(
      appointmentId: appointmentId,
      status: status,
      cancellationReason: cancellationReason,
    );
    ref.invalidate(reservedSlotsProvider);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteAppointment(String appointmentId) async {
    await _repository.deleteAppointment(appointmentId);
    ref.invalidate(reservedSlotsProvider);
    ref.invalidateSelf();
    await future;
  }
}
