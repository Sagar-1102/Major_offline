import 'package:ioe_mobile_app/models/user_model.dart';

class Notice {
  final int id;
  final String message;
  final DateTime timestamp;
  final User author;

  Notice({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.author,
  });
}