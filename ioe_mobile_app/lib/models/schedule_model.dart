class Schedule {
  final int id;
  final String subject;
  final int dayOfWeek; // 0 = Monday, 6 = Sunday
  final String startTime;
  final String endTime;

  Schedule({
    required this.id,
    required this.subject,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });
}