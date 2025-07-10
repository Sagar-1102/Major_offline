import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ioe_mobile_app/services/auth_service.dart';
import 'package:ioe_mobile_app/models/user_model.dart';
import 'package:ioe_mobile_app/screens/dashboard_screen.dart';
import 'package:ioe_mobile_app/screens/user_management_screen.dart';
import 'package:ioe_mobile_app/screens/schedule_screen.dart';
import 'package:ioe_mobile_app/widgets/add_schedule_dialog.dart';
import 'package:ioe_mobile_app/widgets/send_notice_dialog.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  List<Widget> _buildScreens(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return [const DashboardScreen(), const UserManagementScreen()];
      case UserRole.cr:
      case UserRole.student:
        return [const DashboardScreen(), const ScheduleScreen()];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser!;
    final screens = _buildScreens(currentUser.role);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle(currentUser.role, _selectedIndex)),
        actions: _buildHeaderActions(context, currentUser.role),
      ),
      drawer: _buildDrawer(context, currentUser),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, User currentUser) {
    final navItems = _getNavItems(currentUser.role);
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(currentUser.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            accountEmail: Text(currentUser.email),
            currentAccountPicture: CircleAvatar(
              backgroundImage: NetworkImage(currentUser.avatarUrl),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1F2937),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                return ListTile(
                  leading: Icon(item['icon']),
                  title: Text(item['title']),
                  selected: _selectedIndex == index,
                  selectedTileColor: Colors.blue.withOpacity(0.1),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    Navigator.pop(context); // Close the drawer
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.logOut, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Provider.of<AuthService>(context, listen: false).logout();
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getNavItems(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return [
          {'icon': LucideIcons.layoutDashboard, 'title': 'Dashboard'},
          {'icon': LucideIcons.users, 'title': 'User Management'},
        ];
      case UserRole.cr:
        return [
          {'icon': LucideIcons.layoutDashboard, 'title': 'Dashboard'},
          {'icon': LucideIcons.calendarDays, 'title': 'Manage Schedule'},
        ];
      case UserRole.student:
        return [
          {'icon': LucideIcons.layoutDashboard, 'title': 'Dashboard'},
          {'icon': LucideIcons.calendarDays, 'title': 'View Schedule'},
        ];
    }
  }

  String _getPageTitle(UserRole role, int index) {
    return _getNavItems(role)[index]['title'];
  }

  List<Widget> _buildHeaderActions(BuildContext context, UserRole role) {
    if (role == UserRole.admin || role == UserRole.cr) {
      return [
        IconButton(
          icon: const Icon(LucideIcons.send),
          onPressed: () => showDialog(context: context, builder: (_) => const SendNoticeDialog()),
          tooltip: 'Send Notice',
        ),
        if (role == UserRole.cr)
          IconButton(
            icon: const Icon(LucideIcons.calendarPlus),
            onPressed: () => showDialog(context: context, builder: (_) => const AddScheduleDialog()),
            tooltip: 'Add Schedule',
          ),
        const SizedBox(width: 10),
      ];
    }
    return [];
  }
}