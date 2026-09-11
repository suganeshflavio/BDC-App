class AboutUs {
  final int id;
  final String churchName;
  final String ministryName;
  final String description;
  final String contactNumber;

  AboutUs({
    required this.id,
    required this.churchName,
    required this.ministryName,
    required this.description,
    required this.contactNumber,
  });

  factory AboutUs.fromJson(Map<String, dynamic> json) {
    return AboutUs(
      id: json['id'] as int? ?? 0,
      churchName: (json['church_name'] as String?)?.trim() ?? '',
      ministryName: (json['ministry_name'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      contactNumber: (json['contact_number'] as String?)?.trim() ?? '',
    );
  }

  factory AboutUs.empty() {
    return AboutUs(
      id: 0,
      churchName: '',
      ministryName: '',
      description: '',
      contactNumber: '',
    );
  }

  bool get isEmpty =>
      churchName.isEmpty &&
      ministryName.isEmpty &&
      description.isEmpty &&
      contactNumber.isEmpty;

  bool get isNotEmpty => !isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'church_name': churchName,
      'ministry_name': ministryName,
      'description': description,
      'contact_number': contactNumber,
    };
  }
}
