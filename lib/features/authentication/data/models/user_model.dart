import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.role,
    required super.fullName,
    super.phoneNumber,
    super.organizationName,
    required super.isVerified,
    super.approvalStatus = 'pending',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] as String?,
      organizationName: json['organization_name'] as String?,
      isVerified: (json['is_verified'] as bool?) ?? false,
      approvalStatus: (json['approval_status'] as String?) ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'organization_name': organizationName,
        'is_verified': isVerified,
        'approval_status': approvalStatus,
      };
}


extension UserModelFactory on UserModel {
  static UserModel fromAuthUser(User user) {
    final meta = user.userMetadata ?? const <String, dynamic>{};
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      role: (meta['role'] as String?) ?? 'user',
      fullName: (meta['full_name'] as String?) ?? '',
      phoneNumber: user.phone,
      organizationName: (meta['organization_name'] as String?),
      isVerified: user.emailConfirmedAt != null,
    );
  }
}
