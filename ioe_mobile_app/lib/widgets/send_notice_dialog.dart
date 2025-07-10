import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ioe_mobile_app/services/api_service.dart';
import 'package:ioe_mobile_app/services/auth_service.dart';

class SendNoticeDialog extends StatefulWidget {
  const SendNoticeDialog({super.key});

  @override
  State<SendNoticeDialog> createState() => _SendNoticeDialogState();
}

class _SendNoticeDialogState extends State<SendNoticeDialog> {
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send Notice'),
      content: TextField(
        controller: _messageController,
        decoration: const InputDecoration(hintText: 'Type your notice here...'),
        maxLines: 5,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _sendNotice, child: const Text('Send')),
      ],
    );
  }

  void _sendNotice() {
    if (_messageController.text.isEmpty) return;
    final apiService = Provider.of<ApiService>(context, listen: false);
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser!;
    apiService.sendNotice(currentUser, _messageController.text);
    Navigator.pop(context);
  }
}