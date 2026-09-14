class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialization,
  });

  final String id;
  final String name;
  final String specialization;

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
    id: json['id'] as String,
    name: json['name'] as String,
    specialization: json['specialization'] as String,
  );
}
