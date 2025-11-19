import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:logging/logging.dart';
import 'logging_service.dart';

/// A service for fetching and parsing the training plan from an iCalendar URL.
class PlanService {
  final Logger _logger = LoggingService.logger;
  // Your Intervals.icu URL
  final String calendarUrl = "https://intervals.icu/api/cal/i129550/96b17ae6fbd3b415.ics";

  /// Fetches the training plan from the iCalendar URL and parses it.
  ///
  /// This method makes an HTTP GET request to the `calendarUrl`, and if
  /// successful, it parses the iCalendar data into a list of workouts.
  ///
  /// Returns a list of maps, where each map represents a planned workout.
  Future<List<Map<String, dynamic>>> fetchPlan() async {
    try {
      final response = await http.get(Uri.parse(calendarUrl));

      if (response.statusCode == 200) {
        return _parseICS(response.body);
      } else {
        _logger.severe("Failed to load calendar: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      _logger.severe("Error fetching plan: $e");
      return [];
    }
  }

  List<Map<String, dynamic>> _parseICS(String icsString) {
    final iCalendar = ICalendar.fromString(icsString);
    List<Map<String, dynamic>> workouts = [];

    if (iCalendar.data == null) return [];

    for (var item in iCalendar.data) {
      // Some parsers put the event data in 'data', some is flat. 
      // We check if it's an event first.
      if (item['type'] == 'VEVENT') {
        final summary = item['summary']?.toString() ?? '';
        final description = item['description']?.toString() ?? '';
        
        // 1. FIX: Robust Date Parsing
        DateTime date = _parseIcsDate(item['dtstart']);

        // 2. FIX: robust Duration Parsing (Check Title first, then Description)
        int minutes = _parseDurationFromText(summary); 
        if (minutes == 0) minutes = _parseDurationFromText(description);

        String type = _determineType(summary);

        // Filter out rest days or empty items
        if (type != 'Rest') {
           workouts.add({
            'date': date, 
            'type': type,
            'plannedMinutes': minutes,
            'title': summary,
          });       
        }
      }
    }
    
    // Sort by date ascending
    workouts.sort((a, b) => a['date'].compareTo(b['date']));
    
    return workouts;
  }

  // --- HELPERS ---

  /// Determines the workout type from the summary string.
  ///
  /// [summary] is the summary of the iCalendar event.
  ///
  /// Returns a string representing the workout type.
  String _determineType(String summary) {
    final s = summary.toLowerCase();
    if (s.contains('swim')) return 'Swim';
    if (s.contains('ride') || s.contains('bike') || s.contains('cycle')) return 'Bike';
    if (s.contains('run')) return 'Run';
    return 'Rest';
  }

  /// Parses a date from an iCalendar date string.
  ///
  /// This method handles various date formats that may be present in the
  /// iCalendar data.
  ///
  /// [input] is the date string to be parsed.
  ///
  /// Returns a [DateTime] object.
  DateTime _parseIcsDate(dynamic input) {
    if (input == null) return DateTime.now();
    
    // If the library actually did its job and gave us a DateTime
    if (input is DateTime) return input;
    
    // THE NUCLEAR OPTION:
    // 1. Convert to string
    // 2. Regex replace: Remove everything that is NOT a number (0-9)
    String clean = input.toString().replaceAll(RegExp(r'[^0-9]'), '');
    
    // Example: " 20251223}" becomes "20251223"
    // Example: "DTSTART:20251118T060000" becomes "20251118060000"

    if (clean.length >= 8) {
      try {
        // We only care about the first 8 digits (YYYYMMDD)
        String y = clean.substring(0, 4);
        String m = clean.substring(4, 6);
        String d = clean.substring(6, 8);
        
        return DateTime.parse("$y-$m-$d");
      } catch (e) {
        _logger.warning("Date Parse Error ($input) -> Cleaned: $clean. Exception: $e");
      }
    }
    
    // Fallback if data is total garbage
    return DateTime.now(); 
  }

  /// Parses the duration of a workout from a string.
  ///
  /// This method uses regular expressions to extract the duration in minutes
  /// from various text formats.
  ///
  /// [text] is the string to be parsed.
  ///
  /// Returns the duration in minutes.
  int _parseDurationFromText(String text) {
    if (text.isEmpty) return 0;

    // Regex for "1h 30m", "90m", "1h", "1:30"
    // Look for Hours
    final hourMatch = RegExp(r'(\d+)\s?h').firstMatch(text);
    final minuteMatch = RegExp(r'(\d+)\s?m').firstMatch(text); // e.g. 45m
    final colonMatch = RegExp(r'(\d+):(\d+)').firstMatch(text); // e.g. 1:30

    int totalMinutes = 0;

    if (hourMatch != null) {
      totalMinutes += int.parse(hourMatch.group(1)!) * 60;
    }
    
    if (minuteMatch != null) {
      // Avoid double counting if we matched "1h 30m" (the 30m part)
      // This is a simple parser, might need tuning
      totalMinutes += int.parse(minuteMatch.group(1)!);
    }

    if (totalMinutes == 0 && colonMatch != null) {
      totalMinutes += int.parse(colonMatch.group(1)!) * 60;
      totalMinutes += int.parse(colonMatch.group(2)!);
    }
    
    return totalMinutes;
  }
}