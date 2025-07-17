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
    required this.id, required this.name, required this.email,
    required this.role, required this.department, this.year,
    required this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      // UPDATE: Made role parsing more robust
      role: UserRole.values.byName(json['role']),
      department: json['department'],
      year: json['year'],
      avatarUrl: json['avatarUrl'],
    );
  }
}