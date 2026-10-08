import 'package:flutter/material.dart';

import '../models/admin_university_model.dart';
import '../services/university_admin_service.dart';
import '../widgets/university_form.dart';

class EditUniversityScreen extends StatefulWidget {
  const EditUniversityScreen({
    super.key,
    required this.university,
  });

  final AdminUniversityModel university;

  @override
  State<EditUniversityScreen> createState() => _EditUniversityScreenState();
}

class _EditUniversityScreenState extends State<EditUniversityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = UniversityAdminService();

  late UniversityFormData _formData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final u = widget.university;
    _formData = UniversityFormData(
      universityName: u.universityName,
      location: u.location,
      officialEmail: u.officialEmail,
      address: u.address,
      contactNumber: u.contactNumber,
      representativeName: u.representativeName,
      representativeEmail: u.representativeEmail ?? '',
      representativeContactNumber: u.representativeContactNumber,
      status: u.status,
      universityType: u.universityType ?? 'State University',
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = _formData.toMap(isCreating: false);
      await _service.updateUniversity(widget.university.id, payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('University updated successfully.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Edit University',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UniversityForm(
                formKey: _formKey,
                initialData: _formData,
                isCreating: false,
                onChanged: (data) => _formData = data,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  _isLoading ? 'Updating...' : 'Save Changes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

