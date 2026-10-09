import 'dart:async';
import 'package:flutter/material.dart';

import 'screens/university_dashboard_screen.dart';
import 'services/university_service.dart';

export 'screens/university_dashboard_screen.dart';

typedef UniversityDashboardPage = UniversityDashboardScreen;

class UniversityLoginPage extends StatefulWidget {
  const UniversityLoginPage({super.key, this.onLoginSuccess});

  final VoidCallback? onLoginSuccess;

  @override
  State<UniversityLoginPage> createState() => _UniversityLoginPageState();
}

class _UniversityLoginPageState extends State<UniversityLoginPage> {
  final _service = UniversityService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _isOtpStep = false;

  Timer? _countdownTimer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _canResend = true;
        });
      }
    });
  }

  Future<void> _submitLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your university email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _service.login(email, password);
      if (!mounted) return;

      if (res['pendingUniversityOtp'] == true) {
        setState(() {
          _isOtpStep = true;
          _loading = false;
          _error = null;
        });
        _startTimer();
      } else {
        // Direct token returned (if OTP bypassed or already verified)
        _handleSuccessfulLogin();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _submitOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Please enter the 6-digit verification code.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _service.verifyLoginOtp(email, otp);
      if (!mounted) return;
      _handleSuccessfulLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _service.resendLoginOtp(_emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new verification code has been sent to your email.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleSuccessfulLogin() {
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
      Navigator.of(context).maybePop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => UniversityDashboardScreen(
            onLogout: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ),
      );
    }
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verify your university access',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Use your official university email and password to access the portal.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Official University Email',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _loading ? null : _submitLogin,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
          ),
          child: _loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Login'),
        ),
      ],
    );
  }

  Widget _buildOtpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter Verification Code',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          'A 6-digit OTP code has been sent to ${_emailController.text.trim()}. Please enter it below to verify your session.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 10,
          ),
          decoration: const InputDecoration(
            hintText: '------',
            counterText: '',
            prefixIcon: Icon(Icons.security_rounded),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _loading ? null : _submitOtp,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
          ),
          child: _loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Verify & Enter Portal'),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _canResend && !_loading ? _resendOtp : null,
              child: Text(
                _canResend ? 'Resend Code' : 'Resend in ${_secondsRemaining}s',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _canResend
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
            const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
            TextButton(
              onPressed: () => setState(() {
                _isOtpStep = false;
                _error = null;
              }),
              child: const Text('Change Email'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('University Portal Access'),
      leading: BackButton(
        onPressed: () {
          if (_isOtpStep) {
            setState(() => _isOtpStep = false);
          } else {
            Navigator.maybePop(context);
          }
        },
      ),
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: _isOtpStep ? _buildOtpForm() : _buildLoginForm(),
          ),
        ),
      ),
    ),
  );
}
