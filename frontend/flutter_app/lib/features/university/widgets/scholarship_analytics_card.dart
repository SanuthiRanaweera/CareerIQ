import 'package:flutter/material.dart';
import '../models/university_analytics_model.dart';

class ScholarshipAnalyticsCard extends StatelessWidget {
  const ScholarshipAnalyticsCard({
    super.key,
    required this.scholarshipsData,
    required this.applicationStatus,
  });

  final ScholarshipsAnalyticsData scholarshipsData;
  final ApplicationStatusData applicationStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scholarship Performance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${scholarshipsData.total} Total (${scholarshipsData.active} Active)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${scholarshipsData.applications} Apps',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Application Status Breakdown
            const Text(
              'Application Status',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 10),
            _buildStatusBars(context),

            const SizedBox(height: 20),
            const Divider(color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // Top Scholarships by Applications
            const Text(
              'Most Applied Scholarships',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 10),
            if (scholarshipsData.performance.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No scholarship applications recorded yet',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              )
            else
              Column(
                children: scholarshipsData.performance.map((s) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                s.scholarshipType,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${s.applications} apps',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBars(BuildContext context) {
    final total = applicationStatus.total;

    return Column(
      children: [
        // Multi-segment progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: total == 0
                ? Container(color: const Color(0xFFE2E8F0))
                : Row(
                    children: [
                      if (applicationStatus.pending > 0)
                        Expanded(
                          flex: applicationStatus.pending,
                          child: Container(color: const Color(0xFFF59E0B)),
                        ),
                      if (applicationStatus.underReview > 0)
                        Expanded(
                          flex: applicationStatus.underReview,
                          child: Container(color: const Color(0xFF3B82F6)),
                        ),
                      if (applicationStatus.shortlisted > 0)
                        Expanded(
                          flex: applicationStatus.shortlisted,
                          child: Container(color: const Color(0xFF8B5CF6)),
                        ),
                      if (applicationStatus.approved > 0)
                        Expanded(
                          flex: applicationStatus.approved,
                          child: Container(color: const Color(0xFF10B981)),
                        ),
                      if (applicationStatus.rejected > 0)
                        Expanded(
                          flex: applicationStatus.rejected,
                          child: Container(color: const Color(0xFFEF4444)),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        // Status chips
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildStatusBadge('Pending', applicationStatus.pending, const Color(0xFFF59E0B)),
            _buildStatusBadge('Under Review', applicationStatus.underReview, const Color(0xFF3B82F6)),
            _buildStatusBadge('Shortlisted', applicationStatus.shortlisted, const Color(0xFF8B5CF6)),
            _buildStatusBadge('Approved', applicationStatus.approved, const Color(0xFF10B981)),
            _buildStatusBadge('Rejected', applicationStatus.rejected, const Color(0xFFEF4444)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

