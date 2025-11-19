/// A class to process and merge training plan data with actual workout data.
class ComplianceEngine {
  /// Merges the planned workouts with actual activities to create a unified
  /// dashboard view.
  ///
  /// This method iterates through the planned workouts, finds the corresponding
  /// actual activity for the same day and type, and calculates the compliance
  /// status and any deficit.
  ///
  /// [plan] is a list of planned workouts.
  /// [actuals] is a list of actual activities.
  ///
  /// Returns a list of maps, where each map represents a workout with both
  /// planned and actual data.
  List<Map<String, dynamic>> mergeData(List plan, List actuals) {
    List<Map<String, dynamic>> dashboard = [];

    for (var plannedWorkout in plan) {
      DateTime pDate = plannedWorkout['date'];
      
      // Find if we did a workout on this day of the same type
      var matchingActual = actuals.firstWhere(
        (act) => 
          isSameDay(act['date'], pDate) && 
          act['type'] == plannedWorkout['type'],
        orElse: () => null,
      );

      int planned = plannedWorkout['plannedMinutes'];
      int actual = matchingActual != null ? matchingActual['actualMinutes'] : 0;
      int deficit = planned - actual;

      dashboard.add({
        'date': pDate,
        'type': plannedWorkout['type'],
        'planned': planned,
        'actual': actual,
        'status': _getStatus(planned, actual),
        'deficit': deficit > 0 ? deficit : 0, // Debt calculation
      });
    }
    return dashboard;
  }

  /// Determines the status of a workout based on planned vs. actual minutes.
  ///
  /// [planned] is the planned duration of the workout in minutes.
  /// [actual] is the actual duration of the workout in minutes.
  ///
  /// Returns a string representing the workout status.
  String _getStatus(int planned, int actual) {
    if (planned == 0) return 'Rest Day';
    if (actual >= planned * 0.9) return 'Success'; // 90% compliance is good
    if (actual > 0) return 'Partial';
    return 'Missed'; // PANIC MODE
  }
  
  /// Checks if two [DateTime] objects represent the same day.
  ///
  /// [a] is the first [DateTime].
  /// [b] is the second [DateTime].
  ///
  /// Returns `true` if they are on the same day, `false` otherwise.
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}