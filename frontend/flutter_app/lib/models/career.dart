// Models for the Career module.
//
// Every `fromJson` is written defensively with `??` fallbacks, because a career
// created through the admin form may legitimately leave the optional lists
// empty, and a missing field should render an empty section rather than crash
// the screen.

/// Monthly salary band for a career, in Sri Lankan Rupees.
class SalaryRange {
  const SalaryRange({
    required this.min,
    required this.max,
    this.currency = 'LKR',
    this.period = 'month',
  });

  factory SalaryRange.fromJson(Map<String, dynamic> json) => SalaryRange(
        min: (json['min'] as num?)?.toInt() ?? 0,
        max: (json['max'] as num?)?.toInt() ?? 0,
        currency: json['currency'] as String? ?? 'LKR',
        period: json['period'] as String? ?? 'month',
      );

  final int min;
  final int max;
  final String currency;
  final String period;

  Map<String, dynamic> toJson() => {
        'min': min,
        'max': max,
        'currency': currency,
        'period': period,
      };
}

/// One ordered step on the pathway to a career, for example
/// A/L Stream -> Degree -> Skills -> Internship -> Entry Job -> Senior Role.
class CareerPathwayStep {
  const CareerPathwayStep({
    required this.order,
    required this.stage,
    required this.title,
    this.description = '',
    this.durationLabel = '',
  });

  factory CareerPathwayStep.fromJson(Map<String, dynamic> json) =>
      CareerPathwayStep(
        order: (json['order'] as num?)?.toInt() ?? 0,
        stage: json['stage'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        durationLabel: json['durationLabel'] as String? ?? '',
      );

  final int order;
  final String stage;
  final String title;
  final String description;
  final String durationLabel;

  Map<String, dynamic> toJson() => {
        'order': order,
        'stage': stage,
        'title': title,
        'description': description,
        'durationLabel': durationLabel,
      };
}

/// A career, matching the Career model on the backend.
class Career {
  const Career({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.salaryRange,
    required this.jobOutlook,
    this.whatYouDo = const [],
    this.requiredSkills = const [],
    this.recommendedStreams = const [],
    this.industryOpportunities = const [],
    this.pathway = const [],
    this.interestTags = const [],
    this.alSubjects = const [],
    this.personalityTypes = const [],
    this.workStyles = const [],
    this.relatedCourseKeywords = const [],
    this.salaryDisplay = '',
  });

  factory Career.fromJson(Map<String, dynamic> json) => Career(
        id: json['_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? '',
        description: json['description'] as String? ?? '',
        salaryRange: SalaryRange.fromJson(
          (json['salaryRange'] as Map<String, dynamic>?) ?? const {},
        ),
        jobOutlook: json['jobOutlook'] as String? ?? '',
        whatYouDo: _stringList(json['whatYouDo']),
        requiredSkills: _stringList(json['requiredSkills']),
        recommendedStreams: _stringList(json['recommendedStreams']),
        industryOpportunities: _stringList(json['industryOpportunities']),
        pathway: ((json['pathway'] as List?) ?? const [])
            .map((step) => CareerPathwayStep.fromJson(step as Map<String, dynamic>))
            .toList(),
        interestTags: _stringList(json['interestTags']),
        alSubjects: _stringList(json['alSubjects']),
        personalityTypes: _stringList(json['personalityTypes']),
        workStyles: _stringList(json['workStyles']),
        relatedCourseKeywords: _stringList(json['relatedCourseKeywords']),
        salaryDisplay: json['salaryDisplay'] as String? ?? '',
      );

  final String id;
  final String title;
  final String category;
  final String description;
  final SalaryRange salaryRange;
  final String jobOutlook;
  final List<String> whatYouDo;
  final List<String> requiredSkills;
  final List<String> recommendedStreams;
  final List<String> industryOpportunities;
  final List<CareerPathwayStep> pathway;

  // Tags the recommendation scoring runs against.
  final List<String> interestTags;
  final List<String> alSubjects;
  final List<String> personalityTypes;
  final List<String> workStyles;

  /// Reference only. Course data belongs to the Course module, so the career
  /// details screen shows a placeholder until that module can resolve these
  /// keywords into real courses.
  final List<String> relatedCourseKeywords;

  /// Pre-formatted salary label from the backend, e.g.
  /// "LKR 150,000 - 500,000 / month". Falls back to a locally built label if
  /// the backend virtual is not present in the response.
  final String salaryDisplay;

  /// Salary text that is always safe to display.
  String get salaryLabel =>
      salaryDisplay.isNotEmpty ? salaryDisplay : _buildSalaryLabel();

  String _buildSalaryLabel() {
    if (salaryRange.min == 0 && salaryRange.max == 0) return 'Not specified';
    return '${salaryRange.currency} ${_thousands(salaryRange.min)} - '
        '${_thousands(salaryRange.max)} / ${salaryRange.period}';
  }

  /// Pathway steps in the order a student would follow them.
  List<CareerPathwayStep> get orderedPathway {
    final steps = [...pathway]..sort((a, b) => a.order.compareTo(b.order));
    return steps;
  }

  /// Body sent when creating or updating a career from the admin form.
  /// The id is excluded because it travels in the URL, not the body.
  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'description': description,
        'whatYouDo': whatYouDo,
        'requiredSkills': requiredSkills,
        'recommendedStreams': recommendedStreams,
        'salaryRange': salaryRange.toJson(),
        'jobOutlook': jobOutlook,
        'industryOpportunities': industryOpportunities,
        'pathway': pathway.map((step) => step.toJson()).toList(),
        'interestTags': interestTags,
        'alSubjects': alSubjects,
        'personalityTypes': personalityTypes,
        'workStyles': workStyles,
        'relatedCourseKeywords': relatedCourseKeywords,
      };
}

/// One ranked career returned by POST /api/careers/recommend.
class CareerRecommendation {
  const CareerRecommendation({
    required this.career,
    required this.matchPercentage,
    this.reasons = const [],
  });

  factory CareerRecommendation.fromJson(Map<String, dynamic> json) =>
      CareerRecommendation(
        career: Career.fromJson(
          (json['career'] as Map<String, dynamic>?) ?? const {},
        ),
        matchPercentage: (json['matchPercentage'] as num?)?.toInt() ?? 0,
        reasons: _stringList(json['reasons']),
      );

  final Career career;
  final int matchPercentage;

  /// Short explanations such as "Suits the Science stream", shown under each
  /// result so a student understands why the career was suggested.
  final List<String> reasons;
}

/// The full recommendation response, including how much of the form was
/// answered so the results screen can show a confidence note.
class CareerRecommendationResult {
  const CareerRecommendationResult({
    required this.matches,
    required this.answeredComponents,
    required this.totalComponents,
  });

  factory CareerRecommendationResult.fromJson(Map<String, dynamic> json) =>
      CareerRecommendationResult(
        matches: ((json['data'] as List?) ?? const [])
            .map((item) =>
                CareerRecommendation.fromJson(item as Map<String, dynamic>))
            .toList(),
        answeredComponents: (json['answeredComponents'] as num?)?.toInt() ?? 0,
        totalComponents: (json['totalComponents'] as num?)?.toInt() ?? 0,
      );

  final List<CareerRecommendation> matches;
  final int answeredComponents;
  final int totalComponents;

  /// e.g. "Based on 3 of 5 answers" - shown so a high percentage from a
  /// half-filled form is read in context.
  String get confidenceNote =>
      'Based on $answeredComponents of $totalComponents answers';
}

/// Reads a JSON value that should be a list of strings, skipping anything that
/// is not a string so one bad entry cannot break a whole screen.
List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}

/// Formats an integer with thousands separators, e.g. 150000 -> "150,000".
String _thousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
