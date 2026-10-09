import 'package:flutter/material.dart';

class UniversityFormData {
  UniversityFormData({
    this.universityName = '',
    this.location = '',
    this.officialEmail = '',
    this.address = '',
    this.contactNumber = '',
    this.representativeName = '',
    this.representativeEmail = '',
    this.representativeContactNumber = '',
    this.password = '',
    this.confirmPassword = '',
    this.status = 'active',
    this.universityType = 'State University',
  });

  String universityName;
  String location;
  String officialEmail;
  String address;
  String contactNumber;
  String representativeName;
  String representativeEmail;
  String representativeContactNumber;
  String password;
  String confirmPassword;
  String status;
  String universityType;

  Map<String, dynamic> toMap({bool isCreating = false}) {
    final map = <String, dynamic>{
      'universityName': universityName.trim(),
      'location': location.trim(),
      'officialEmail': officialEmail.trim(),
      'address': address.trim(),
      'contactNumber': contactNumber.trim(),
      'representativeName': representativeName.trim(),
      'representativeEmail': representativeEmail.trim(),
      'representativeContactNumber': representativeContactNumber.trim(),
      'status': status.trim().toLowerCase(),
      'universityType': universityType.trim(),
    };
    if (isCreating) {
      map['password'] = password;
      map['confirmPassword'] = confirmPassword;
    }
    return map;
  }
}

class UniversityForm extends StatefulWidget {
  const UniversityForm({
    super.key,
    required this.formKey,
    required this.initialData,
    required this.isCreating,
    required this.onChanged,
  });

  final GlobalKey<FormState> formKey;
  final UniversityFormData initialData;
  final bool isCreating;
  final ValueChanged<UniversityFormData> onChanged;

  @override
  State<UniversityForm> createState() => _UniversityFormState();
}

class _UniversityFormState extends State<UniversityForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _contactController;
  late final TextEditingController _repNameController;
  late final TextEditingController _repEmailController;
  late final TextEditingController _repContactController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late String _status;
  late String _universityType;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nameController = TextEditingController(text: d.universityName);
    _locationController = TextEditingController(text: d.location);
    _emailController = TextEditingController(text: d.officialEmail);
    _addressController = TextEditingController(text: d.address);
    _contactController = TextEditingController(text: d.contactNumber);
    _repNameController = TextEditingController(text: d.representativeName);
    _repEmailController = TextEditingController(text: d.representativeEmail);
    _repContactController = TextEditingController(
      text: d.representativeContactNumber,
    );
    _passwordController = TextEditingController(text: d.password);
    _confirmPasswordController = TextEditingController(text: d.confirmPassword);
    _status = d.status.isEmpty ? 'active' : d.status;
    _universityType = d.universityType.isEmpty
        ? 'State University'
        : d.universityType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _repNameController.dispose();
    _repEmailController.dispose();
    _repContactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged(
      UniversityFormData(
        universityName: _nameController.text,
        location: _locationController.text,
        officialEmail: _emailController.text,
        address: _addressController.text,
        contactNumber: _contactController.text,
        representativeName: _repNameController.text,
        representativeEmail: _repEmailController.text,
        representativeContactNumber: _repContactController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        status: _status,
        universityType: _universityType,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. UNIVERSITY INFORMATION
          _buildSectionHeader(
            'UNIVERSITY INFORMATION',
            Icons.account_balance_rounded,
          ),
          TextFormField(
            controller: _nameController,
            onChanged: (_) => _notifyChange(),
            decoration: const InputDecoration(
              labelText: 'University Name *',
              hintText: 'e.g. University of Colombo',
              prefixIcon: Icon(Icons.school_outlined),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'University Name is required'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            onChanged: (_) => _notifyChange(),
            decoration: const InputDecoration(
              labelText: 'University Location *',
              hintText: 'e.g. Colombo, Western Province',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'University Location is required'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            onChanged: (_) => _notifyChange(),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'University Official Email *',
              hintText: 'e.g. info@cmb.ac.lk',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'University Official Email is required';
              }
              if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            onChanged: (_) => _notifyChange(),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'University Address *',
              hintText:
                  'e.g. College House, 94 Cumaratunga Munidasa Mawatha, Colombo 03',
              prefixIcon: Icon(Icons.place_outlined),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'University Address is required'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contactController,
            onChanged: (_) => _notifyChange(),
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'University Contact Number *',
              hintText: 'e.g. +94 11 258 1835',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Contact Number is required'
                : null,
          ),

          // 2. ADMIN / REPRESENTATIVE INFORMATION
          _buildSectionHeader(
            'ADMIN / REPRESENTATIVE INFORMATION',
            Icons.person_outline_rounded,
          ),
          TextFormField(
            controller: _repNameController,
            onChanged: (_) => _notifyChange(),
            decoration: const InputDecoration(
              labelText: 'Admin/Representative Name *',
              hintText: 'e.g. Prof. H.D. Karunaratne',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Representative Name is required'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _repEmailController,
            onChanged: (_) => _notifyChange(),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Admin/Representative Email',
              hintText: 'e.g. rep@cmb.ac.lk (Optional)',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _repContactController,
            onChanged: (_) => _notifyChange(),
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Admin/Representative Contact Number *',
              hintText: 'e.g. +94 77 123 4567',
              prefixIcon: Icon(Icons.phone_iphone_outlined),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Representative Contact Number is required'
                : null,
          ),

          // 3. ACCOUNT INFORMATION (Only during account creation)
          if (widget.isCreating) ...[
            _buildSectionHeader(
              'ACCOUNT INFORMATION',
              Icons.lock_outline_rounded,
            ),
            TextFormField(
              controller: _passwordController,
              onChanged: (_) => _notifyChange(),
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password *',
                hintText: 'Minimum 6 characters',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6)
                  return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              onChanged: (_) => _notifyChange(),
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password *',
                hintText: 'Re-enter your password',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty)
                  return 'Confirm Password is required';
                if (v != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],

          // 4. ACCOUNT STATUS
          _buildSectionHeader('ACCOUNT STATUS', Icons.toggle_on_outlined),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Active')),
                  selected: _status == 'active',
                  selectedColor: const Color(0xFFDCFCE7),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _status == 'active'
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF64748B),
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _status = 'active');
                      _notifyChange();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Inactive')),
                  selected: _status == 'inactive',
                  selectedColor: const Color(0xFFFEE2E2),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _status == 'inactive'
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF64748B),
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _status = 'inactive');
                      _notifyChange();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
