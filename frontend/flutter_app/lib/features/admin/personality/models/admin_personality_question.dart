class AdminQuestionOption {
  const AdminQuestionOption({
    required this.text,
    required this.score,
  });

  factory AdminQuestionOption.fromJson(Map<String, dynamic> json) =>
      AdminQuestionOption(
        text: (json['text'] ?? json['label'] ?? '') as String,
        score: ((json['score'] ?? json['value'] ?? 0) as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
    'text': text,
    'score': score,
  };

  final String text;
  final int score;
}

class AdminPersonalityQuestion {
  AdminPersonalityQuestion({
    required this.id,
    required this.questionText,
    this.type = 'personality',
    this.category = 'analytical',
    this.answerType = 'likert_5',
    this.options = const [],
    this.reverseScoring = false,
    this.displayOrder = 1,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminPersonalityQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List?) ?? const [];
    return AdminPersonalityQuestion(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      questionText: (json['questionText'] ?? json['text'] ?? '') as String,
      type: (json['type'] as String?)?.toLowerCase() ?? 'personality',
      category: (json['category'] as String?)?.toLowerCase() ?? 'analytical',
      answerType: (json['answerType'] as String?) ?? 'likert_5',
      options: rawOptions
          .map((o) => AdminQuestionOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      reverseScoring: (json['reverseScoring'] as bool?) ?? false,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 1,
      isActive: (json['isActive'] as bool?) ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'questionText': questionText,
    'type': type,
    'category': category,
    'answerType': answerType,
    'options': options.map((o) => o.toJson()).toList(),
    'reverseScoring': reverseScoring,
    'displayOrder': displayOrder,
    'isActive': isActive,
  };

  AdminPersonalityQuestion copyWith({
    String? id,
    String? questionText,
    String? type,
    String? category,
    String? answerType,
    List<AdminQuestionOption>? options,
    bool? reverseScoring,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AdminPersonalityQuestion(
        id: id ?? this.id,
        questionText: questionText ?? this.questionText,
        type: type ?? this.type,
        category: category ?? this.category,
        answerType: answerType ?? this.answerType,
        options: options ?? this.options,
        reverseScoring: reverseScoring ?? this.reverseScoring,
        displayOrder: displayOrder ?? this.displayOrder,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  final String id;
  final String questionText;
  final String type;
  final String category;
  final String answerType;
  final List<AdminQuestionOption> options;
  final bool reverseScoring;
  final int displayOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class AdminPersonalityAnalytics {
  const AdminPersonalityAnalytics({
    this.totalQuestions = 0,
    this.activeQuestions = 0,
    this.inactiveQuestions = 0,
    this.totalAttempts = 0,
    this.categoryDistribution = const {},
    this.typeDistribution = const {},
  });

  factory AdminPersonalityAnalytics.fromJson(Map<String, dynamic> json) {
    final catDist = (json['categoryDistribution'] as Map?) ?? const {};
    final typeDist = (json['typeDistribution'] as Map?) ?? const {};

    return AdminPersonalityAnalytics(
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      activeQuestions: (json['activeQuestions'] as num?)?.toInt() ?? 0,
      inactiveQuestions: (json['inactiveQuestions'] as num?)?.toInt() ?? 0,
      totalAttempts: (json['totalAttempts'] as num?)?.toInt() ?? 0,
      categoryDistribution: catDist.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      ),
      typeDistribution: typeDist.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      ),
    );
  }

  final int totalQuestions;
  final int activeQuestions;
  final int inactiveQuestions;
  final int totalAttempts;
  final Map<String, int> categoryDistribution;
  final Map<String, int> typeDistribution;
}

