import 'package:flutter/material.dart';

import 'features/authentication/login_page.dart';
import 'features/authentication/register_page.dart';
import 'features/student/dashboard_page.dart';
import 'features/student/profile_page.dart';
import 'models/student.dart';
import 'services/auth_service.dart';
import 'services/student_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CareerIQ',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E69)),
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
    ),
    home: const AuthGate(),
  );
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = AuthService();
  final _students = StudentService();
  Student? _student;
  String? _token;
  bool _loading = true;
  bool _registering = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      _token = await _auth.token();
      if (_token != null) _student = await _students.getMe(_token!);
    } catch (_) {
      await _auth.logout();
      _token = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _login(String email, String password) async {
    _student = await _auth.login(email, password);
    _token = await _auth.token();
    if (mounted) setState(() {});
  }

  Future<void> _googleLogin() async {
    _student = await _auth.googleLogin();
    _token = await _auth.token();
    if (mounted) setState(() {});
  }

  Future<void> _register(Map<String, dynamic> payload) async =>
      _auth.register(payload);

  Future<void> _verifyEmail(String email, String otp) async =>
      _auth.verifyEmail(email, otp);

  Future<void> _resendVerificationEmail(String email) async =>
      _auth.resendVerificationEmail(email);

  Future<void> _logout() async {
    await _auth.logout();
    if (mounted)
      setState(() {
        _student = null;
        _token = null;
      });
  }

  Future<void> _refreshStudent() async {
    if (_token == null) return;
    _student = await _students.getMe(_token!);
    if (mounted) setState(() {});
  }

  Future<void> _saveStudent(Student student) async {
    if (_token == null) return;
    _student = await _students.update(_token!, student);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_student != null && _token != null) {
      return DashboardPage(
        student: _student!,
        onLogout: _logout,
        onProfile: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProfilePage(student: _student!, onSave: _saveStudent),
            ),
          );
          await _refreshStudent();
        },
      );
    }
    if (_registering)
      return RegisterPage(
        onRegister: _register,
        onVerify: _verifyEmail,
        onResend: _resendVerificationEmail,
        onLogin: () => setState(() => _registering = false),
      );
    return LoginPage(
      onLogin: _login,
      onGoogleLogin: _googleLogin,
      onRegister: () => setState(() => _registering = true),
    );
  }
}
