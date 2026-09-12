import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.onRegister, required this.onLogin});
  final Future<void> Function(Map<String, dynamic> payload) onRegister;
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
  bool _loading = false;
  String? _error;

  @override
  void dispose() { for (final controller in [_name, _email, _password, _confirm, _school, _district, _year]) { controller.dispose(); } super.dispose(); }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty || _password.text.length < 6 || _password.text != _confirm.text) {
      setState(() => _error = 'Complete the fields and make sure both passwords match.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await widget.onRegister({'fullName': _name.text.trim(), 'email': _email.text.trim(), 'password': _password.text, 'confirmPassword': _confirm.text, 'school': _school.text.trim(), 'district': _district.text.trim(), 'alYear': int.tryParse(_year.text.trim())});
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create account')),
        body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Start your journey', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), const Text('Your profile will be saved securely to CareerIQ.'), const SizedBox(height: 24),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')), const SizedBox(height: 12),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')), const SizedBox(height: 12),
          TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')), const SizedBox(height: 12),
          TextField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')), const SizedBox(height: 12),
          TextField(controller: _school, decoration: const InputDecoration(labelText: 'School')), const SizedBox(height: 12),
          TextField(controller: _district, decoration: const InputDecoration(labelText: 'District')), const SizedBox(height: 12),
          TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'A/L year')), 
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red))], const SizedBox(height: 22),
          FilledButton(onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator() : const Text('Create account')), const SizedBox(height: 8),
          TextButton(onPressed: widget.onLogin, child: const Text('Already have an account? Log in')),
        ]))))));
}
