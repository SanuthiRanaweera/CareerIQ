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
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF087F78),
        brightness: Brightness.light,
        surface: const Color(0xFFF4FAF8),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF4FAF8),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Color(0x220D3734),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: Color(0x0F0D3734)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          side: const BorderSide(color: Color(0xFF52706D)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFE9F1EF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0x2452706D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFF087F78), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        floatingLabelStyle: TextStyle(
          color: Color(0xFF087F78),
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 32,
          height: 1.1,
          fontWeight: FontWeight.w800,
          color: Color(0xFF142322),
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          height: 1.15,
          fontWeight: FontWeight.w800,
          color: Color(0xFF142322),
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF142322),
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          height: 1.35,
          color: Color(0xFF405451),
        ),
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
