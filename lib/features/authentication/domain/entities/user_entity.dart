class UserEntity {
  final String id;
  final String email;
  final String role;
  final String fullName;
  final String? phoneNumber;
  final String? organizationName;
  final bool isVerified;

  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
    required this.fullName,
    this.phoneNumber,
    this.organizationName,
    required this.isVerified,
  });
}

