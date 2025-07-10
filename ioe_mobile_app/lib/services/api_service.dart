import 'package:ioe_mobile_app/models/user_model.dart';
import 'package:ioe_mobile_app/models/notice_model.dart';
import 'package:ioe_mobile_app/models/schedule_model.dart';

// This is a MOCK service that simulates a real backend API.
// In a real app, this class would make HTTP requests to your Python server.
class ApiService {
  // --- Mock Database ---
  final List<User> _users = [
    User(id: 1, name: 'Suresh Kumar', email: 'admin@ioe.edu.np', role: UserRole.admin, department: 'BCT', avatarUrl: 'https://i.pravatar.cc/150?u=1'),
    User(id: 2, name: 'Rita Sharma', email: 'cr@ioe.edu.np', role: UserRole.cr, department: 'BCT', year: 3, avatarUrl: 'https://i.pravatar.cc/150?u=2'),
    User(id: 3, name: 'Hari Bahadur', email: 'student@ioe.edu.np', role: UserRole.student, department: 'BCT', year: 3, avatarUrl: 'https://i.pravatar.cc/150?u=3'),
    User(id: 4, name: 'Gita Thapa', email: 'gita@ioe.edu.np', role: UserRole.student, department: 'BCT', year: 3, avatarUrl: 'https://i.pravatar.cc/150?u=4'),
    User(id: 5, name: 'Nabin Shrestha', email: 'nabin@ioe.edu.np', role: UserRole.student, department: 'BCT', year: 2, avatarUrl: 'https://i.pravatar.cc/150?u=5'),
  ];

  final List<Notice> _notices = [];
  final List<Schedule> _schedules = [];

  ApiService() {
    _notices.addAll([
      Notice(id: 1, message: 'Mid-term examinations will commence from next week. Please collect your admit cards.', timestamp: DateTime.now().subtract(const Duration(days: 2)), author: _users[0]),
      Notice(id: 2, message: 'The Database Systems class scheduled for 2 PM today has been cancelled.', timestamp: DateTime.now().subtract(const Duration(hours: 1)), author: _users[1]),
    ]);
    _schedules.addAll([
      Schedule(id: 1, subject: 'Database Systems', dayOfWeek: 0, startTime: '14:00', endTime: '16:00'),
      Schedule(id: 2, subject: 'Operating Systems', dayOfWeek: 1, startTime: '10:00', endTime: '12:00'),
    ]);
  }

  // --- Mock API Methods ---

  Future<User> loginAs(UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    return _users.firstWhere((user) => user.role == role);
  }

  Future<List<User>> getUsersForAdmin(User admin) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _users.where((user) => user.department == admin.department && user.id != admin.id).toList();
  }

  Future<void> toggleCRStatus(User user) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = User(
        id: user.id, name: user.name, email: user.email,
        role: user.role == UserRole.student ? UserRole.cr : UserRole.student,
        department: user.department, year: user.year, avatarUrl: user.avatarUrl
      );
    }
  }

  Future<List<Notice>> getNotices(User currentUser) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _notices.where((notice) =>
        notice.author.department == currentUser.department &&
        (notice.author.role == UserRole.admin || notice.author.year == currentUser.year)
    ).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> sendNotice(User author, String message) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final newNotice = Notice(
      id: _notices.length + 1,
      message: message,
      timestamp: DateTime.now(),
      author: author,
    );
    _notices.insert(0, newNotice);
  }

  Future<List<Schedule>> getSchedules(User currentUser) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _schedules.where((s) => s.dayOfWeek >= 0).toList(); // Simplified for demo
  }

  Future<void> addSchedule(User cr, String subject, int day, String start, String end) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newSchedule = Schedule(
      id: _schedules.length + 1,
      subject: subject,
      dayOfWeek: day,
      startTime: start,
      endTime: end,
    );
    _schedules.add(newSchedule);
  }
}