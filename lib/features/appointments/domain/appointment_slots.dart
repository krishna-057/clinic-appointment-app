import 'package:flutter/material.dart';

class AppointmentSlot {
  const AppointmentSlot({required this.value, required this.label});

  final String value;
  final String label;
}

abstract final class AppointmentSlots {
  static const all = <AppointmentSlot>[
    AppointmentSlot(value: '10:00:00', label: '10:00 AM'),
    AppointmentSlot(value: '10:30:00', label: '10:30 AM'),
    AppointmentSlot(value: '11:00:00', label: '11:00 AM'),
    AppointmentSlot(value: '11:30:00', label: '11:30 AM'),
    AppointmentSlot(value: '12:00:00', label: '12:00 PM'),
    AppointmentSlot(value: '12:30:00', label: '12:30 PM'),
    AppointmentSlot(value: '14:00:00', label: '2:00 PM'),
    AppointmentSlot(value: '14:30:00', label: '2:30 PM'),
    AppointmentSlot(value: '15:00:00', label: '3:00 PM'),
    AppointmentSlot(value: '15:30:00', label: '3:30 PM'),
    AppointmentSlot(value: '16:00:00', label: '4:00 PM'),
    AppointmentSlot(value: '16:30:00', label: '4:30 PM'),
  ];

  static List<AppointmentSlot> available({
    required DateTime date,
    required Set<String> reserved,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();

    return all.where((slot) {
      if (reserved.contains(slot.value)) return false;

      final parts = slot.value.split(':');
      final startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      return startsAt.isAfter(current);
    }).toList();
  }

  static String formatStoredTime(BuildContext context, String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    ).format(context);
  }
}
