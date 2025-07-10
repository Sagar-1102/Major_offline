import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ioe_mobile_app/services/api_service.dart';
import 'package:ioe_mobile_app/services/auth_service.dart';
import 'package:ioe_mobile_app/models/notice_model.dart';
import 'package:ioe_mobile_app/widgets/notice_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Notice>> _noticesFuture;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  void _loadNotices() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser!;
    setState(() {
      _noticesFuture = apiService.getNotices(currentUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _loadNotices(),
        child: FutureBuilder<List<Notice>>(
          future: _noticesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No notices to display.'));
            }

            final notices = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notices.length,
              itemBuilder: (context, index) {
                return NoticeCard(notice: notices[index]);
              },
            );
          },
        ),
      ),
    );
  }
}