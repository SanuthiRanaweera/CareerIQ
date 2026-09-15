import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.onRegister,
    required this.onVerify,
    required this.onResend,
    required this.onLogin,
  });
  final Future<void> Function(Map<String, dynamic> payload) onRegister;
  final Future<void> Function(String email, String otp) onVerify;
  final Future<void> Function(String email) onResend;
  final VoidCallback onLogin;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _school = TextEditingController();
  final _district = TextEditingController();
  final _year = TextEditingController();
  final _otp = TextEditingController();
  bool _loading = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _password,
      _confirm,
      _school,
      _district,
      _year,
      _otp,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.length < 6 ||
        _password.text != _confirm.text) {
      setState(
        () =>
            _error = 'Complete the fields and make sure both passwords match.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onRegister({
        'fullName': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'confirmPassword': _confirm.text,
        'school': _school.text.trim(),
        'district': _district.text.trim(),
        'alYear': int.tryParse(_year.text.trim()),
      });
      if (mounted) setState(() => _submitted = true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_otp.text.trim())) {
      setState(() => _error = 'Enter the six-digit code from Gmail.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onVerify(_email.text.trim(), _otp.text.trim());
      if (mounted) widget.onLogin();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onResend(_email.text.trim());
      if (mounted)
        setState(
          () => _error = 'A new verification code was sent to your Gmail.',
        );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create account')),
    body: _submitted
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mark_email_read_outlined,
                    size: 64,
                    color: Color(0xFF0B6E69),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Check your Gmail',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Enter the six-digit code sent to ${_email.text}.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _otp,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Email verification code',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _verify,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Verify email'),
                  ),
                  TextButton(
                    onPressed: _loading ? null : _resend,
                    child: const Text('Resend verification code'),
                  ),
                  TextButton(
                    onPressed: widget.onLogin,
                    child: const Text('Back to login'),
                  ),
                ],
              ),
            ),
          )
        : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'Assets/logo.jpeg',
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'CREATE YOUR PROFILE',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF087F78),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Start your journey',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your profile will be saved securely to CareerIQ.',
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirm,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _school,
                        decoration: const InputDecoration(labelText: 'School'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _district,
                        decoration: const InputDecoration(
                          labelText: 'District',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _year,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'A/L year',
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text('Create account'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: widget.onLogin,
                        child: const Text('Already have an account? Log in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
  );
}
