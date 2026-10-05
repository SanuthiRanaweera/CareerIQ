class Course {
  const Course({
    required this.id,
    required this.title,
    required this.university,
    required this.stream,
    required this.degreeType,
    required this.description,
    required this.durationYears,
    required this.minZScore,
    required this.subjects,
    required this.careerPaths,
    required this.website,
    required this.applicationUrl,
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['_id'] as String? ?? json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    university: json['university'] as String? ?? '',
    stream: json['stream'] as String? ?? 'Any',
    degreeType: json['degreeType'] as String? ?? "Bachelor's Degree",
    description: json['description'] as String? ?? '',
    durationYears: (json['durationYears'] as num?)?.toDouble() ?? 0,
    minZScore: (json['minZScore'] as num?)?.toDouble(),
    subjects: _stringList(json['subjects']),
    careerPaths: _stringList(json['careerPaths']),
    website: json['website'] as String? ?? '',
    applicationUrl: json['applicationUrl'] as String? ?? '',
  );

  final String id;
  final String title;
  final String university;
  final String stream;
  final String degreeType;
  final String description;
  final double durationYears;
  final double? minZScore;
  final List<String> subjects;
  final List<String> careerPaths;
  final String website;
  final String applicationUrl;

  static List<String> _stringList(Object? value) =>
      (value as List? ?? const []).whereType<String>().toList();
}