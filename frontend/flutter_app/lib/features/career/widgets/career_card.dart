import 'package:flutter/material.dart';

import '../../../models/career.dart';

/// A career summary card for the careers list (screen 08).
///
/// Shows the four things a student scans for when browsing: the job title, the
/// industry it sits in, the salary band, and how strong demand is. The whole
/// card is the tap target rather than a small chevron, which makes it
/// comfortable to hit on a phone.
class CareerCard extends StatelessWidget {
  const CareerCard({super.key, required this.career, this.onTap});

  final Career career;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      career.title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 10),
                  DemandLevelBadge(jobOutlook: career.jobOutlook),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                career.category,
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      career.salaryLabel,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coloured pill showing how strong demand is for a career.
///
/// Colour alone is never the only signal: the level is always written out, so
/// the badge still reads correctly for a colour-blind user or in greyscale.
class DemandLevelBadge extends StatelessWidget {
  const DemandLevelBadge({super.key, required this.jobOutlook});

  final String jobOutlook;

  /// Background and text colour per demand level, warmest for the strongest
  /// demand. Anything unrecognised falls back to a neutral grey.
  static const Map<String, (Color, Color)> _palette = {
    'Very High': (Color(0xFFDCFCE7), Color(0xFF15803D)),
    'High': (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    'Medium': (Color(0xFFFEF3C7), Color(0xFFB45309)),
    'Low': (Color(0xFFF1F5F9), Color(0xFF475569)),
  };

  @override
  Widget build(BuildContext context) {
    if (jobOutlook.isEmpty) return const SizedBox.shrink();

    final colours =
        _palette[jobOutlook] ?? const (Color(0xFFF1F5F9), Color(0xFF475569));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colours.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$jobOutlook demand',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colours.$2,
        ),
      ),
    );
  }
}
