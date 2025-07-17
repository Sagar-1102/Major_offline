class Schedule {
  final int id;
  final String subject;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  Schedule({
    required this.id,
    required this.subject,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    // UPDATE: Correctly map keys from the backend API
    return Schedule(
      id: json['id'],
      subject: json['subject_name'],
      dayOfWeek: json['day_of_week'],
      startTime: json['start_time'],
      endTime: json['end_time'],
    );
  }
}