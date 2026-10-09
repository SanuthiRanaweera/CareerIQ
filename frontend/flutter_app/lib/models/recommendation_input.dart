// Input vocabulary and answer object for career recommendations.
//
// The option lists mirror backend/data/careerOptions.js. The backend remains
// the authority: it validates every submitted value and replies with a 400
// naming the valid options, so a drift between the two shows up immediately
// as a clear error rather than a silent wrong result.

/// A/L streams offered in Sri Lankan schools. Identical to the `stream` enum
/// on the Student model, so these answers can later come from a real student
/// profile without any value mapping.
const List<String> alStreams = [
  'Science',
  'Mathematics',
  'Commerce',
  'Arts',
  'Technology',
];

/// Personality categories, matching those produced by the personality test.
const List<String> personalityTypes = [
  'Analytical',
  'Creative',
  'Social',
  'Leadership',
  'Practical',
  'Organized',
];

/// How a person prefers to spend a working day.
const List<String> workStyles = [
  'Office-based',
  'Remote',
  'Fieldwork',
  'Laboratory',
  'Team-based',
  'Independent',
];

/// Common A/L subjects, offered as suggestions for the optional subject
/// question.
const List<String> alSubjectOptions = [
  'Combined Mathematics',
  'Physics',
  'Chemistry',
  'Biology',
  'ICT',
  'Engineering Technology',
  'Agricultural Science',
  'Accounting',
  'Business Studies',
  'Economics',
  'Political Science',
  'Geography',
  'Media Studies',
  'Art',
  'Logic',
  'Languages',
];

/// Interests a student can pick from. These match the `interestTags` stored
/// on careers, which is what the scoring compares them against.
const List<String> interestOptions = [
  'technology',
  'healthcare',
  'business',
  'design',
  'science',
  'mathematics',
  'helping people',
  'problem solving',
  'creativity',
  'research',
  'finance',
  'law',
  'environment',
  'agriculture',
  'marketing',
  'communication',
  'travel',
  'construction',
  'accounting',
  'art',
  'biology',
  'computers',
  'data',
  'debate',
  'economics',
  'hospitality',
  'infrastructure',
  'justice',
  'medicine',
  'nature',
  'numbers',
  'psychology',
  'social media',
  'software',
  'tourism',
  'writing',
];

/// The answers collected by the recommendation form.
///
/// A deliberately plain object: it carries nothing but the five values the
/// backend scores against. When the Student module is ready, the same object
/// can be built from a real Student record instead of a form, and neither the
/// API service nor the backend needs to change.
class RecommendationAnswers {
  const RecommendationAnswers({
    this.stream = '',
    this.subjects = const [],
    this.interests = const [],
    this.personalityType = '',
    this.workStyle = '',
  });

  final String stream;
  final List<String> subjects;
  final List<String> interests;
  final String personalityType;
  final String workStyle;

  /// How many of the five scoring components were answered. The backend
  /// reports its own count on the response; this mirrors it so the form can
  /// reason about completeness before submitting.
  int get answeredCount => [
    stream.isNotEmpty,
    subjects.isNotEmpty,
    interests.isNotEmpty,
    personalityType.isNotEmpty,
    workStyle.isNotEmpty,
  ].where((answered) => answered).length;

  /// Short description of what the ranking was based on, e.g.
  /// "Science stream, Analytical".
  String get summary => [
    if (stream.isNotEmpty) '$stream stream',
    if (personalityType.isNotEmpty) personalityType,
    if (workStyle.isNotEmpty) workStyle,
  ].join(', ');
}
