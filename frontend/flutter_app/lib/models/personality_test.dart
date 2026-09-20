class PersonalityQuestion {
  PersonalityQuestion({required this.id, required this.text});

  factory PersonalityQuestion.fromJson(Map<String, dynamic> json) =>
      PersonalityQuestion(
        id: json['id'] as String,
        text: json['text'] as String,
      );

  final String id;
  final String text;
}

class PersonalityAnswerOption {
  const PersonalityAnswerOption({required this.label, required this.value});

  factory PersonalityAnswerOption.fromJson(Map<String, dynamic> json) =>
      PersonalityAnswerOption(
        label: json['label'] as String,
        value: (json['value'] as num).toInt(),
      );

  final String label;
  final int value;
}

const personalityCategoryLabels = {
  'analytical': 'Analytical',
  'creative': 'Creative',
  'social': 'Social',
  'leadership': 'Leadership',
  'practical': 'Practical',
  'organized': 'Organized',
};

class PersonalityResult {
  PersonalityResult({
    required this.resultType,
    required this.strengths,
    required this.careers,
    required this.scores,
    required this.completedDate,
  });

  factory PersonalityResult.fromJson(Map<String, dynamic> json) {
    final rawScores = (json['scores'] as Map?) ?? const {};
    return PersonalityResult(
      resultType: json['resultType'] as String? ?? '',
      strengths: ((json['strengths'] as List?) ?? const [])
          .map((item) => item as String)
          .toList(),
      careers: ((json['careers'] as List?) ?? const [])
          .map((item) => item as String)
          .toList(),
      scores: rawScores.map(
        (key, value) => MapEntry(key as String, (value as num).toInt()),
      ),
      completedDate: json['completedDate'] as String?,
    );
  }

  final String resultType;
  final List<String> strengths;
  final List<String> careers;
  final Map<String, int> scores;
  final String? completedDate;
}
