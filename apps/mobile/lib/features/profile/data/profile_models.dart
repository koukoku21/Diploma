class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.avatarUrl,
    this.masterProfileId,
    this.masterStatus,
    this.rejectionReason,
  });

  final String id;
  final String name;
  final String phone;
  final String? avatarUrl;
  final String? masterProfileId;
  final String? masterStatus; // PENDING | APPROVED | REJECTED
  final String? rejectionReason;

  bool get isMaster => masterStatus == 'APPROVED';
  bool get hasMasterProfile => masterProfileId != null;

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    final mp = j['masterProfile'] as Map<String, dynamic>?;
    return UserProfile(
      id: j['id'] as String,
      name: j['name'] as String,
      phone: j['phone'] as String,
      avatarUrl: j['avatarUrl'] as String?,
      masterProfileId: mp?['id'] as String?,
      masterStatus: mp?['status'] as String?,
      rejectionReason: mp?['rejectionReason'] as String?,
    );
  }
}
