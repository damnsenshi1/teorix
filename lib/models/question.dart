class Question {
  final String id;
  final String lessonId;
  final String category;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String difficulty;
  final List<String> tags;
  final String? visualKey;
  final int penaltyPoints;

  const Question({
    required this.id,
    required this.lessonId,
    required this.category,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.difficulty,
    required this.tags,
    this.visualKey,
    this.penaltyPoints = 2,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        lessonId: (json['lesson_id'] ?? '') as String,
        category: json['category'] as String,
        text: json['text'] as String,
        options: List<String>.from(json['options'] as List),
        correctIndex: (json['correct_index'] as num).toInt(),
        explanation: (json['explanation'] ?? '') as String,
        difficulty: (json['difficulty'] ?? 'medium') as String,
        tags: List<String>.from(json['tags'] as List? ?? const []),
        visualKey: json['visual_key'] as String?,
        penaltyPoints: (json['penalty_points'] as num?)?.toInt() ?? 2,
      );
}
