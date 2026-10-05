import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onLogin,
    required this.onGoogleLogin,
    required this.onRegister,
    required this.isAdminPortal,
    required this.onAdminPortalToggle,
    this.onUniversityLogin,
  });
  final Future<void> Function(String email, String password) onLogin;
  final Future<void> Function() onGoogleLogin;
  final VoidCallback onRegister;
  final bool isAdminPortal;
  final VoidCallback onAdminPortalToggle;
  final VoidCallback? onUniversityLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onLogin(_email.text.trim(), _password.text);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSubmit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onGoogleLogin();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'Assets/logo.jpeg',
                  width: 112,
                  height: 112,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 18),
                Text(
                  widget.isAdminPortal ? 'Admin Portal' : 'Welcome back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isAdminPortal
                      ? 'Sign in with your administrator account.'
                      : 'Continue building your career path.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                Text(
                  'SIGN IN',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: TextStyle(color: Color(0xFFEF4444))),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : Text(widget.isAdminPortal ? 'Admin sign in' : 'Log in'),
                ),
                if (!widget.isAdminPortal) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _googleSubmit,
                    icon: const Icon(Icons.account_circle_outlined),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'new here?',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: widget.onRegister,
                    child: const Text('Create a student account'),
                  ),
                ],
                const SizedBox(height: 8),
                if (widget.onUniversityLogin != null) ...[
                  TextButton(
                    onPressed: _loading ? null : widget.onUniversityLogin,
                    child: const Text('University Login'),
                  ),
                ],
                TextButton.icon(
                  onPressed: _loading ? null : widget.onAdminPortalToggle,
                  icon: Icon(
                    widget.isAdminPortal
                        ? Icons.arrow_back_rounded
                        : Icons.admin_panel_settings_outlined,
                  ),
                  label: Text(
                    widget.isAdminPortal
                        ? 'Back to student sign in'
                        : 'Admin Portal',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
