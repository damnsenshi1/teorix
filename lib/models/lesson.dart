class LessonSection {
  final String heading;
  final String body;
  final List<String> bullets;

  const LessonSection({required this.heading, required this.body, required this.bullets});

  factory LessonSection.fromJson(Map<String, dynamic> json) => LessonSection(
        heading: (json['heading'] ?? '') as String,
        body: (json['body'] ?? '') as String,
        bullets: List<String>.from(json['bullets'] as List? ?? const []),
      );
}

class Lesson {
  final String id;
  final String category;
  final String module;
  final int order;
  final String title;
  final int minutes;
  final String summary;
  final List<LessonSection> sections;
  final List<String> keyPoints;
  final List<String> examTips;
  final List<String> tags;

  const Lesson({
    required this.id,
    required this.category,
    required this.module,
    required this.order,
    required this.title,
    required this.minutes,
    required this.summary,
    required this.sections,
    required this.keyPoints,
    required this.examTips,
    required this.tags,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] as String,
        category: json['category'] as String,
        module: (json['module'] ?? 'Genel') as String,
        order: (json['order'] as num?)?.toInt() ?? 0,
        title: json['title'] as String,
        minutes: (json['minutes'] as num?)?.toInt() ?? 10,
        summary: json['summary'] as String? ?? '',
        sections: (json['sections'] as List? ?? const [])
            .map((e) => LessonSection.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        keyPoints: List<String>.from(json['key_points'] as List? ?? const []),
        examTips: List<String>.from(json['exam_tips'] as List? ?? const []),
        tags: List<String>.from(json['tags'] as List? ?? const []),
      );
}
