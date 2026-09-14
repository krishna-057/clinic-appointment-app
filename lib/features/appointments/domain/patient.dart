class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.mobileNumber,
  });

  final String id;
  final String name;
  final String mobileNumber;

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id'] as String,
    name: json['name'] as String,
    mobileNumber: json['mobile_number'] as String,
  );
}
