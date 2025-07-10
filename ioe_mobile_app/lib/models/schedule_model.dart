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

  // Factory constructor to create a Schedule from JSON data
  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      subject: json['subject'],
      dayOfWeek: json['dayOfWeek'],
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }
}