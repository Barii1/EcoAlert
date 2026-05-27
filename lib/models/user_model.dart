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
  final List<String> healthConditions;

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
    this.healthConditions = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String readString(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = json[key];
        if (value is String && value.isNotEmpty) return value;
      }
      return fallback;
    }

    return UserModel(
      id: readString(['id']),
      username: readString(['username']),
      email: readString(['email']),
      phoneNumber: readString(['phoneNumber', 'phone_number']),
      cnicNumber: readString(['cnicNumber', 'cnic_number', 'cnic_hash']),
      province: readString(['province']),
      city: readString(['city']),
      createdAt: DateTime.tryParse(
            readString(['createdAt', 'created_at'])
          ) ??
          DateTime.now(),
      role: _userRoleFromString(json['role'] as String?),
      healthConditions: (json['health_conditions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
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
      'health_conditions': healthConditions,
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
    List<String>? healthConditions,
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
      healthConditions: healthConditions ?? this.healthConditions,
    );
  }
}
