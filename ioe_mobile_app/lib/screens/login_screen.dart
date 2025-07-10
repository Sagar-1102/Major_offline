import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ioe_mobile_app/services/auth_service.dart';
import 'package:ioe_mobile_app/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _login(UserRole role) async {
    setState(() => _isLoading = true);
    await Provider.of<AuthService>(context, listen: false).login(role);
    // No need to set loading to false as the widget will be replaced
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 100),
                const SizedBox(height: 20),
                const Text(
                  'IOE Attendance Portal',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pulchowk Campus, Lalitpur',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Select a role to log in as:',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                      _buildLoginButton(
                        'Log in as Admin',
                        const Color(0xFF2563EB),
                        () => _login(UserRole.admin),
                      ),
                      const SizedBox(height: 16),
                      _buildLoginButton(
                        'Log in as CR',
                        const Color(0xFF16A34A),
                        () => _login(UserRole.cr),
                      ),
                      const SizedBox(height: 16),
                      _buildLoginButton(
                        'Log in as Student',
                        const Color(0xFF4B5563),
                        () => _login(UserRole.student),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}