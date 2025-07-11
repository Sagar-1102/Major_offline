import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ioe_mobile_app/models/user_model.dart';
import 'package:ioe_mobile_app/models/notice_model.dart';
import 'package:ioe_mobile_app/models/schedule_model.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:5000/api';

  Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to log in');
    }
  }

  Future<User> signup({
    required String name, required String email, required String password,
    required String department, required int? year, required UserRole role
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
          'name': name, 'email': email, 'password': password,
          'department': department, 'year': year,
          'role': role.name
      }),
    );
    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to sign up: ${jsonDecode(response.body)['error']}');
    }
  }

  Future<List<Notice>> getNotices(User currentUser) async {
    final response = await http.get(Uri.parse('$_baseUrl/notices/${currentUser.id}'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Notice.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notices');
    }
  }
  
  Future<void> sendNotice(User author, String message) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/notices'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'author_id': author.id, 'message': message}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to send notice');
    }
  }

  Future<List<User>> getUsersForAdmin(User admin) async {
    final response = await http.get(Uri.parse('$_baseUrl/admin/users/${admin.id}'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }
  
  Future<void> toggleCRStatus(User user) async {
    final response = await http.post(Uri.parse('$_baseUrl/admin/toggle_cr/${user.id}'));
    if (response.statusCode != 200) {
      throw Exception('Failed to update user role');
    }
  }

  Future<List<Schedule>> getSchedules(User user) async {
    final response = await http.get(Uri.parse('$_baseUrl/schedules/${user.id}'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Schedule.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load schedules');
    }
  }

  Future<void> addSchedule(User cr, String subject, int day, String start, String end) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/schedules'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
          'author_id': cr.id, 'subject': subject, 'dayOfWeek': day,
          'startTime': start, 'endTime': end
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add schedule');
    }
  }
}