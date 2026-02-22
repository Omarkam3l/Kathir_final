import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    super.phoneNumber,
    required super.isVerified,
    super.avatarUrl,
    super.defaultLocation,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'user',
      phoneNumber: json['phone_number'] as String?,
      isVerified: (json['is_verified'] as bool?) ?? false,
      avatarUrl: json['avatar_url'] as String?,
      defaultLocation: json['default_location'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role,
        'phone_number': phoneNumber,
        'is_verified': isVerified,
        'avatar_url': avatarUrl,
        'default_location': defaultLocation,
      };
}
