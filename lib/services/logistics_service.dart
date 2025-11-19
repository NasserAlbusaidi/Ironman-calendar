import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'logging_service.dart';

/// A service for managing logistics tasks related to the Ironman race.
///
/// This class provides a master list of tasks and methods to retrieve and
/// manage the status of these tasks using shared preferences.
class LogisticsService {
  final Logger _logger = LoggingService.logger;
  // The Standard Ironman Protocol Checklist
  final List<Map<String, dynamic>> _masterList = [
    {'id': 'hotel', 'title': 'Book Race Hotel', 'weeksOut': 24},
    {'id': 'mechanic', 'title': 'Book Bike Mechanic Tune-up', 'weeksOut': 4},
    {'id': 'shoes', 'title': 'Buy Race Day Shoes (Break them in)', 'weeksOut': 6},
    {'id': 'nutrition_buy', 'title': 'Bulk Buy Race Nutrition (Gels/Salt)', 'weeksOut': 8},
    {'id': 'nutrition_test', 'title': 'Test Race Nutrition on Long Ride', 'weeksOut': 5},
    {'id': 'taper_start', 'title': 'Start Taper Protocol', 'weeksOut': 3},
    {'id': 'guide', 'title': 'Read Athlete Guide PDF', 'weeksOut': 2},
    {'id': 'shave', 'title': 'Leg Shave / Grooming', 'weeksOut': 0},
    {'id': 'checkin', 'title': 'Athlete Check-In', 'weeksOut': 0},
  ];

  /// Retrieves a list of pending logistics tasks.
  ///
  /// This method filters the master list of tasks to only include those that
  /// have not been marked as complete. The list is then sorted by urgency.
  ///
  /// [weeksUntilRace] is the number of weeks remaining until the race.
  ///
  /// Returns a list of maps, where each map represents a pending task.
  Future<List<Map<String, dynamic>>> getPendingTasks(int weeksUntilRace) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> pending = [];

      for (var task in _masterList) {
        // Check if already done
        bool isDone = prefs.getBool('task_${task['id']}') ?? false;

        // Check if it's time to worry about this (show tasks due now or in the past)
        bool isTime = task['weeksOut'] >= weeksUntilRace;

        // For a smoother UI, let's just show everything that isn't done,
        // sorted by urgency.
        if (!isDone) {
          pending.add(task);
        }
      }

      // Sort by urgency (closest to race day first, but showing big items first)
      pending.sort((a, b) => b['weeksOut'].compareTo(a['weeksOut']));

      return pending;
    } catch (e) {
      _logger.severe('Error getting pending tasks: $e');
      return [];
    }
  }

  /// Marks a logistics task as complete.
  ///
  /// This method saves the completion status of a task to shared preferences.
  ///
  /// [id] is the ID of the task to be marked as complete.
  Future<void> markTaskComplete(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('task_$id', true);
    } catch (e) {
      _logger.severe('Error marking task as complete: $e');
    }
  }
}