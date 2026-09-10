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
      id: json['id'] as int? ?? 1,
      churchName: json['church_name'] as String? ?? 'Bethesda Deliverance Church',
      ministryName: json['ministry_name'] as String? ?? 'The Feet of Heavenly Father Ministries',
      description: json['description'] as String? ?? '',
      contactNumber: json['contact_number'] as String? ?? '94436-94891',
    );
  }

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
