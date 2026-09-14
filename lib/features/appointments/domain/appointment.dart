import 'appointment_status.dart';
import 'doctor.dart';
import 'patient.dart';

class Appointment {
  const Appointment({
    required this.id,
    required this.referenceCode,
    required this.patient,
    required this.doctor,
    required this.date,
    required this.startTime,
    required this.status,
    this.description,
    this.cancellationReason,
  });

  final String id;
  final String referenceCode;
  final Patient patient;
  final Doctor doctor;
  final DateTime date;
  final String startTime;
  final AppointmentStatus status;
  final String? description;
  final String? cancellationReason;

  DateTime get startsAt {
    final parts = startTime.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] as String,
    referenceCode: json['reference_code'] as String,
    patient: Patient.fromJson(json['patient'] as Map<String, dynamic>),
    doctor: Doctor.fromJson(json['doctor'] as Map<String, dynamic>),
    date: DateTime.parse(json['appointment_date'] as String),
    startTime: json['start_time'] as String,
    status: AppointmentStatus.fromJson(json['status'] as String),
    description: json['description'] as String?,
    cancellationReason: json['cancellation_reason'] as String?,
  );
}
