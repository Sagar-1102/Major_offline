import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ioe_mobile_app/services/auth_service.dart';
import 'package:ioe_mobile_app/services/api_service.dart';
import 'package:ioe_mobile_app/screens/login_screen.dart';
import 'package:ioe_mobile_app/screens/main_shell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use MultiProvider to provide services to the entire app
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => ApiService()),
      ],
      child: MaterialApp(
        title: 'IOE Attendance Portal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Inter',
          scaffoldBackgroundColor: const Color(0xFFF0F2F5),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer widget listens for changes in AuthService
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // If a user is logged in, show the main application shell.
        // Otherwise, show the login screen.
        if (authService.currentUser != null) {
          return const MainShell();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}