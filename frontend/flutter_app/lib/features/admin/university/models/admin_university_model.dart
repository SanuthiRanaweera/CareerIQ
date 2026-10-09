class AdminUniversityModel {
  const AdminUniversityModel({
    required this.id,
    required this.userId,
    required this.universityName,
    required this.location,
    required this.officialEmail,
    required this.address,
    required this.contactNumber,
    required this.representativeName,
    this.representativeEmail,
    required this.representativeContactNumber,
    this.universityType,
    this.website,
    this.description,
    this.logo,
    required this.status,
    this.isEmailVerified = false,
    this.courseCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String universityName;
  final String location;
  final String officialEmail;
  final String address;
  final String contactNumber;
  final String representativeName;
  final String? representativeEmail;
  final String representativeContactNumber;
  final String? universityType;
  final String? website;
  final String? description;
  final String? logo;
  final String status;
  final bool isEmailVerified;
  final int courseCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status.toLowerCase() == 'active';
  bool get isInactive => status.toLowerCase() == 'inactive';
  bool get isPending =>
      status.toLowerCase() == 'pending' ||
      status.toLowerCase() == 'pending_verification';
  bool get isPendingVerification => isPending;

  factory AdminUniversityModel.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    bool emailVerified = false;
    String uId = '';

    if (user is Map<String, dynamic>) {
      uId = (user['_id'] ?? user['id'] ?? '').toString();
      emailVerified =
          (user['isEmailVerified'] ?? user['emailVerified'] ?? false) as bool;
    } else if (user != null) {
      uId = user.toString();
    }

    return AdminUniversityModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: uId,
      universityName: (json['universityName'] ?? '').toString().trim(),
      location: (json['location'] ?? '').toString().trim(),
      officialEmail: (json['officialEmail'] ?? '').toString().trim(),
      address: (json['address'] ?? '').toString().trim(),
      contactNumber: (json['contactNumber'] ?? '').toString().trim(),
      representativeName: (json['representativeName'] ?? '').toString().trim(),
      representativeEmail: json['representativeEmail']?.toString().trim(),
      representativeContactNumber: (json['representativeContactNumber'] ?? '')
          .toString()
          .trim(),
      universityType: json['universityType']?.toString().trim(),
      website: json['website']?.toString().trim(),
      description: json['description']?.toString().trim(),
      logo: json['logo']?.toString().trim(),
      status: (json['status'] ?? 'pending').toString().trim(),
      isEmailVerified: emailVerified,
      courseCount: (json['courseCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'universityName': universityName,
    'location': location,
    'officialEmail': officialEmail,
    'address': address,
    'contactNumber': contactNumber,
    'representativeName': representativeName,
    if (representativeEmail != null) 'representativeEmail': representativeEmail,
    'representativeContactNumber': representativeContactNumber,
    if (universityType != null) 'universityType': universityType,
    if (website != null) 'website': website,
    if (description != null) 'description': description,
    if (logo != null) 'logo': logo,
    'status': status,
    'isEmailVerified': isEmailVerified,
  };
}

class AdminUniversityStats {
  const AdminUniversityStats({
    this.totalUniversities = 0,
    this.activeUniversities = 0,
    this.inactiveUniversities = 0,
    this.pendingVerification = 0,
  });

  final int totalUniversities;
  final int activeUniversities;
  final int inactiveUniversities;
  final int pendingVerification;

  factory AdminUniversityStats.fromJson(Map<String, dynamic> json) =>
      AdminUniversityStats(
        totalUniversities: json['totalUniversities'] as int? ?? 0,
        activeUniversities: json['activeUniversities'] as int? ?? 0,
        inactiveUniversities: json['inactiveUniversities'] as int? ?? 0,
        pendingVerification: json['pendingVerification'] as int? ?? 0,
      );
}
