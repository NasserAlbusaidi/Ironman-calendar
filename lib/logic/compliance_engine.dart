class ComplianceEngine {
  // Returns a list merging Plan + Actuals
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

  String _getStatus(int planned, int actual) {
    if (planned == 0) return 'Rest Day';
    if (actual >= planned * 0.9) return 'Success'; // 90% compliance is good
    if (actual > 0) return 'Partial';
    return 'Missed'; // PANIC MODE
  }
  
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}