import '../domain/appointment.dart';
import '../domain/appointment_status.dart';
import '../domain/doctor.dart';

abstract interface class AppointmentRepository {
  Future<List<Doctor>> getDoctors();

  Future<List<Appointment>> getAppointments();

  Future<void> createAppointment({
    required String patientName,
    required String mobileNumber,
    required String doctorId,
    required DateTime date,
    required String startTime,
    String? description,
  });

  Future<void> updateStatus({
    required String appointmentId,
    required AppointmentStatus status,
    String? cancellationReason,
  });

  Future<void> deleteAppointment(String appointmentId);
}
