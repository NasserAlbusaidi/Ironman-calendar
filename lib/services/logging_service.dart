import 'package:logging/logging.dart';

/// A service for configuring and providing a centralized logger.
///
/// This class ensures that all log messages are handled in a consistent
/// and structured manner. It sets up a hierarchical logger with a specified
/// log level and formats the output to include the timestamp, log level,
/// and message.
class LoggingService {
  /// The static logger instance for the application.
  static final Logger _logger = Logger('IronmanDash');

  /// Configures the logger with a specific log level and output format.
  ///
  /// This method should be called once at the application's startup to
  /// ensure that all subsequent log messages are properly handled.
  static void setup() {
    // Set the log level to show all messages
    Logger.root.level = Level.ALL;

    // Set a listener to handle log records
    Logger.root.onRecord.listen((record) {
      // Format and print the log message to the console
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  /// Returns the application's logger instance.
  ///
  /// This getter provides a convenient way to access the logger from
  /// anywhere in the application.
  static Logger get logger => _logger;
}