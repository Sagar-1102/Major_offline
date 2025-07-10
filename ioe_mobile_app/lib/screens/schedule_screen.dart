import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ioe_mobile_app/services/api_service.dart';
import 'package:ioe_mobile_app/services/auth_service.dart';
import 'package:ioe_mobile_app/models/schedule_model.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<Schedule>> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  void _loadSchedules() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser!;
    setState(() {
      _scheduleFuture = apiService.getSchedules(currentUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

    return Scaffold(
      body: FutureBuilder<List<Schedule>>(
        future: _scheduleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No schedule available.'));
          }

          final schedules = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final daySchedules = schedules.where((s) => s.dayOfWeek == index).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(days[index], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  if (daySchedules.isEmpty)
                    const Text('No classes scheduled for this day.')
                  else
                    ...daySchedules.map((s) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(s.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${s.startTime} - ${s.endTime}'),
                      ),
                    )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}