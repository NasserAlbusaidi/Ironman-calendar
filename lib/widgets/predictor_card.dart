import 'package:flutter/material.dart';

/// A widget that displays a race day simulation and predicted finish time.
///
/// This card uses the average paces from training to project the finish
/// times for the swim, bike, and run segments of the race, as well as the
/// overall finish time.
class PredictorCard extends StatelessWidget {
  /// A map of average paces for each discipline.
  ///
  /// The keys are "Swim", "Bike", and "Run", and the values are the paces
  /// in seconds per meter.
  final Map<String, double> paces; // Seconds per Meter

  const PredictorCard({Key? key, required this.paces}) : super(key: key);

  /// Builds the predictor card widget.
  ///
  /// [context] is the build context for this widget.
  @override
  Widget build(BuildContext context) {
    // Ironman Distances in Meters
    final double swimDist = 1900;
    final double bikeDist = 90000;
    final double runDist = 21086;

    // Calculate Projected Times (in Seconds)
    // If no data (pace is 0), assume a "Back of pack" pace to prevent crash
    // Swim: 2:30/100m, Bike: 20km/h, Run: 7:00/km
    int swimTime = (paces['Swim']! > 0 ? paces['Swim']! * swimDist : 5790).round();
    int bikeTime = (paces['Bike']! > 0 ? paces['Bike']! * bikeDist : 32400).round();
    int runTime  = (paces['Run']! > 0 ? paces['Run']! * runDist : 17724).round();
    
    // Transitions (Fixed 12 mins total)
    int t1t2 = 720; 

    int totalSeconds = swimTime + bikeTime + runTime + t1t2;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        // A Matrix-style Green/Black gradient
        gradient: LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 5))]
      ),
      child: Column(
        children: [
          Text("RACE DAY SIMULATION", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text(
            _formatTotal(totalSeconds), 
            style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)
          ),
          Text("PROJECTED FINISH TIME", style: TextStyle(color: Colors.white54, fontSize: 10)),
          Divider(color: Colors.white10, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _split("SWIM", swimTime, paces['Swim']!),
              _split("BIKE", bikeTime, paces['Bike']!),
              _split("RUN", runTime, paces['Run']!),
            ],
          )
        ],
      ),
    );
  }

  /// Builds a widget to display a single split time and pace.
  Widget _split(String label, int seconds, double pace) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(_formatSplit(seconds), style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 2),
        Text(_formatPace(label, pace), style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
      ],
    );
  }

  /// Formats the pace for a given discipline.
  ///
  /// [label] is the discipline ("SWIM", "BIKE", or "RUN").
  /// [pace] is the pace in seconds per meter.
  ///
  /// Returns a formatted string representing the pace.
  String _formatPace(String label, double pace) {
    // Pace is in seconds per meter
    if (pace <= 0) return "-";
    if (label == "SWIM") {
      // Convert to seconds per 100m
      double secPer100m = pace * 100;
      int min = secPer100m ~/ 60;
      int sec = (secPer100m % 60).round();
      return "$min:${sec.toString().padLeft(2, '0')}/100m";
    } else if (label == "BIKE") {
      // Convert to km/h
      double kph = 3600 / (pace * 1000);
      return "${kph.toStringAsFixed(1)} km/h";
    } else if (label == "RUN") {
      // Convert to min/km
      double secPerKm = pace * 1000;
      int min = secPerKm ~/ 60;
      int sec = (secPerKm % 60).round();
      return "$min:${sec.toString().padLeft(2, '0')}/km";
    }
    return "-";
  }

  /// Formats the total finish time.
  ///
  /// [totalSeconds] is the total time in seconds.
  ///
  /// Returns a formatted string in the format "Xh XXm".
  String _formatTotal(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    return "${h}h ${m.toString().padLeft(2, '0')}m";
  }

  /// Formats a split time.
  ///
  /// [totalSeconds] is the total time in seconds.
  ///
  /// Returns a formatted string in the format "X:XX".
  String _formatSplit(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    return "${h}:${m.toString().padLeft(2, '0')}";
  }
}