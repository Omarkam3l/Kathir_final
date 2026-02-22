class ProfileEntity {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? phoneNumber;
  final bool isVerified;
  final String? avatarUrl;
  final String? defaultLocation;

  const ProfileEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    required this.isVerified,
    this.avatarUrl,
    this.defaultLocation,
  });
}
