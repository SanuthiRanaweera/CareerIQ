import 'package:flutter/material.dart';

class PersonalityQuestion {
  PersonalityQuestion({
    required this.id,
    required this.text,
    this.type = 'personality',
    this.category = 'analytical',
    this.answerType = 'likert_5',
    this.displayOrder = 0,
    this.reverseScoring = false,
    this.isActive = true,
    this.options = const [],
  });

  factory PersonalityQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List?) ?? const [];
    final parsedOptions = rawOptions
        .map((o) => PersonalityAnswerOption.fromJson(o as Map<String, dynamic>))
        .toList();

    return PersonalityQuestion(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      text: (json['text'] ?? json['questionText'] ?? '') as String,
      type: (json['type'] as String?) ?? 'personality',
      category: (json['category'] as String?) ?? 'analytical',
      answerType: (json['answerType'] as String?) ?? 'likert_5',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      reverseScoring: (json['reverseScoring'] as bool?) ?? false,
      isActive: (json['isActive'] as bool?) ?? true,
      options: parsedOptions,
    );
  }

  final String id;
  final String text;
  final String type;
  final String category;
  final String answerType;
  final int displayOrder;
  final bool reverseScoring;
  final bool isActive;
  final List<PersonalityAnswerOption> options;
}

class PersonalityAnswerOption {
  const PersonalityAnswerOption({required this.label, required this.value});

  factory PersonalityAnswerOption.fromJson(Map<String, dynamic> json) =>
      PersonalityAnswerOption(
        label: (json['label'] ?? json['text'] ?? '') as String,
        value: ((json['value'] ?? json['score'] ?? 0) as num).toInt(),
      );

  final String label;
  final int value;
}

class RecommendedCareerMatch {
  const RecommendedCareerMatch({
    required this.title,
    this.id,
    this.category,
    this.matchPercentage = 0,
    this.reasons = const [],
  });

  factory RecommendedCareerMatch.fromJson(Map<String, dynamic> json) =>
      RecommendedCareerMatch(
        title: (json['title'] ?? '') as String,
        id: (json['id'] ?? json['careerId'] ?? json['_id']) as String?,
        category: json['category'] as String?,
        matchPercentage: (json['matchPercentage'] as num?)?.toInt() ?? 0,
        reasons: ((json['reasons'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  final String title;
  final String? id;
  final String? category;
  final int matchPercentage;
  final List<String> reasons;
}

class RecommendedCourseMatch {
  const RecommendedCourseMatch({
    required this.title,
    this.id,
    this.university,
    this.stream,
    this.durationYears,
  });

  factory RecommendedCourseMatch.fromJson(Map<String, dynamic> json) =>
      RecommendedCourseMatch(
        title: (json['title'] ?? json['name'] ?? '') as String,
        id: (json['id'] ?? json['courseId'] ?? json['_id']) as String?,
        university: json['university'] as String?,
        stream: json['stream'] as String?,
        durationYears:
            (json['durationYears'] ?? json['duration'] as num?)?.toInt(),
      );

  final String title;
  final String? id;
  final String? university;
  final String? stream;
  final int? durationYears;
}

const personalityCategoryLabels = {
  'analytical': 'Analytical',
  'creative': 'Creative',
  'social': 'Social',
  'leadership': 'Leadership',
  'practical': 'Practical',
  'organized': 'Organized',
};

const personalityCategoryColors = {
  'analytical': Color(0xFF3B82F6),
  'creative': Color(0xFFEC4899),
  'social': Color(0xFF10B981),
  'leadership': Color(0xFFF59E0B),
  'practical': Color(0xFF6366F1),
  'organized': Color(0xFF14B8A6),
};

Color getCategoryColor(String category) {
  return personalityCategoryColors[category.toLowerCase()] ??
      const Color(0xFF8B5CF6);
}

String getCategoryLabel(String category) {
  return personalityCategoryLabels[category.toLowerCase()] ??
      (category.isNotEmpty
          ? '${category[0].toUpperCase()}${category.substring(1)}'
          : category);
}

class PersonalityResult {
  PersonalityResult({
    required this.resultType,
    required this.strengths,
    required this.careers,
    required this.scores,
    required this.completedDate,
    this.recommendedCareers = const [],
    this.recommendedCourses = const [],
  });

  factory PersonalityResult.fromJson(Map<String, dynamic> json) {
    final rawScores = (json['scores'] as Map?) ?? const {};
    final rawCareers = (json['careers'] as List?) ?? const [];
    final rawStrengths = (json['strengths'] as List?) ?? const [];
    final rawRecCareers = (json['recommendedCareers'] as List?) ?? const [];
    final rawRecCourses = (json['recommendedCourses'] as List?) ?? const [];

    return PersonalityResult(
      resultType: json['resultType'] as String? ?? 'General Explorer',
      strengths: rawStrengths.map((item) => item.toString()).toList(),
      careers: rawCareers.map((item) => item.toString()).toList(),
      scores: rawScores.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      ),
      completedDate: json['completedDate'] as String?,
      recommendedCareers: rawRecCareers
          .map((c) => c is Map<String, dynamic>
              ? RecommendedCareerMatch.fromJson(c)
              : RecommendedCareerMatch(title: c.toString()))
          .toList(),
      recommendedCourses: rawRecCourses
          .map((c) => c is Map<String, dynamic>
              ? RecommendedCourseMatch.fromJson(c)
              : RecommendedCourseMatch(title: c.toString()))
          .toList(),
    );
  }

  final String resultType;
  final List<String> strengths;
  final List<String> careers;
  final Map<String, int> scores;
  final String? completedDate;
  final List<RecommendedCareerMatch> recommendedCareers;
  final List<RecommendedCourseMatch> recommendedCourses;
}
