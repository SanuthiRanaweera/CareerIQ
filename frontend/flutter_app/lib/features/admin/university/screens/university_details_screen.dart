import 'package:flutter/material.dart';

import '../models/admin_university_model.dart';
import '../services/university_admin_service.dart';
import '../widgets/university_status_badge.dart';
import 'edit_university_screen.dart';

class UniversityDetailsScreen extends StatefulWidget {
  const UniversityDetailsScreen({
    super.key,
    required this.university,
  });

  final AdminUniversityModel university;

  @override
  State<UniversityDetailsScreen> createState() =>
      _UniversityDetailsScreenState();
}

class _UniversityDetailsScreenState extends State<UniversityDetailsScreen> {
  late AdminUniversityModel _university;
  final _service = UniversityAdminService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _university = widget.university;
    _refreshDetails();
  }

  Future<void> _refreshDetails() async {
    try {
      final updated = await _service.getUniversityById(_university.id);
      if (mounted) setState(() => _university = updated);
    } catch (_) {}
  }

  Future<void> _toggleStatus() async {
    final newStatus = _university.isActive ? 'inactive' : 'active';
    setState(() => _loading = true);
    try {
      final updated =
          await _service.updateUniversityStatus(_university.id, newStatus);
      if (mounted) {
        setState(() => _university = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'University ${newStatus == 'active' ? 'activated' : 'deactivated'} successfully.',
            ),
            backgroundColor: newStatus == 'active'
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteUniversity() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete University?'),
        content: const Text(
          'Are you sure you want to delete this university account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _loading = true);
      try {
        await _service.deleteUniversity(_university.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('University deleted successfully.'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
          Navigator.pop(context, true); // Pop back to list and refresh
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _editUniversity() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditUniversityScreen(university: _university),
      ),
    );
    if (updated == true && mounted) {
      await _refreshDetails();
    }
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
        padding: const EdgeInsets.all(18),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Color(0xFF2563EB),
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

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final createdDateStr = _university.createdAt != null
        ? '${_university.createdAt!.year}-${_university.createdAt!.month.toString().padLeft(2, '0')}-${_university.createdAt!.day.toString().padLeft(2, '0')}'
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'University Details',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit University',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _loading ? null : _editUniversity,
          ),
          IconButton(
            tooltip: 'Delete University',
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: _loading ? null : _deleteUniversity,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Hero Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                    ),
                    color: const Color(0xFFEFF6FF),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF93C5FD)),
                            ),
                            child: Center(
                              child: Text(
                                _university.universityName.isNotEmpty
                                    ? _university.universityName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
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
                                  _university.universityName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _university.location,
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          UniversityStatusBadge(
                            status: _university.status,
                            fontSize: 12,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 1. UNIVERSITY INFORMATION
                  _buildSection(
                    'UNIVERSITY INFORMATION',
                    Icons.account_balance_rounded,
                    [
                      _buildDetailRow(
                          'University Name', _university.universityName),
                      _buildDetailRow('Location', _university.location),
                      _buildDetailRow(
                          'Official Email', _university.officialEmail),
                      _buildDetailRow('Address', _university.address),
                      _buildDetailRow(
                          'Contact Number', _university.contactNumber),
                      if (_university.universityType != null &&
                          _university.universityType!.isNotEmpty)
                        _buildDetailRow(
                            'University Type', _university.universityType!),
                      _buildDetailRow(
                          'Offered Courses',
                          '${_university.courseCount} ${_university.courseCount == 1 ? "Program" : "Programs"}',
                          icon: Icons.school_outlined),
                    ],
                  ),

                  // 2. REPRESENTATIVE INFORMATION
                  _buildSection(
                    'REPRESENTATIVE INFORMATION',
                    Icons.badge_outlined,
                    [
                      _buildDetailRow(
                          'Representative Name', _university.representativeName),
                      _buildDetailRow('Representative Email',
                          _university.representativeEmail ?? 'Not specified'),
                      _buildDetailRow('Representative Contact',
                          _university.representativeContactNumber),
                    ],
                  ),

                  // 3. ACCOUNT STATUS INFORMATION
                  _buildSection(
                    'ACCOUNT INFORMATION',
                    Icons.security_outlined,
                    [
                      _buildDetailRow('Account Status',
                          _university.isActive ? 'Active' : 'Inactive'),
                      _buildDetailRow(
                        'Email Verification Status',
                        _university.isEmailVerified ? 'Verified' : 'Pending',
                      ),
                      _buildDetailRow('Created Date', createdDateStr),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ACTIONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _toggleStatus,
                          icon: Icon(
                            _university.isActive
                                ? Icons.toggle_off_outlined
                                : Icons.toggle_on_outlined,
                            color: _university.isActive
                                ? Colors.orange
                                : const Color(0xFF16A34A),
                          ),
                          label: Text(
                            _university.isActive
                                ? 'Deactivate Account'
                                : 'Activate Account',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _editUniversity,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit University'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

