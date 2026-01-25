class ProfileEntity {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? phoneNumber;
  final String? organizationName;
  final bool isVerified;
  final String? avatarUrl;
  final String? legalDocsUrl;
  final String? defaultLocation;

  const ProfileEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    this.organizationName,
    required this.isVerified,
    this.avatarUrl,
    this.legalDocsUrl,
    this.defaultLocation,
  });
}
