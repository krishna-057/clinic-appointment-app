import 'package:clinic_appointment_app/features/appointments/domain/appointment_slots.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppointmentSlots', () {
    test('uses 30-minute slots and excludes the 1 PM lunch hour', () {
      expect(AppointmentSlots.all, hasLength(12));
      expect(
        AppointmentSlots.all.map((slot) => slot.value),
        isNot(contains('13:00:00')),
      );
      expect(AppointmentSlots.all.first.value, '10:00:00');
      expect(AppointmentSlots.all.last.value, '16:30:00');
    });

    test('removes reserved slots for the selected doctor', () {
      final result = AppointmentSlots.available(
        date: DateTime(2026, 9, 15),
        reserved: {'10:30:00', '14:00:00'},
        now: DateTime(2026, 9, 14, 12),
      );

      expect(result.map((slot) => slot.value), isNot(contains('10:30:00')));
      expect(result.map((slot) => slot.value), isNot(contains('14:00:00')));
      expect(result, hasLength(10));
    });

    test('removes past slots when booking for today', () {
      final result = AppointmentSlots.available(
        date: DateTime(2026, 9, 14),
        reserved: const {},
        now: DateTime(2026, 9, 14, 14, 15),
      );

      expect(result.first.value, '14:30:00');
    });

    test('keeps all slots for a future date', () {
      final result = AppointmentSlots.available(
        date: DateTime(2026, 9, 15),
        reserved: const {},
        now: DateTime(2026, 9, 14, 23, 59),
      );

      expect(result, hasLength(AppointmentSlots.all.length));
    });
  });
}
