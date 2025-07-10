enum UserRole { admin, cr, student }

class User {
  final int id;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final int? year;
  final String avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    this.year,
    required this.avatarUrl,
  });
}