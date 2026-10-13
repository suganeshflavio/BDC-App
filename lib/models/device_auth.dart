class DeviceUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;

  const DeviceUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
  });

  factory DeviceUser.fromJson(Map<String, dynamic> json) {
    return DeviceUser(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Member',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
    };
  }
}

class DeviceAuthResponse {
  final String token;
  final DeviceUser user;

  const DeviceAuthResponse({
    required this.token,
    required this.user,
  });

  factory DeviceAuthResponse.fromJson(Map<String, dynamic> json) {
    return DeviceAuthResponse(
      token: json['token'] as String? ?? '',
      user: DeviceUser.fromJson((json['user'] as Map<String, dynamic>?) ?? {}),
    );
  }
}
