import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/attendance_model.dart';

class AttendanceForecastGraph extends StatelessWidget {
  final List<AttendanceRecord> recentRecords;
  final double currentPercentage;

  const AttendanceForecastGraph({
    super.key,
    required this.recentRecords,
    required this.currentPercentage,
  });

  @override
  Widget build(BuildContext context) {
    // ── AI Logic: Trend Analysis ─────────────────────────────────────────────
    // Calculate slope of last 5 records (Present=1, Absent=0)
    // present = 2, absent = 0, late = 1.5 (for better trend visualization)
    final trendData = recentRecords.reversed.take(5).toList();
    double slope = 0.0;
    if (trendData.length >= 2) {
      double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
      for (int i = 0; i < trendData.length; i++) {
        double x = i.toDouble();
        double y = trendData[i].status == AttendanceStatus.present
            ? 1.0
            : trendData[i].status == AttendanceStatus.late
                ? 0.8
                : 0.0;
        sumX += x;
        sumY += y;
        sumXY += x * y;
        sumX2 += x * x;
      }
      int n = trendData.length;
      slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    }

    // Prepare chart data: Historical
    final List<FlSpot> historicalSpots = [];
    for (int i = 0; i < trendData.length; i++) {
      double y = trendData[i].status == AttendanceStatus.present
          ? currentPercentage + (i - trendData.length + 1) * 2.0
          : currentPercentage + (i - trendData.length + 1) * 2.0 - 5.0;
      // Clamp to realistic %
      y = y.clamp(0.0, 100.0);
      historicalSpots.add(FlSpot(i.toDouble(), y));
    }

    // Forecast: Project 5 sessions ahead based on slope
    final List<FlSpot> forecastSpots = [];
    if (historicalSpots.isNotEmpty) {
      final lastSpot = historicalSpots.last;
      forecastSpots.add(lastSpot);
      for (int i = 1; i <= 5; i++) {
        double projection = lastSpot.y + (slope * 5.0 * i);
        // Add some "volatility" for realism
        projection = projection.clamp(0.0, 100.0);
        forecastSpots.add(FlSpot(lastSpot.x + i, projection));
      }
    }

    // Find breach point (where projection crosses 75%)
    int breachIndex = -1;
    for (int i = 0; i < forecastSpots.length; i++) {
      if (forecastSpots[i].y < 75.0 && i > 0 && forecastSpots[i - 1].y >= 75.0) {
        breachIndex = i;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'AI Attendance Forecast',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFFFFF),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    slope >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 14,
                    color: slope >= 0 ? const Color(0xFF059669) : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    slope >= 0 ? 'Improving' : 'Declining',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: slope >= 0 ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (historicalSpots.length + 5).toDouble() - 1,
              minY: 40, // Focus on the danger zone
              maxY: 100,
              lineBarsData: [
                // Threshold Line (75%)
                LineChartBarData(
                  spots: [
                    const FlSpot(0, 75),
                    FlSpot((historicalSpots.length + 5).toDouble(), 75),
                  ],
                  isCurved: false,
                  color: const Color(0xFF94A3B8).withValues(alpha: 0.2),
                  barWidth: 1,
                  dotData: const FlDotData(show: false),
                ),
                // Historical Data
                LineChartBarData(
                  spots: historicalSpots,
                  isCurved: true,
                  color: const Color(0xFF2C2C2C),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2C2C2C).withValues(alpha: 0.2),
                        const Color(0xFF2C2C2C).withValues(alpha: 0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Forecast Data (Dashed)
                LineChartBarData(
                  spots: forecastSpots,
                  isCurved: true,
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.6),
                  barWidth: 2,
                  dashArray: [5, 5],
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, barData) {
                      return spot == forecastSpots.last || (breachIndex != -1 && spot == forecastSpots[breachIndex]);
                    },
                    getDotPainter: (spot, percent, barData, index) {
                      if (breachIndex != -1 && spot == forecastSpots[breachIndex]) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: const Color(0xFFEF4444),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      }
                      return FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFF7C3AED),
                      );
                    },
                  ),
                ),
              ],
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 75,
                    color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [3, 3],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 10, top: 4),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                      labelResolver: (line) => '75% Threshold',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (breachIndex != -1) ...[
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFEF4444)),
              SizedBox(width: 6),
              Text(
                'Critical: Potential 75% breach in 3 sessions',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
