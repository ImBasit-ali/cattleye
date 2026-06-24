/// User Model - Represents authenticated user/farmer
class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? phoneNumber;
  final String? farmName;
  final String? farmLocation;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  
  // Preferences
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.farmName,
    this.farmLocation,
    required this.createdAt,
    this.lastLoginAt,
    this.preferences,
  });

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      farmName: json['farm_name'] as String?,
      farmLocation: json['farm_location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone_number': phoneNumber,
      'farm_name': farmName,
      'farm_location': farmLocation,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'preferences': preferences,
    };
  }

  /// Create a copy with modified fields
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? farmName,
    String? farmLocation,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      farmName: farmName ?? this.farmName,
      farmLocation: farmLocation ?? this.farmLocation,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
    );
  }

  /// Get display name (name or email)
  String get displayName => name ?? email;

  @override
  String toString() {
    return 'UserModel{id: $id, email: $email, name: $name}';
  }
}
