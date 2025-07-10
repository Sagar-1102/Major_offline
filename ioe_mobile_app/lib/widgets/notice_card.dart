import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ioe_mobile_app/models/notice_model.dart';
import 'package:ioe_mobile_app/models/user_model.dart';

class NoticeCard extends StatelessWidget {
  final Notice notice;
  const NoticeCard({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    final authorRole = notice.author.role == UserRole.admin
        ? 'Department Admin'
        : 'CR (Year ${notice.author.year})';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(notice.author.avatarUrl),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notice.author.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(authorRole, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Text(notice.message, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('MMM d, yyyy - hh:mm a').format(notice.timestamp),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}