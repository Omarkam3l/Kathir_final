import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    super.phoneNumber,
    super.organizationName,
    required super.isVerified,
    super.avatarUrl,
    super.legalDocsUrl,
    super.defaultLocation,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'user',
      phoneNumber: json['phone_number'] as String?,
      organizationName: json['organization_name'] as String?,
      isVerified: (json['is_verified'] as bool?) ?? false,
      avatarUrl: json['avatar_url'] as String?,
      legalDocsUrl: json['legal_docs_url'] as String?,
      defaultLocation: json['default_location'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role,
        'phone_number': phoneNumber,
        'organization_name': organizationName,
        'is_verified': isVerified,
        'avatar_url': avatarUrl,
        'legal_docs_url': legalDocsUrl,
        'default_location': defaultLocation,
      };
}
