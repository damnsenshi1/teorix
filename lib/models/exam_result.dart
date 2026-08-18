class ExamResult {
  final int total;
  final int correct;
  final int wrong;
  final int empty;
  final DateTime completedAt;

  const ExamResult({
    required this.total,
    required this.correct,
    required this.wrong,
    required this.empty,
    required this.completedAt,
  });

  double get score => total == 0 ? 0 : (correct / total) * 100;
}
