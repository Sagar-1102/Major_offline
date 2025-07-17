import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ioe_mobile_app/models/user_model.dart';
import 'package:ioe_mobile_app/services/auth_service.dart';
import 'package:ioe_mobile_app/screens/face_capture_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _yearController = TextEditingController();

  String _selectedDepartment = 'BCT';
  final UserRole _selectedRole = UserRole.student;
  List<List<double>> _capturedEmbeddings = [];
  bool _isLoading = false;

  final List<String> _departments = [
    "BCT",
    "BEI",
    "BCE",
    "BAG",
    "BAR",
    "BME",
    "BEL"
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _captureFaceEmbeddings() async {
    final List<List<double>>? result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FaceCaptureScreen()),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _capturedEmbeddings = result;
      });
    }
  }

  Future<void> _performSignup() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole != UserRole.admin && _capturedEmbeddings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please complete the face capture step.'),
              backgroundColor: Colors.red),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.signup(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        department: _selectedDepartment,
        year: _selectedRole == UserRole.admin
            ? null
            : int.parse(_yearController.text),
        role: _selectedRole,
        embeddings: _capturedEmbeddings,
      );

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Signup successful! Please log in.'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(authService.errorMessage ?? 'Signup failed.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Full Name', border: OutlineInputBorder()),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter an email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                      labelText: 'Password', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a password' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  decoration: const InputDecoration(
                      labelText: 'Department', border: OutlineInputBorder()),
                  items: _departments.map((String value) {
                    return DropdownMenuItem<String>(
                        value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) =>
                      setState(() => _selectedDepartment = newValue!),
                ),
                const SizedBox(height: 16),
                if (_selectedRole != UserRole.admin)
                  TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                        labelText: 'Admission Year',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_selectedRole != UserRole.admin && value!.isEmpty) {
                        return 'Please enter your admission year';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),
                if (_selectedRole != UserRole.admin)
                  ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                            color: _capturedEmbeddings.isNotEmpty
                                ? Colors.green
                                : Colors.grey)),
                    leading: Icon(
                      Icons.face_retouching_natural,
                      color: _capturedEmbeddings.isNotEmpty
                          ? Colors.green
                          : Theme.of(context).primaryColor,
                    ),
                    title: const Text('Face Enrollment'),
                    subtitle: Text(
                      _capturedEmbeddings.isNotEmpty
                          ? '${_capturedEmbeddings.length} faces captured - Complete'
                          : 'Required for attendance',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _captureFaceEmbeddings,
                  ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _performSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Sign Up',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}