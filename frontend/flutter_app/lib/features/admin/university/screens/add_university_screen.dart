import 'package:flutter/material.dart';

import '../services/university_admin_service.dart';
import '../widgets/university_form.dart';
import 'university_otp_screen.dart';

class AddUniversityScreen extends StatefulWidget {
  const AddUniversityScreen({super.key});

  @override
  State<AddUniversityScreen> createState() => _AddUniversityScreenState();
}

class _AddUniversityScreenState extends State<AddUniversityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = UniversityAdminService();
  UniversityFormData _formData = UniversityFormData();
  bool _loading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final payload = _formData.toMap(isCreating: true);
      final result = await _service.createUniversity(payload);

      if (!mounted) return;

      final universityId = (result['universityId'] ?? '').toString();
      final officialEmail =
          (result['officialEmail'] ?? _formData.officialEmail).toString();
      final universityName =
          (result['universityName'] ?? _formData.universityName).toString();
      final desiredStatus =
          (result['desiredStatus'] ?? _formData.status).toString();

      // Open OTP verification screen
      final verified = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => UniversityOtpScreen(
            universityId: universityId,
            officialEmail: officialEmail,
            universityName: universityName,
            desiredStatus: desiredStatus,
          ),
        ),
      );

      if (verified == true && mounted) {
        Navigator.pop(context, true); // Pop back to list and refresh
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '').trim();
      if (mounted) {
        setState(() {
          if (msg.toLowerCase().contains('already exists')) {
            _errorMessage = 'This university email is already registered.';
          } else if (msg.toLowerCase().contains('unable to send')) {
            _errorMessage = 'Unable to send verification code. Please check email configuration.';
          } else {
            _errorMessage = msg.isNotEmpty ? msg : 'Failed to create university.';
          }
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add University',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Register New University',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Fill in the university and representative details. A verification OTP will be sent to the university official email.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Color(0xFFDC2626), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      UniversityForm(
                        formKey: _formKey,
                        initialData: _formData,
                        isCreating: true,
                        onChanged: (data) => _formData = data,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create University',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

