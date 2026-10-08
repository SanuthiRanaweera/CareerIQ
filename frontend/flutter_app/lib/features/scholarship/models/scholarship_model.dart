import '../../../models/student.dart';

class RequiredSubjectModel {
  const RequiredSubjectModel({
    required this.subject,
    required this.grade,
  });

  final String subject;
  final String grade;

  factory RequiredSubjectModel.fromJson(Map<String, dynamic> json) =>
      RequiredSubjectModel(
        subject: (json['subject'] ?? '').toString().trim(),
        grade: (json['grade'] ?? '').toString().trim(),
      );

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'grade': grade,
      };
}

class ScholarshipEligibilityModel {
  const ScholarshipEligibilityModel({
    this.stream = 'Any',
    this.minimumResults = const [],
    this.academicRequirement = '',
    this.ageRequirement = '',
    this.districtRequirement = '',
    this.otherRequirements = '',
  });

  final String stream;
  final List<RequiredSubjectModel> minimumResults;
  final String academicRequirement;
  final String ageRequirement;
  final String districtRequirement;
  final String otherRequirements;

  String? get district => districtRequirement.isNotEmpty ? districtRequirement : null;
  String? get other => otherRequirements.isNotEmpty ? otherRequirements : null;

  factory ScholarshipEligibilityModel.fromJson(Map<String, dynamic> json) {
    final rawResults = json['minimumResults'] as List? ?? const [];
    return ScholarshipEligibilityModel(
      stream: (json['stream'] ?? 'Any').toString().trim(),
      minimumResults: rawResults
          .map((r) => RequiredSubjectModel.fromJson(r as Map<String, dynamic>))
          .toList(),
      academicRequirement:
          (json['academicRequirement'] ?? '').toString().trim(),
      ageRequirement: (json['ageRequirement'] ?? '').toString().trim(),
      districtRequirement:
          (json['districtRequirement'] ?? '').toString().trim(),
      otherRequirements: (json['otherRequirements'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'stream': stream,
        'minimumResults': minimumResults.map((r) => r.toJson()).toList(),
        if (academicRequirement.isNotEmpty)
          'academicRequirement': academicRequirement,
        if (ageRequirement.isNotEmpty) 'ageRequirement': ageRequirement,
        if (districtRequirement.isNotEmpty)
          'districtRequirement': districtRequirement,
        if (otherRequirements.isNotEmpty)
          'otherRequirements': otherRequirements,
      };
}

class EligibilityCheckResult {
  const EligibilityCheckResult({
    required this.isEligible,
    required this.matchedCriteria,
    required this.unmetCriteria,
    required this.guidanceMessage,
  });

  final bool isEligible;
  final List<String> matchedCriteria;
  final List<String> unmetCriteria;
  final String guidanceMessage;
}

class ScholarshipModel {
  const ScholarshipModel({
    required this.id,
    required this.universityId,
    required this.universityName,
    required this.title,
    required this.description,
    required this.scholarshipType,
    required this.amount,
    required this.coverage,
    required this.numberOfScholarships,
    required this.applicationDeadline,
    this.startDate,
    this.endDate,
    this.eligibility = const ScholarshipEligibilityModel(),
    this.applicationInstructions = '',
    this.requiredDocuments = const [],
    this.status = 'active',
    this.applicationsCount = 0,
    this.hasApplied = false,
    this.applicationId,
    this.applicationStatus,
    this.isDeadlinePassed = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String universityId;
  final String universityName;
  final String title;
  final String description;
  final String scholarshipType;
  final String amount;
  final List<String> coverage;
  final int numberOfScholarships;
  final DateTime applicationDeadline;
  final DateTime? startDate;
  final DateTime? endDate;
  final ScholarshipEligibilityModel eligibility;
  final String applicationInstructions;
  final List<String> requiredDocuments;
  final String status;
  final int applicationsCount;
  final bool hasApplied;
  final String? applicationId;
  final String? applicationStatus;
  final bool isDeadlinePassed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isExpired =>
      status.toLowerCase() == 'expired' ||
      DateTime.now().isAfter(applicationDeadline);

  bool get isActive =>
      status.toLowerCase() == 'active' && !isExpired;

  bool get isClosed => status.toLowerCase() == 'closed';
  bool get isDraft => status.toLowerCase() == 'draft';

  bool get canApply => isActive && !hasApplied;

  String get initials {
    final clean = universityName.replaceAll(RegExp(r'[^a-zA-Z\s]'), '');
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'U';
    if (words.length == 1) {
      return words[0].substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    if (words.length >= 3 && words[1].toLowerCase() == 'of') {
      return '${words[0][0]}${words[2][0]}'.toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  // Compare student profile with scholarship eligibility criteria
  EligibilityCheckResult checkEligibility(Student? student) {
    if (student == null) {
      return const EligibilityCheckResult(
        isEligible: false,
        matchedCriteria: [],
        unmetCriteria: ['Student profile not available'],
        guidanceMessage: 'Please log in and complete your profile to verify eligibility.',
      );
    }

    final matched = <String>[];
    final unmet = <String>[];

    // 1. Stream Check
    final requiredStream = eligibility.stream.trim();
    if (requiredStream == 'Any') {
      matched.add('Open to all A/L streams');
    } else if (student.stream != null &&
        student.stream!.trim().toLowerCase() == requiredStream.toLowerCase()) {
      matched.add('Matches required stream ($requiredStream)');
    } else {
      unmet.add(
        'Requires $requiredStream stream (You are in ${student.stream ?? "Not specified"})',
      );
    }

    // 2. Minimum Subject Results Check
    // Grade points: A=4, B=3, C=2, S=1, F=0
    int gradePoints(String g) {
      final clean = g.toUpperCase().trim();
      if (clean.startsWith('A')) return 4;
      if (clean.startsWith('B')) return 3;
      if (clean.startsWith('C')) return 2;
      if (clean.startsWith('S')) return 1;
      return 0;
    }

    if (eligibility.minimumResults.isNotEmpty) {
      for (final reqSub in eligibility.minimumResults) {
        final reqName = reqSub.subject.toLowerCase();
        final reqGrade = reqSub.grade.toUpperCase();
        final reqVal = gradePoints(reqGrade);

        final studentSub = student.alResults.firstWhere(
          (s) => s.name.toLowerCase().contains(reqName) || reqName.contains(s.name.toLowerCase()),
          orElse: () => SubjectResult(id: null, name: '', grade: ''),
        );

        if (studentSub.name.isEmpty) {
          unmet.add('Requires ${reqSub.subject} ($reqGrade) - Not in your results');
        } else {
          final studentVal = gradePoints(studentSub.grade);
          if (studentVal >= reqVal) {
            matched.add('${reqSub.subject}: You scored ${studentSub.grade} (Meets required $reqGrade)');
          } else {
            unmet.add('${reqSub.subject}: Requires $reqGrade, you scored ${studentSub.grade}');
          }
        }
      }
    } else {
      matched.add('No specific subject grade requirements');
    }

    // 3. District Check (if specified)
    if (eligibility.districtRequirement.trim().isNotEmpty) {
      final reqDistrict = eligibility.districtRequirement.trim().toLowerCase();
      if (student.district.trim().toLowerCase() == reqDistrict) {
        matched.add('Location: Matches district ($reqDistrict)');
      } else {
        unmet.add('Location: Requires $reqDistrict district');
      }
    }

    final isEligible = unmet.isEmpty;
    final message = isEligible
        ? 'You appear to meet the academic eligibility requirements.'
        : 'You may not meet all the academic eligibility requirements.';

    return EligibilityCheckResult(
      isEligible: isEligible,
      matchedCriteria: matched,
      unmetCriteria: unmet,
      guidanceMessage: message,
    );
  }

  factory ScholarshipModel.fromJson(Map<String, dynamic> json) {
    final deadlineStr = json['applicationDeadline']?.toString();
    DateTime deadline = DateTime.now();
    if (deadlineStr != null) {
      deadline = DateTime.tryParse(deadlineStr) ?? DateTime.now();
    }

    final covRaw = json['coverage'] as List? ?? const [];
    final docsRaw = json['requiredDocuments'] as List? ?? const [];

    return ScholarshipModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      universityId: (json['universityId'] is Map
              ? json['universityId']['_id'] ?? json['universityId']['id']
              : json['universityId'] ?? '')
          .toString(),
      universityName: (json['universityName'] ??
              (json['universityId'] is Map
                  ? json['universityId']['universityName']
                  : ''))
          .toString()
          .trim(),
      title: (json['title'] ?? '').toString().trim(),
      description: (json['description'] ?? '').toString().trim(),
      scholarshipType: (json['scholarshipType'] ?? 'Merit').toString().trim(),
      amount: (json['amount'] ?? '').toString().trim(),
      coverage: covRaw.map((c) => c.toString().trim()).where((c) => c.isNotEmpty).toList(),
      numberOfScholarships: (json['numberOfScholarships'] as num?)?.toInt() ?? 1,
      applicationDeadline: deadline,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      eligibility: json['eligibility'] is Map<String, dynamic>
          ? ScholarshipEligibilityModel.fromJson(
              json['eligibility'] as Map<String, dynamic>)
          : const ScholarshipEligibilityModel(),
      applicationInstructions:
          (json['applicationInstructions'] ?? '').toString().trim(),
      requiredDocuments:
          docsRaw.map((d) => d.toString().trim()).where((d) => d.isNotEmpty).toList(),
      status: (json['status'] ?? 'active').toString().trim(),
      applicationsCount: (json['applicationsCount'] as num?)?.toInt() ?? 0,
      hasApplied: json['hasApplied'] as bool? ?? false,
      applicationId: json['applicationId']?.toString(),
      applicationStatus: json['applicationStatus']?.toString(),
      isDeadlinePassed: json['isDeadlinePassed'] as bool? ??
          DateTime.now().isAfter(deadline),
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
        'universityId': universityId,
        'universityName': universityName,
        'title': title,
        'description': description,
        'scholarshipType': scholarshipType,
        'amount': amount,
        'coverage': coverage,
        'numberOfScholarships': numberOfScholarships,
        'applicationDeadline': applicationDeadline.toIso8601String(),
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
        'eligibility': eligibility.toJson(),
        if (applicationInstructions.isNotEmpty)
          'applicationInstructions': applicationInstructions,
        'requiredDocuments': requiredDocuments,
        'status': status,
      };
}
