import 'package:flutter/material.dart';

import '../models/university_dashboard_data.dart';
import '../services/university_service.dart';

class EditUniversityProfileScreen extends StatefulWidget {
  const EditUniversityProfileScreen({super.key, required this.profile});

  final UniversityProfileModel profile;

  @override
  State<EditUniversityProfileScreen> createState() =>
      _EditUniversityProfileScreenState();
}

class _EditUniversityProfileScreenState
    extends State<EditUniversityProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = UniversityService();

  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _addressController;
  late final TextEditingController _contactController;
  late final TextEditingController _repNameController;
  late final TextEditingController _repEmailController;
  late final TextEditingController _repContactController;
  late final TextEditingController _websiteController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _logoController;

  late String _universityType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p.universityName);
    _locationController = TextEditingController(text: p.location);
    _addressController = TextEditingController(text: p.address);
    _contactController = TextEditingController(text: p.contactNumber);
    _repNameController = TextEditingController(text: p.representativeName);
    _repEmailController = TextEditingController(
      text: p.representativeEmail ?? '',
    );
    _repContactController = TextEditingController(
      text: p.representativeContactNumber,
    );
    _websiteController = TextEditingController(text: p.website ?? '');
    _descriptionController = TextEditingController(text: p.description ?? '');
    _logoController = TextEditingController(text: p.logo ?? '');
    _universityType = p.universityType ?? 'State University';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _repNameController.dispose();
    _repEmailController.dispose();
    _repContactController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final payload = <String, dynamic>{
        'universityName': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'address': _addressController.text.trim(),
        'contactNumber': _contactController.text.trim(),
        'representativeName': _repNameController.text.trim(),
        'representativeEmail': _repEmailController.text.trim(),
        'representativeContactNumber': _repContactController.text.trim(),
        'universityType': _universityType,
        'website': _websiteController.text.trim(),
        'description': _descriptionController.text.trim(),
        'logo': _logoController.text.trim(),
      };

      await _service.updateUniversityProfile(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('University profile updated successfully.'),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Read-only Official Email notice
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Official Email (Read-only)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.profile.officialEmail,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Managed by CareerIQ Administrator.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                _buildSectionHeader(
                  'UNIVERSITY INFORMATION',
                  Icons.account_balance_outlined,
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'University Name *',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'University Name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location / City *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Location is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Full Address *',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Address is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'University Contact Number *',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Contact Number is required'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _universityType,
                  decoration: const InputDecoration(
                    labelText: 'University Type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'State University',
                      child: Text('State University'),
                    ),
                    DropdownMenuItem(
                      value: 'Non-State University',
                      child: Text('Non-State University'),
                    ),
                    DropdownMenuItem(
                      value: 'Foreign Affiliated',
                      child: Text('Foreign Affiliated'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _universityType = v);
                  },
                ),

                _buildSectionHeader(
                  'REPRESENTATIVE INFORMATION',
                  Icons.badge_outlined,
                ),
                TextFormField(
                  controller: _repNameController,
                  decoration: const InputDecoration(
                    labelText: 'Representative Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Representative Name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _repEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Representative Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _repContactController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Representative Contact Number *',
                    prefixIcon: Icon(Icons.phone_android_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Representative Contact is required'
                      : null,
                ),

                _buildSectionHeader(
                  'ONLINE PRESENCE & ABOUT',
                  Icons.language_outlined,
                ),
                TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Official Website (e.g. www.university.lk)',
                    prefixIcon: Icon(Icons.language_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'About / Description',
                    hintText: 'Brief overview of your university...',
                  ),
                ),

                const SizedBox(height: 28),
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
                      : const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 20,
                        ),
                  label: Text(
                    _isLoading ? 'Saving...' : 'Save Profile Changes',
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
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
