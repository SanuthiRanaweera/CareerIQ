import 'dart:math';
import 'package:flutter/material.dart';
import '../models/university_analytics_model.dart';

class AnalyticsTrendBarChart extends StatefulWidget {
  const AnalyticsTrendBarChart({
    super.key,
    required this.title,
    required this.points,
    this.barColor = const Color(0xFF2563EB),
    this.subtitle,
    this.metricLabel = 'views',
  });

  final String title;
  final List<DailyTrendPoint> points;
  final Color barColor;
  final String? subtitle;
  final String metricLabel;

  @override
  State<AnalyticsTrendBarChart> createState() => _AnalyticsTrendBarChartState();
}

class _AnalyticsTrendBarChartState extends State<AnalyticsTrendBarChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final hasData = widget.points.any((p) => p.count > 0);

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
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
                if (hasData)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.barColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.points.fold<int>(0, (sum, p) => sum + p.count)} total',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: widget.barColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (!hasData)
              Container(
                height: 160,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 36,
                      color: const Color(0xFF94A3B8).withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Not enough data yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Activity trends will display as students interact.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildChartBars(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartBars() {
    // For readability on mobile, take at most 14 points, or sample evenly if points > 14
    List<DailyTrendPoint> displayPoints = widget.points;
    if (displayPoints.length > 14) {
      // Sample down or show last 14
      displayPoints = displayPoints.sublist(displayPoints.length - 14);
    }

    final maxVal = max(
      1,
      displayPoints.fold<int>(0, (m, p) => max(m, p.count)),
    );

    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(displayPoints.length, (idx) {
          final p = displayPoints[idx];
          final heightFactor = p.count / maxVal;
          final isSelected = _hoveredIndex == idx;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _hoveredIndex = _hoveredIndex == idx ? null : idx;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Tooltip / value above bar
                    if (isSelected || (p.count > 0 && displayPoints.length <= 7))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0F172A)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${p.count}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF475569),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 18),
                    // Bar
                    Container(
                      height: max(6.0, 110.0 * heightFactor),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isSelected
                              ? [
                                  widget.barColor,
                                  widget.barColor.withValues(alpha: 0.8),
                                ]
                              : [
                                  widget.barColor.withValues(alpha: 0.85),
                                  widget.barColor.withValues(alpha: 0.4),
                                ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // X-axis label
                    Text(
                      displayPoints.length <= 7 ? p.dayOfWeek : p.label.split(' ').last,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? widget.barColor
                            : const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

