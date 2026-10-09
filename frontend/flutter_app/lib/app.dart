import 'package:flutter/material.dart';

import 'features/career/screens/career_details_page.dart';
import 'features/career/screens/career_pathway_page.dart';
import 'features/career/screens/career_recommendation_form_page.dart';
import 'features/career/screens/career_recommendation_results_page.dart';
import 'features/career/screens/careers_list_page.dart';
import 'features/chatbot/screens/chatbot_screen.dart';
import 'features/authentication/login_page.dart';
import 'features/authentication/register_page.dart';
import 'features/admin/admin_dashboard_page.dart';
import 'features/student/dashboard_page.dart';
import 'features/student/courses/course_catalog_page.dart';
import 'features/university/university_login_page.dart';
import 'features/student/personality/personality_test_page.dart';
import 'features/student/profile_page.dart';
import 'models/career.dart';
import 'models/student.dart';
import 'services/auth_service.dart';
import 'services/saved_career_service.dart';
import 'services/student_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CareerIQ',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6),
        brightness: Brightness.light,
        surface: const Color(0xFFF8FAFC),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
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
        shadowColor: Color(0x1A1F2937),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: Color(0x12E2E8F0)),
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
          side: const BorderSide(color: Color(0xFF64748B)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFF94A3B8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        floatingLabelStyle: TextStyle(
          color: Color(0xFF3B82F6),
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 32,
          height: 1.1,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1F2937),
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          height: 1.15,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1F2937),
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          height: 1.35,
          color: Color(0xFF64748B),
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
  bool _isAdmin = false;
  bool _isUniversity = false;
  bool _loading = true;
  bool _registering = false;
  bool _adminPortal = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      _token = await _auth.token();
      if (_token != null) {
        _isAdmin = await _auth.isAdmin();
        _isUniversity = await _auth.isUniversity();
        if (!_isAdmin && !_isUniversity) {
          _student = await _students.getMe(_token!);
        }
      }
    } catch (_) {
      await _auth.logout();
      _token = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _login(String email, String password) async {
    _student = await _auth.login(email, password);
    _token = await _auth.token();
    _isAdmin = await _auth.isAdmin();
    if (_adminPortal && !_isAdmin) {
      await _auth.logout();
      _student = null;
      _token = null;
      throw StateError('This account does not have administrator access.');
    }
    if (mounted) setState(() {});
  }

  Future<void> _googleLogin() async {
    _student = await _auth.googleLogin();
    _token = await _auth.token();
    _isAdmin = false;
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
    if (mounted) {
      setState(() {
        _student = null;
        _token = null;
        _isAdmin = false;
        _isUniversity = false;
      });
    }
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

  // --- Career module navigation ---

  void _openCareerDetails(BuildContext context, Career career) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CareerDetailsPage(
          token: _token!,
          careerId: career.id,
          savedCareerService: SavedCareerService(),
          onViewPathway: (loaded) => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CareerPathwayPage(career: loaded),
            ),
          ),
        ),
      ),
    );
  }

  void _openCareers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CareersListPage(
          token: _token!,
          onCareerSelected: (career) => _openCareerDetails(context, career),
        ),
      ),
    );
  }

  void _openCareerRecommendations(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CareerRecommendationFormPage(
          onSubmit: (answers) => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CareerRecommendationResultsPage(
                token: _token!,
                answers: answers,
                onCareerSelected: (career) =>
                    _openCareerDetails(context, career),
                onEditAnswers: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isAdmin && _token != null) {
      return AdminDashboardPage(onLogout: _logout);
    }
    if (_isUniversity && _token != null) {
      return UniversityDashboardScreen(onLogout: _logout);
    }
    if (_student != null && _token != null) {
      return DashboardPage(
        student: _student!,
        token: _token!,
        onLogout: _logout,
        onBrowseCareers: () => _openCareers(context),
        onCareerRecommendations: () => _openCareerRecommendations(context),
        onProfile: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfilePage(
                student: _student!,
                onSave: _saveStudent,
                onLogout: _logout,
              ),
            ),
          );
          await _refreshStudent();
        },
        onPersonalityTest: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PersonalityTestPage(
                token: _token!,
                studentId: _student!.id,
                onCompleted: _refreshStudent,
              ),
            ),
          );
          await _refreshStudent();
        },
        onCourses: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CourseCatalogPage(initialStream: _student!.stream),
            ),
          );
        },
        onChatbot: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatbotScreen(
                token: _token!,
                studentName: _student!.fullName,
              ),
            ),
          );
        },
      );
    }
    if (_registering) {
      return RegisterPage(
        onRegister: _register,
        onVerify: _verifyEmail,
        onResend: _resendVerificationEmail,
        onLogin: () => setState(() => _registering = false),
      );
    }
    return LoginPage(
      onLogin: _login,
      onGoogleLogin: _googleLogin,
      onRegister: () => setState(() => _registering = true),
      isAdminPortal: _adminPortal,
      onAdminPortalToggle: () => setState(() => _adminPortal = !_adminPortal),
      onUniversityLogin: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UniversityLoginPage(
              onLoginSuccess: () async {
                _token = await _auth.token();
                _isUniversity = await _auth.isUniversity();
                if (mounted) setState(() {});
              },
            ),
          ),
        );
      },
    );
  }
}
