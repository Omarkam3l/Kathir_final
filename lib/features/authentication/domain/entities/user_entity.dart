class UserEntity {
  final String id;
  final String email;
  final String role;
  final String fullName;
  final String? phoneNumber;
  final String? organizationName;
  final bool isVerified;
  final String approvalStatus;

  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
    required this.fullName,
    this.phoneNumber,
    this.organizationName,
    required this.isVerified,
    this.approvalStatus = 'pending',
  });

  /// Check if user needs approval (restaurant or NGO)
  bool get needsApproval => role == 'rest' || role == 'ngo';

  /// Check if user is approved
  bool get isApproved => approvalStatus == 'approved';
}


