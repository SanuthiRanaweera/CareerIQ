class UniversityProfileModel {
  const UniversityProfileModel({
    required this.id,
    required this.userId,
    required this.universityName,
    required this.officialEmail,
    required this.location,
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
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String universityName;
  final String officialEmail;
  final String location;
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status.toLowerCase() == 'active';
  bool get isInactive => status.toLowerCase() == 'inactive';
  bool get isPending =>
      status.toLowerCase() == 'pending' ||
      status.toLowerCase() == 'pending_verification';

  factory UniversityProfileModel.fromJson(Map<String, dynamic> json) {
    return UniversityProfileModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: (json['userId'] is Map
              ? (json['userId']['_id'] ?? json['userId']['id'])
              : json['userId'] ?? '')
          .toString(),
      universityName: (json['universityName'] ?? json['name'] ?? '').toString().trim(),
      officialEmail: (json['officialEmail'] ?? json['email'] ?? '').toString().trim(),
      location: (json['location'] ?? '').toString().trim(),
      address: (json['address'] ?? '').toString().trim(),
      contactNumber: (json['contactNumber'] ?? '').toString().trim(),
      representativeName: (json['representativeName'] ?? '').toString().trim(),
      representativeEmail: json['representativeEmail']?.toString().trim(),
      representativeContactNumber:
          (json['representativeContactNumber'] ?? '').toString().trim(),
      universityType: json['universityType']?.toString().trim() ?? 'State University',
      website: json['website']?.toString().trim(),
      description: json['description']?.toString().trim(),
      logo: json['logo']?.toString().trim(),
      status: (json['status'] ?? 'active').toString().trim(),
      isEmailVerified: json['isEmailVerified'] == true || json['emailVerified'] == true,
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
        'officialEmail': officialEmail,
        'location': location,
        'address': address,
        'contactNumber': contactNumber,
        'representativeName': representativeName,
        'representativeEmail': representativeEmail,
        'representativeContactNumber': representativeContactNumber,
        'universityType': universityType,
        'website': website,
        'description': description,
        'logo': logo,
        'status': status,
        'isEmailVerified': isEmailVerified,
      };

  UniversityProfileModel copyWith({
    String? universityName,
    String? location,
    String? address,
    String? contactNumber,
    String? representativeName,
    String? representativeEmail,
    String? representativeContactNumber,
    String? universityType,
    String? website,
    String? description,
    String? logo,
  }) {
    return UniversityProfileModel(
      id: id,
      userId: userId,
      universityName: universityName ?? this.universityName,
      officialEmail: officialEmail,
      location: location ?? this.location,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      representativeName: representativeName ?? this.representativeName,
      representativeEmail: representativeEmail ?? this.representativeEmail,
      representativeContactNumber:
          representativeContactNumber ?? this.representativeContactNumber,
      universityType: universityType ?? this.universityType,
      website: website ?? this.website,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      status: status,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class UniversityStatisticsModel {
  const UniversityStatisticsModel({
    required this.profileCompletion,
    required this.courseCount,
    this.completedFields = 0,
    this.totalFields = 11,
    this.status = 'active',
  });

  final int profileCompletion;
  final int courseCount;
  final int completedFields;
  final int totalFields;
  final String status;

  factory UniversityStatisticsModel.fromJson(Map<String, dynamic> json) {
    return UniversityStatisticsModel(
      profileCompletion: (json['profileCompletion'] as num?)?.toInt() ?? 0,
      courseCount: (json['courseCount'] as num?)?.toInt() ?? 0,
      completedFields: (json['completedFields'] as num?)?.toInt() ?? 0,
      totalFields: (json['totalFields'] as num?)?.toInt() ?? 11,
      status: (json['status'] ?? 'active').toString(),
    );
  }
}

class UniversityNotificationModel {
  const UniversityNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.timestamp,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime? timestamp;

  factory UniversityNotificationModel.fromJson(Map<String, dynamic> json) {
    return UniversityNotificationModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      type: (json['type'] ?? 'info').toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
    );
  }
}

class UniversityActivityModel {
  const UniversityActivityModel({
    required this.id,
    required this.title,
    required this.description,
    this.timestamp,
  });

  final String id;
  final String title;
  final String description;
  final DateTime? timestamp;

  factory UniversityActivityModel.fromJson(Map<String, dynamic> json) {
    return UniversityActivityModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
    );
  }
}

class UniversityCourseItem {
  const UniversityCourseItem({
    required this.id,
    required this.title,
    required this.university,
    required this.stream,
    required this.degreeType,
    required this.description,
    required this.durationYears,
    this.minZScore,
    this.website,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String university;
  final String stream;
  final String degreeType;
  final String description;
  final double durationYears;
  final double? minZScore;
  final String? website;
  final bool isActive;

  factory UniversityCourseItem.fromJson(Map<String, dynamic> json) {
    return UniversityCourseItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      university: (json['university'] ?? '').toString(),
      stream: (json['stream'] ?? 'Any').toString(),
      degreeType: (json['degreeType'] ?? "Bachelor's Degree").toString(),
      description: (json['description'] ?? '').toString(),
      durationYears: (json['durationYears'] as num?)?.toDouble() ?? 4.0,
      minZScore: (json['minZScore'] as num?)?.toDouble(),
      website: json['website']?.toString(),
      isActive: json['isActive'] != false,
    );
  }
}

class UniversityDashboardData {
  const UniversityDashboardData({
    required this.university,
    required this.statistics,
    this.notifications = const [],
    this.recentActivity = const [],
  });

  final UniversityProfileModel university;
  final UniversityStatisticsModel statistics;
  final List<UniversityNotificationModel> notifications;
  final List<UniversityActivityModel> recentActivity;

  factory UniversityDashboardData.fromJson(Map<String, dynamic> json) {
    final rawUni = json['university'] as Map<String, dynamic>? ?? {};
    final rawStats = json['statistics'] as Map<String, dynamic>? ?? {};
    final rawNotifs = json['notifications'] as List? ?? [];
    final rawActs = json['recentActivity'] as List? ?? [];

    return UniversityDashboardData(
      university: UniversityProfileModel.fromJson(rawUni),
      statistics: UniversityStatisticsModel.fromJson(rawStats),
      notifications: rawNotifs
          .map((n) => UniversityNotificationModel.fromJson(n as Map<String, dynamic>))
          .toList(),
      recentActivity: rawActs
          .map((a) => UniversityActivityModel.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

