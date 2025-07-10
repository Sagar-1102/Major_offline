import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ioe_mobile_app/services/api_service.dart';
import 'package:ioe_mobile_app/services/auth_service.dart';

class AddScheduleDialog extends StatefulWidget {
  const AddScheduleDialog({super.key});

  @override
  State<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<AddScheduleDialog> {
  final _subjectController = TextEditingController();
  int _selectedDay = 0;
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Class Schedule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Subject Name')),
            DropdownButton<int>(
              value: _selectedDay,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Monday')),
                DropdownMenuItem(value: 1, child: Text('Tuesday')),
                DropdownMenuItem(value: 2, child: Text('Wednesday')),
                DropdownMenuItem(value: 3, child: Text('Thursday')),
                DropdownMenuItem(value: 4, child: Text('Friday')),
              ],
              onChanged: (value) => setState(() => _selectedDay = value!),
            ),
            ListTile(
              title: Text('Start Time: ${_startTime.format(context)}'),
              onTap: () async {
                final time = await showTimePicker(context: context, initialTime: _startTime);
                if (time != null) setState(() => _startTime = time);
              },
            ),
            ListTile(
              title: Text('End Time: ${_endTime.format(context)}'),
              onTap: () async {
                final time = await showTimePicker(context: context, initialTime: _endTime);
                if (time != null) setState(() => _endTime = time);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _addSchedule, child: const Text('Add')),
      ],
    );
  }

  void _addSchedule() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser!;
    apiService.addSchedule(
      currentUser,
      _subjectController.text,
      _selectedDay,
      _startTime.format(context),
      _endTime.format(context),
    );
    Navigator.pop(context);
  }
}