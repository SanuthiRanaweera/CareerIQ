import '../../../../models/course.dart';

class UniversityCourseInfo {
  const UniversityCourseInfo({
    required this.id,
    required this.title,
    required this.stream,
    required this.degreeType,
    required this.durationYears,
    this.minZScore,
    this.subjects = const [],
    this.careerPaths = const [],
    this.website = '',
    this.applicationUrl = '',
  });

  final String id;
  final String title;
  final String stream;
  final String degreeType;
  final double durationYears;
  final double? minZScore;
  final List<String> subjects;
  final List<String> careerPaths;
  final String website;
  final String applicationUrl;

  Course toCourse({required String universityName, String? universityId}) {
    return Course(
      id: id,
      title: title,
      university: universityName,
      universityId: universityId,
      stream: stream,
      degreeType: degreeType,
      description: '',
      durationYears: durationYears,
      minZScore: minZScore,
      subjects: subjects,
      careerPaths: careerPaths,
      website: website,
      applicationUrl: applicationUrl,
    );
  }

  factory UniversityCourseInfo.fromJson(Map<String, dynamic> json) =>
      UniversityCourseInfo(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString().trim(),
        stream: (json['stream'] ?? 'Any').toString().trim(),
        degreeType:
            (json['degreeType'] ?? "Bachelor's Degree").toString().trim(),
        durationYears: (json['durationYears'] as num?)?.toDouble() ?? 0.0,
        minZScore: (json['minZScore'] as num?)?.toDouble(),
        subjects: (json['subjects'] as List? ?? const [])
            .map((s) => s.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        careerPaths: (json['careerPaths'] as List? ?? const [])
            .map((s) => s.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        website: (json['website'] ?? '').toString().trim(),
        applicationUrl: (json['applicationUrl'] ?? '').toString().trim(),
      );
}

class UniversityComparisonModel {
  const UniversityComparisonModel({
    required this.id,
    required this.universityName,
    required this.location,
    this.district = '',
    this.city = '',
    this.country = 'Sri Lanka',
    this.universityType = 'State University',
    this.establishedYear,
    this.website,
    this.officialEmail = '',
    this.contactNumber = '',
    this.address = '',
    this.description = '',
    this.logo,
    this.tuitionFee,
    this.status = 'active',
    this.courseCount = 0,
    this.courses = const [],
    this.degreeTitles = const [],
    this.streams = const [],
    this.degreeTypes = const [],
    this.durations = const [],
    this.minZScore,
    this.subjects = const [],
  });

  final String id;
  final String universityName;
  final String location;
  final String district;
  final String city;
  final String country;
  final String universityType;
  final int? establishedYear;
  final String? website;
  final String officialEmail;
  final String contactNumber;
  final String address;
  final String description;
  final String? logo;
  final String? tuitionFee;
  final String status;
  final int courseCount;
  final List<UniversityCourseInfo> courses;
  final List<String> degreeTitles;
  final List<String> streams;
  final List<String> degreeTypes;
  final List<double> durations;
  final double? minZScore;
  final List<String> subjects;

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

  String get durationDisplay {
    if (durations.isEmpty) return 'Not available';
    final intDurations = durations.map((d) => d.toInt()).toSet().toList()..sort();
    if (intDurations.length == 1) return '${intDurations.first} Years';
    return '${intDurations.first} - ${intDurations.last} Years';
  }

  String get feeDisplay {
    if (tuitionFee != null && tuitionFee!.trim().isNotEmpty) {
      return tuitionFee!.trim();
    }
    return 'Not available';
  }

  String get zScoreDisplay {
    if (minZScore != null) {
      return minZScore!.toStringAsFixed(2);
    }
    return 'Not specified';
  }

  bool matchesStream(String? studentStream) {
    if (studentStream == null || studentStream.trim().isEmpty) return false;
    final lower = studentStream.trim().toLowerCase();
    return streams.any((s) => s.toLowerCase() == lower || s.toLowerCase() == 'any') ||
        courses.any((c) => c.stream.toLowerCase() == lower || c.stream.toLowerCase() == 'any');
  }

  factory UniversityComparisonModel.fromJson(Map<String, dynamic> json) {
    final rawCourses = json['courses'] as List? ?? const [];
    final courses = rawCourses
        .map((c) => UniversityCourseInfo.fromJson(c as Map<String, dynamic>))
        .toList();

    final rawDegreeTitles = (json['degreeTitles'] as List? ?? const [])
        .map((t) => t.toString().trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final rawStreams = (json['streams'] as List? ?? const [])
        .map((s) => s.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final rawDegreeTypes = (json['degreeTypes'] as List? ?? const [])
        .map((d) => d.toString().trim())
        .where((d) => d.isNotEmpty)
        .toList();

    final rawDurations = (json['durations'] as List? ?? const [])
        .map((d) => (d as num?)?.toDouble())
        .whereType<double>()
        .toList();

    final rawSubjects = (json['subjects'] as List? ?? const [])
        .map((s) => s.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return UniversityComparisonModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      universityName: (json['universityName'] ?? '').toString().trim(),
      location: (json['location'] ?? '').toString().trim(),
      district: (json['district'] ?? '').toString().trim(),
      city: (json['city'] ?? '').toString().trim(),
      country: (json['country'] ?? 'Sri Lanka').toString().trim(),
      universityType:
          (json['universityType'] ?? 'State University').toString().trim(),
      establishedYear: (json['establishedYear'] as num?)?.toInt(),
      website: json['website']?.toString().trim(),
      officialEmail: (json['officialEmail'] ?? '').toString().trim(),
      contactNumber: (json['contactNumber'] ?? '').toString().trim(),
      address: (json['address'] ?? '').toString().trim(),
      description: (json['description'] ?? '').toString().trim(),
      logo: json['logo']?.toString().trim(),
      tuitionFee: json['tuitionFee']?.toString().trim(),
      status: (json['status'] ?? 'active').toString().trim(),
      courseCount: (json['courseCount'] as num?)?.toInt() ?? courses.length,
      courses: courses,
      degreeTitles: rawDegreeTitles.isNotEmpty
          ? rawDegreeTitles
          : courses.map((c) => c.title).toList(),
      streams: rawStreams.isNotEmpty
          ? rawStreams
          : courses.map((c) => c.stream).toSet().toList(),
      degreeTypes: rawDegreeTypes.isNotEmpty
          ? rawDegreeTypes
          : courses.map((c) => c.degreeType).toSet().toList(),
      durations: rawDurations.isNotEmpty
          ? rawDurations
          : courses.map((c) => c.durationYears).toSet().toList(),
      minZScore: (json['minZScore'] as num?)?.toDouble() ??
          (courses.any((c) => c.minZScore != null)
              ? courses
                  .map((c) => c.minZScore)
                  .whereType<double>()
                  .fold<double?>(
                      null, (min, val) => min == null || val < min ? val : min)
              : null),
      subjects: rawSubjects.isNotEmpty
          ? rawSubjects
          : courses.expand((c) => c.subjects).toSet().toList(),
    );
  }
}

