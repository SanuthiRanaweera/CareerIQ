import 'package:flutter/material.dart';

import '../models/university_dashboard_data.dart';
import '../services/university_service.dart';
import '../widgets/university_status_badge.dart';
import '../../student/courses/widgets/course_details_modal.dart';
import 'edit_university_profile_screen.dart';
import 'university_courses_screen.dart';

class UniversityProfileScreen extends StatefulWidget {
  const UniversityProfileScreen({
    super.key,
    required this.initialProfile,
  });

  final UniversityProfileModel initialProfile;

  @override
  State<UniversityProfileScreen> createState() =>
      _UniversityProfileScreenState();
}

class _UniversityProfileScreenState extends State<UniversityProfileScreen> {
  final _service = UniversityService();
  late UniversityProfileModel _profile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _service.getUniversityProfile();
      if (mounted) {
        setState(() => _profile = updated);
      }
    } catch (_) {
      // Keep displaying current profile if background refresh fails
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditUniversityProfileScreen(profile: _profile),
      ),
    );
    if (updated == true && mounted) {
      await _refreshProfile();
    }
  }

  String get _initials {
    final parts = _profile.universityName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesOfferedSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school_outlined,
                        size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    const Text(
                      'COURSES OFFERED',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    '${_profile.courseCount} ${_profile.courseCount == 1 ? "Course" : "Courses"}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            if (_profile.courses.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No degree programs are currently linked to ${_profile.universityName} in MongoDB.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ..._profile.courses.take(4).map((c) {
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => showCourseDetailsModal(context, c.toCourse()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4, right: 8),
                          child: Icon(Icons.circle,
                              size: 7, color: Color(0xFF2563EB)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${c.degreeType}  •  ${c.stream}  •  ${c.durationYears.toStringAsFixed(c.durationYears == c.durationYears.roundToDouble() ? 0 : 1)} Yrs',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            size: 18, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UniversityCoursesScreen(
                        universityName: _profile.universityName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.menu_book_rounded, size: 16),
                label: Text(
                  _profile.courseCount > 4
                      ? 'View All Courses (${_profile.courseCount})'
                      : 'View Courses Directory',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String? value, {
    IconData? icon,
    bool isPrimary = false,
  }) {
    final displayValue =
        (value != null && value.trim().isNotEmpty) ? value : 'Not provided';
    final hasValue = value != null && value.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                color: hasValue
                    ? (isPrimary
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF0F172A))
                    : const Color(0xFF94A3B8),
              ),
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
          'University Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: _editProfile,
          ),
        ],
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: Color(0xFF2563EB),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header profile card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profile.universityName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _profile.universityType ?? 'State University',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            UniversityStatusBadge(
                              status: _profile.status,
                              compact: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // University Details
              _buildSection(
                'UNIVERSITY INFORMATION',
                Icons.account_balance_outlined,
                [
                  _buildInfoRow(
                    'Official Email',
                    _profile.officialEmail,
                    icon: Icons.email_outlined,
                    isPrimary: true,
                  ),
                  _buildInfoRow(
                    'Location',
                    _profile.location,
                    icon: Icons.location_on_outlined,
                  ),
                  _buildInfoRow(
                    'Address',
                    _profile.address,
                    icon: Icons.map_outlined,
                  ),
                  _buildInfoRow(
                    'Contact Number',
                    _profile.contactNumber,
                    icon: Icons.phone_outlined,
                  ),
                  _buildInfoRow(
                    'Institute Type',
                    _profile.universityType,
                    icon: Icons.category_outlined,
                  ),
                ],
              ),

              // Representative Details
              _buildSection(
                'ADMIN / REPRESENTATIVE',
                Icons.badge_outlined,
                [
                  _buildInfoRow(
                    'Name',
                    _profile.representativeName,
                    icon: Icons.person_outline,
                  ),
                  _buildInfoRow(
                    'Email',
                    _profile.representativeEmail,
                    icon: Icons.mail_outline,
                  ),
                  _buildInfoRow(
                    'Contact Number',
                    _profile.representativeContactNumber,
                    icon: Icons.phone_android_outlined,
                  ),
                ],
              ),

              // Online Presence & About
              _buildSection(
                'ABOUT & ONLINE PRESENCE',
                Icons.language_rounded,
                [
                  _buildInfoRow(
                    'Website',
                    _profile.website,
                    icon: Icons.link_rounded,
                  ),
                  _buildInfoRow(
                    'Description',
                    _profile.description,
                    icon: Icons.notes_rounded,
                  ),
                ],
              ),

              // Courses Offered
              _buildCoursesOfferedSection(),

              // Account Status & Verification
              _buildSection(
                'ACCOUNT STATUS & DATES',
                Icons.verified_user_outlined,
                [
                  _buildInfoRow(
                    'Account Status',
                    _profile.status.toUpperCase(),
                    icon: Icons.toggle_on_outlined,
                  ),
                  _buildInfoRow(
                    'Email Verified',
                    _profile.isEmailVerified ? 'Yes (Verified)' : 'Pending',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  if (_profile.createdAt != null)
                    _buildInfoRow(
                      'Registered On',
                      '${_profile.createdAt!.year}-${_profile.createdAt!.month.toString().padLeft(2, '0')}-${_profile.createdAt!.day.toString().padLeft(2, '0')}',
                      icon: Icons.calendar_today_outlined,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _editProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
