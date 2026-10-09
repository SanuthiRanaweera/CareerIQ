import '../../../models/student.dart';

class ApplicationDocumentModel {
  const ApplicationDocumentModel({
    required this.name,
    this.fileName = '',
    this.fileUrl = '',
    this.uploadedAt,
  });

  final String name;
  final String fileName;
  final String fileUrl;
  final DateTime? uploadedAt;

  factory ApplicationDocumentModel.fromJson(Map<String, dynamic> json) =>
      ApplicationDocumentModel(
        name: (json['name'] ?? '').toString().trim(),
        fileName: (json['fileName'] ?? '').toString().trim(),
        fileUrl: (json['fileUrl'] ?? '').toString().trim(),
        uploadedAt: json['uploadedAt'] != null
            ? DateTime.tryParse(json['uploadedAt'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'fileName': fileName,
    'fileUrl': fileUrl,
  };
}

class ScholarshipApplicationModel {
  const ScholarshipApplicationModel({
    required this.id,
    required this.scholarshipId,
    this.scholarshipTitle = '',
    this.scholarshipType = '',
    this.scholarshipAmount = '',
    required this.universityId,
    this.universityName = '',
    this.universityLogo,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    this.studentSchool = '',
    this.studentDistrict = '',
    this.studentStream = '',
    this.studentPhone,
    this.zScore,
    this.studentAlResults = const [],
    required this.personalStatement,
    this.careerGoal = '',
    this.additionalInfo = '',
    this.documents = const [],
    this.status = 'pending',
    this.reviewNotes = '',
    required this.submittedAt,
  });

  final String id;
  final String scholarshipId;
  final String scholarshipTitle;
  final String scholarshipType;
  final String scholarshipAmount;
  final String universityId;
  final String universityName;
  final String? universityLogo;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String studentSchool;
  final String studentDistrict;
  final String studentStream;
  final String? studentPhone;
  final double? zScore;
  final List<SubjectResult> studentAlResults;
  final String personalStatement;
  final String careerGoal;
  final String additionalInfo;
  final List<ApplicationDocumentModel> documents;
  final String status;
  final String reviewNotes;
  final DateTime submittedAt;

  String get stream => studentStream;
  String get district => studentDistrict;
  String get school => studentSchool;
  List<SubjectResult> get alResults => studentAlResults;
  DateTime get createdAt => submittedAt;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isUnderReview =>
      status.toLowerCase() == 'under_review' ||
      status.toLowerCase() == 'under review';
  bool get isShortlisted => status.toLowerCase() == 'shortlisted';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  String get formattedStatus {
    switch (status.toLowerCase()) {
      case 'under_review':
      case 'under review':
        return 'Under Review';
      case 'shortlisted':
        return 'Shortlisted';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  factory ScholarshipApplicationModel.fromJson(Map<String, dynamic> json) {
    final sch = json['scholarshipId'];
    String schId = '';
    String schTitle = '';
    String schType = '';
    String schAmount = '';

    if (sch is Map<String, dynamic>) {
      schId = (sch['_id'] ?? sch['id'] ?? '').toString();
      schTitle = (sch['title'] ?? '').toString().trim();
      schType = (sch['scholarshipType'] ?? '').toString().trim();
      schAmount = (sch['amount'] ?? '').toString().trim();
    } else if (sch != null) {
      schId = sch.toString();
    }

    final uni = json['universityId'];
    String uId = '';
    String uName = '';
    String? uLogo;

    if (uni is Map<String, dynamic>) {
      uId = (uni['_id'] ?? uni['id'] ?? '').toString();
      uName = (uni['universityName'] ?? '').toString().trim();
      uLogo = uni['logo']?.toString();
    } else if (uni != null) {
      uId = uni.toString();
    }

    final rawResults = (json['studentAlResults'] as List? ?? const []);
    final alResults = rawResults
        .map((r) => SubjectResult.fromJson(r as Map<String, dynamic>))
        .toList();

    final rawDocs = (json['documents'] as List? ?? const []);
    final docs = rawDocs
        .map(
          (d) => ApplicationDocumentModel.fromJson(d as Map<String, dynamic>),
        )
        .toList();

    return ScholarshipApplicationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      scholarshipId: schId,
      scholarshipTitle: schTitle,
      scholarshipType: schType,
      scholarshipAmount: schAmount,
      universityId: uId,
      universityName: uName,
      universityLogo: uLogo,
      studentId:
          (json['studentId'] is Map
                  ? json['studentId']['_id'] ?? json['studentId']['id']
                  : json['studentId'] ?? '')
              .toString(),
      studentName: (json['studentName'] ?? '').toString().trim(),
      studentEmail: (json['studentEmail'] ?? '').toString().trim(),
      studentSchool: (json['studentSchool'] ?? '').toString().trim(),
      studentDistrict: (json['studentDistrict'] ?? '').toString().trim(),
      studentStream: (json['studentStream'] ?? '').toString().trim(),
      studentPhone: json['studentPhone']?.toString().trim(),
      zScore:
          (json['zScore'] as num?)?.toDouble() ??
          (json['studentZScore'] as num?)?.toDouble(),
      studentAlResults: alResults,
      personalStatement: (json['personalStatement'] ?? '').toString().trim(),
      careerGoal: (json['careerGoal'] ?? '').toString().trim(),
      additionalInfo: (json['additionalInfo'] ?? '').toString().trim(),
      documents: docs,
      status: (json['status'] ?? 'pending').toString().trim(),
      reviewNotes: (json['reviewNotes'] ?? '').toString().trim(),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
