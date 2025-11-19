import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A widget that displays a line chart of the training volume over time.
///
/// This chart visualizes the build and taper phases of the training plan,
/// showing the weekly volume in hours.
class TaperChart extends StatelessWidget {
  /// The schedule of planned workouts.
  final List<Map<String, dynamic>> schedule;

  const TaperChart({Key? key, required this.schedule}) : super(key: key);

  /// Builds the taper chart widget.
  ///
  /// [context] is the build context for this widget.
  @override
  Widget build(BuildContext context) {
    // 1. Group minutes by Week
    List<double> weeklyVolume = _calculateWeeklyVolume();
    double maxVolume = weeklyVolume.reduce((curr, next) => curr > next ? curr : next);

    return Container(
      height: 180,
      padding: EdgeInsets.fromLTRB(10, 20, 20, 0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10.0, bottom: 10),
            child: Text("THE BUILD & TAPER", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5)),
          ),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2, // Show every 2nd week
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < weeklyVolume.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "W${index + 1}",
                              style: TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklyVolume.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value);
                    }).toList(),
                    isCurved: true,
                    color: Colors.redAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.redAccent.withOpacity(0.2), // The "Blood" fill
                    ),
                  ),
                ],
                // Add the "You Are Here" Marker
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    VerticalLine(
                      x: _getCurrentWeekIndex(), 
                      color: Colors.white, 
                      strokeWidth: 1, 
                      dashArray: [5, 5],
                      label: VerticalLineLabel(show: true, labelResolver: (_) => " NOW", style: TextStyle(color: Colors.white, fontSize: 10))
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calculates the index of the current week in the training plan.
  ///
  /// Returns the week index as a double.
  double _getCurrentWeekIndex() {
    if (schedule.isEmpty) return 0;
    DateTime start = schedule.first['date'];
    int daysDiff = DateTime.now().difference(start).inDays;
    return (daysDiff / 7).clamp(0, 20).toDouble();
  }

  /// Calculates the total weekly training volume from the schedule.
  ///
  /// Returns a list of doubles, where each value is the total planned
  /// training hours for a week.
  List<double> _calculateWeeklyVolume() {
    if (schedule.isEmpty) return [];
    
    // Find start date (Earliest date in plan)
    DateTime start = schedule.first['date'];
    DateTime end = schedule.last['date'];
    int totalWeeks = end.difference(start).inDays ~/ 7 + 1;
    
    List<double> weeks = List.filled(totalWeeks, 0.0);

    for (var item in schedule) {
      int minutes = item['planned'];
      int dayOffset = item['date'].difference(start).inDays;
      if (dayOffset >= 0) {
        int weekIndex = dayOffset ~/ 7;
        if (weekIndex < totalWeeks) {
          weeks[weekIndex] += minutes.toDouble() / 60; // Convert to Hours
        }
      }
    }
    return weeks;
  }
}