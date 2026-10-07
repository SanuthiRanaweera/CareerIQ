import 'package:flutter_app/models/career.dart';
import 'package:flutter_app/services/career_service.dart';

// Shared test doubles for the Career module.
//
// Widget tests cannot reach the real backend: `testWidgets` installs its own
// HttpOverrides, so every HTTP request returns 400 no matter what the test
// does. Every Career screen therefore accepts an injectable CareerService, and
// these fakes stand in for it. Keeping them in one file means each screen test
// describes only what is specific to that screen.

/// Builds a Career with sensible defaults, so a test only has to state the
/// fields it actually cares about.
Career careerFixture({
  String id = 'id-1',
  String title = 'Software Engineer',
  String category = 'Information Technology',
  String description = 'Designs, builds and maintains software systems.',
  List<String> whatYouDo = const ['Write and review code'],
  List<String> requiredSkills = const ['Programming'],
  List<String> recommendedStreams = const ['Technology'],
  List<String> industryOpportunities = const [],
  List<CareerPathwayStep> pathway = const [],
  List<String> relatedCourseKeywords = const [],
  int salaryMin = 150000,
  int salaryMax = 500000,
  String jobOutlook = 'Very High',
}) =>
    Career(
      id: id,
      title: title,
      category: category,
      description: description,
      salaryRange: SalaryRange(min: salaryMin, max: salaryMax),
      jobOutlook: jobOutlook,
      whatYouDo: whatYouDo,
      requiredSkills: requiredSkills,
      recommendedStreams: recommendedStreams,
      industryOpportunities: industryOpportunities,
      pathway: pathway,
      relatedCourseKeywords: relatedCourseKeywords,
    );

/// Three careers across three categories, enough to exercise lists, filters
/// and singular/plural wording.
/// Descriptions and skills are deliberately distinct per career: sharing one
/// default description would make every search match everything, and a search
/// test would then pass without proving anything.
List<Career> sampleCareers() => [
      careerFixture(
        id: 'id-se',
        title: 'Software Engineer',
        category: 'Information Technology',
        description: 'Designs, builds and maintains software systems.',
        requiredSkills: const ['Programming', 'Databases'],
      ),
      careerFixture(
        id: 'id-md',
        title: 'Medical Doctor',
        category: 'Healthcare & Medicine',
        description: 'Diagnoses and treats illness and cares for patients.',
        requiredSkills: const ['Clinical knowledge', 'Empathy'],
        recommendedStreams: const ['Science'],
        salaryMin: 150000,
        salaryMax: 600000,
      ),
      careerFixture(
        id: 'id-ao',
        title: 'Agricultural Officer',
        category: 'Agriculture & Environment',
        description: 'Supports farmers with crop science and soil management.',
        requiredSkills: const ['Crop science', 'Field research'],
        recommendedStreams: const ['Science'],
        salaryMin: 70000,
        salaryMax: 220000,
        jobOutlook: 'Medium',
      ),
    ];

/// In-memory stand-in for [CareerService].
///
/// Records the arguments it was called with, so a test can assert that a
/// screen asked the backend for the right thing, and can be told to fail so
/// error states are exercised.
class FakeCareerService implements CareerService {
  FakeCareerService({
    List<Career>? careers,
    this.categories = const [
      'Agriculture & Environment',
      'Healthcare & Medicine',
      'Information Technology',
    ],
    this.error,
    this.recommendation,
    this.responseDelay = const Duration(milliseconds: 10),
  }) : careers = careers ?? sampleCareers();

  /// Careers returned by [getCareers] and [getCareerById].
  List<Career> careers;

  /// Categories returned by [getCategories].
  List<String> categories;

  /// When set, every call throws this instead of returning data.
  Object? error;

  /// Result returned by [recommend].
  CareerRecommendationResult? recommendation;

  /// Small delay so tests can observe the loading state before data arrives.
  /// Mutable so a test can make one response slower than the next and check
  /// that a stale reply cannot overwrite newer results.
  Duration responseDelay;

  // --- Recorded calls, for assertions ---
  int getCareersCallCount = 0;
  String? lastSearch;
  String? lastCategory;
  Career? lastCreated;
  Career? lastUpdated;
  String? lastUpdatedId;
  String? lastDeletedId;
  Map<String, dynamic>? lastRecommendBody;

  Future<T> _respond<T>(T value) async {
    await Future<void>.delayed(responseDelay);
    if (error != null) throw error!;
    return value;
  }

  @override
  Future<List<Career>> getCareers(
    String token, {
    String search = '',
    String category = '',
  }) {
    getCareersCallCount++;
    lastSearch = search;
    lastCategory = category;

    // Mirror the backend's filtering so filter tests exercise realistic data.
    var results = careers;
    if (category.isNotEmpty && category.toLowerCase() != 'all') {
      results = results
          .where((c) => c.category.toLowerCase() == category.toLowerCase())
          .toList();
    }
    if (search.isNotEmpty) {
      final term = search.toLowerCase();
      results = results
          .where((c) =>
              c.title.toLowerCase().contains(term) ||
              c.category.toLowerCase().contains(term) ||
              c.description.toLowerCase().contains(term) ||
              c.requiredSkills.any((s) => s.toLowerCase().contains(term)))
          .toList();
    }
    return _respond(results);
  }

  @override
  Future<List<String>> getCategories(String token) => _respond(categories);

  @override
  Future<Career> getCareerById(String token, String id) => _respond(
        careers.firstWhere(
          (c) => c.id == id,
          orElse: () => careers.isNotEmpty ? careers.first : careerFixture(),
        ),
      );

  @override
  Future<Career> createCareer(String token, Career career) {
    lastCreated = career;
    return _respond(career);
  }

  @override
  Future<Career> updateCareer(String token, String id, Career career) {
    lastUpdatedId = id;
    lastUpdated = career;
    return _respond(career);
  }

  @override
  Future<void> deleteCareer(String token, String id) {
    lastDeletedId = id;
    return _respond(null);
  }

  @override
  Future<CareerRecommendationResult> recommend(
    String token, {
    String? stream,
    List<String> subjects = const [],
    List<String> interests = const [],
    String? personalityType,
    String? workStyle,
    int? limit,
  }) {
    lastRecommendBody = {
      'stream': stream,
      'subjects': subjects,
      'interests': interests,
      'personalityType': personalityType,
      'workStyle': workStyle,
      'limit': limit,
    };
    return _respond(
      recommendation ??
          const CareerRecommendationResult(
            matches: [],
            answeredComponents: 0,
            totalComponents: 5,
          ),
    );
  }
}
