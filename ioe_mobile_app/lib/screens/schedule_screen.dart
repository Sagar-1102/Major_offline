import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ioe_mobile_app/services/api_service.dart';
import 'package:ioe_mobile_app/services/auth_service.dart';
import 'package:ioe_mobile_app/models/schedule_model.dart';
import 'package:ioe_mobile_app/widgets/add_schedule_dialog.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Schedule>> _scheduleFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _scheduleFuture = _loadSchedules();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fabScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<Schedule>> _loadSchedules() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final currentUser =
        Provider.of<AuthService>(context, listen: false).currentUser!;
    return apiService.getSchedules(currentUser);
  }

  void _refreshSchedules() {
    setState(() {
      _scheduleFuture = _loadSchedules();
    });
  }

  void _showAddScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AddScheduleDialog(
        onScheduleAdded: _refreshSchedules,
      ),
    );
  }

  IconData getSubjectIcon(String subject) {
    final subjectLower = subject.toLowerCase();
    if (subjectLower.contains('math')) return Icons.calculate;
    if (subjectLower.contains('computer network') ||
        subjectLower.contains('network')) {
      return Icons.network_check;
    }
    if (subjectLower.contains('physics')) return Icons.science;
    if (subjectLower.contains('chemistry')) return Icons.biotech;
    if (subjectLower.contains('biology')) return Icons.local_florist;
    if (subjectLower.contains('english')) return Icons.book;
    if (subjectLower.contains('history')) return Icons.history_edu;
    return Icons.book_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday'
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x00ffffff),
              Color(0xFFF7FAFF),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2A6EBB), Color(0xFF3B8DE3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFF2A6EBB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Class Schedule',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'View and manage your weekly classes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Schedule>>(
                future: _scheduleFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF2A6EBB)),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!, width: 1),
                        ),
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'No schedule available.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    );
                  }

                  final schedules = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      final daySchedules = schedules
                          .where((s) => s.dayOfWeek == index)
                          .toList();
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFF),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    days[index],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2C3E50),
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                ),
                              ),
                              if (daySchedules.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Text(
                                    'No classes scheduled for this day.',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                )
                              else
                                ...daySchedules.map((s) => FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: SlideTransition(
                                        position: _slideAnimation,
                                        child: Card(
                                          margin: const EdgeInsets.only(
                                              bottom: 12, left: 8, right: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          elevation: 4,
                                          color: const Color(0xFFF8FAFF),
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8),
                                            leading: Icon(
                                              getSubjectIcon(s.subject),
                                              color: const Color(0xFF2A6EBB),
                                              size: 24,
                                            ),
                                            title: Text(
                                              s.subject,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: Color(0xFF2C3E50),
                                                fontFamily: 'Roboto',
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${s.startTime} - ${s.endTime}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                                fontFamily: 'Roboto',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton(
          onPressed: _showAddScheduleDialog,
          backgroundColor: Colors.transparent,
          elevation: 4,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2A6EBB), Color(0xFF3B8DE3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}