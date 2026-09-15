class SubjectResult {
  SubjectResult({required this.id, required this.name, required this.grade});

  factory SubjectResult.fromJson(Map<String, dynamic> json) => SubjectResult(
        id: json['_id'] as String?,
        name: json['name'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
      );

  String? id;
  String name;
  String grade;

  Map<String, dynamic> toJson() => {'name': name, 'grade': grade};
}

class Student {
  Student({
    required this.id,
    required this.fullName,
    required this.email,
    this.school = '',
    this.district = '',
    this.alYear,
    this.stream,
    this.dateOfBirth,
    this.alResults = const [],
    this.profileCompletion = 0,
    this.personalityCategory,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    final personality = json['personalityResult'] as Map<String, dynamic>?;
    return Student(
      id: json['_id'] as String,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      school: json['school'] as String? ?? '',
      district: json['district'] as String? ?? '',
      alYear: (json['alYear'] as num?)?.toInt(),
      stream: json['stream'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      alResults: ((json['alResults'] as List?) ?? const [])
          .map((item) => SubjectResult.fromJson(item as Map<String, dynamic>))
          .toList(),
      profileCompletion: (json['profileCompletion'] as num?)?.toInt() ?? 0,
      personalityCategory: personality?['category'] as String?,
    );
  }

  final String id;
  String fullName;
  final String email;
  String school;
  String district;
  int? alYear;
  String? stream;
  String? dateOfBirth;
  List<SubjectResult> alResults;
  int profileCompletion;
  String? personalityCategory;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'school': school,
        'district': district,
        'alYear': alYear,
        'stream': stream,
        'dateOfBirth': dateOfBirth,
        'alResults': alResults.map((result) => result.toJson()).toList(),
      };
}
