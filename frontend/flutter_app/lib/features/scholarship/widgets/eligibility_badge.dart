import 'package:flutter/material.dart';

import '../models/scholarship_model.dart';

class EligibilityBadge extends StatefulWidget {
  const EligibilityBadge({
    super.key,
    required this.result,
    this.initiallyExpanded = false,
  });

  final EligibilityCheckResult result;
  final bool initiallyExpanded;

  @override
  State<EligibilityBadge> createState() => _EligibilityBadgeState();
}

class _EligibilityBadgeState extends State<EligibilityBadge> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.result;
    final isEligible = res.isEligible;

    final bgColor = isEligible
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFFFBEB);
    final borderColor = isEligible
        ? const Color(0xFFA7F3D0)
        : const Color(0xFFFDE68A);
    final textColor = isEligible
        ? const Color(0xFF065F46)
        : const Color(0xFF92400E);
    final iconColor = isEligible
        ? const Color(0xFF059669)
        : const Color(0xFFD97706);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isEligible
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEligible
                          ? '✓ You appear to meet the academic eligibility requirements.'
                          : '⚠ You may not meet all academic eligibility requirements.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Eligibility guidance is derived from your profile. Final evaluation rests with the university.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0x33000000)),
            const SizedBox(height: 10),
            if (res.matchedCriteria.isNotEmpty) ...[
              const Text(
                'Matched Requirements:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF047857),
                ),
              ),
              const SizedBox(height: 4),
              ...res.matchedCriteria.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          c,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (res.unmetCriteria.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text(
                'Unmet or Missing Criteria:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(height: 4),
              ...res.unmetCriteria.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          c,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
