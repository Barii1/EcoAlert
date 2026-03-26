enum UserRole {
  general,
  registered,
  premium,
  admin,
}

UserRole _userRoleFromString(String? value) {
  switch (value) {
    case 'general':
      return UserRole.general;
    case 'premium':
      return UserRole.premium;
    case 'admin':
      return UserRole.admin;
    case 'registered':
    default:
      return UserRole.registered;
  }
}

String _userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.general:
      return 'general';
    case UserRole.premium:
      return 'premium';
    case UserRole.admin:
      return 'admin';
    case UserRole.registered:
      return 'registered';
  }
}

class UserModel {
  final String id;
  final String username;
  final String email;
  final String phoneNumber;
  final String cnicNumber;
  final String province;
  final String city;
  final DateTime createdAt;
  final UserRole role;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.cnicNumber,
    required this.province,
    required this.city,
    required this.createdAt,
    this.role = UserRole.registered,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      cnicNumber: json['cnicNumber'] as String,
      province: json['province'] as String,
      city: json['city'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      role: _userRoleFromString(json['role'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'cnicNumber': cnicNumber,
      'province': province,
      'city': city,
      'createdAt': createdAt.toIso8601String(),
      'role': _userRoleToString(role),
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? phoneNumber,
    String? cnicNumber,
    String? province,
    String? city,
    DateTime? createdAt,
    UserRole? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      province: province ?? this.province,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
    );
  }
}
