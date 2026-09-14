enum AppointmentStatus {
  scheduled,
  completed,
  cancelled;

  String get label => switch (this) {
    scheduled => 'Scheduled',
    completed => 'Completed',
    cancelled => 'Cancelled',
  };

  static AppointmentStatus fromJson(String value) =>
      AppointmentStatus.values.firstWhere((status) => status.name == value);
}
