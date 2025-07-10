import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ioe_mobile_app/services/api_service.dart';
import 'package:ioe_mobile_app/services/auth_service.dart';
import 'package:ioe_mobile_app/models/user_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Future<List<User>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser!;
    setState(() {
      _usersFuture = apiService.getUsersForAdmin(currentUser);
    });
  }

  Future<void> _toggleCR(User user) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    await apiService.toggleCRStatus(user);
    _loadUsers(); // Refresh the list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<User>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl)),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${user.department} - Year ${user.year}'),
                  trailing: ElevatedButton(
                    onPressed: () => _toggleCR(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user.role == UserRole.cr ? Colors.amber : Colors.blue,
                    ),
                    child: Text(user.role == UserRole.cr ? 'Demote' : 'Promote to CR', style: const TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}