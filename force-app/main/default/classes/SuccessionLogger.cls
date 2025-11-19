/**
 * @description Utility class for standardized logging across the application.
 * Replaces ad-hoc System.debug calls with a structured approach.
 * Supports different log levels and future extensibility (e.g., Platform Events).
 *
 * @author Estate Administration Team
 * @date 2025-11-18
 */
public with sharing class SuccessionLogger {
  public enum Level {
    ERROR,
    WARN,
    INFO,
    DEBUG
  }

  /**
   * @description Log a debug message
   * @param message The message to log
   */
  public static void debug(String message) {
    log(Level.DEBUG, message);
  }

  /**
   * @description Log an info message
   * @param message The message to log
   */
  public static void info(String message) {
    log(Level.INFO, message);
  }

  /**
   * @description Log a warning message
   * @param message The message to log
   */
  public static void warn(String message) {
    log(Level.WARN, message);
  }

  /**
   * @description Log an error message
   * @param message The message to log
   */
  public static void error(String message) {
    log(Level.ERROR, message);
  }

  /**
   * @description Log an exception with a custom message
   * @param message Context message
   * @param e The exception to log
   */
  public static void error(String message, Exception e) {
    String fullMessage =
      message +
      ' | Exception: ' +
      e.getMessage() +
      ' | Stack Trace: ' +
      e.getStackTraceString();
    log(Level.ERROR, fullMessage);
  }

  /**
   * @description Internal log handler. Currently wraps System.debug but designed for extension.
   * @param level Log level
   * @param message Message content
   */
  private static void log(Level level, String message) {
    // Map internal levels to System.LoggingLevel
    LoggingLevel systemLevel = LoggingLevel.DEBUG;
    String prefix = '[SUCCESSION] ';

    switch on level {
      when ERROR {
        systemLevel = LoggingLevel.ERROR;
        prefix += '[ERROR] ';
      }
      when WARN {
        systemLevel = LoggingLevel.WARN;
        prefix += '[WARN] ';
      }
      when INFO {
        systemLevel = LoggingLevel.INFO;
        prefix += '[INFO] ';
      }
      when DEBUG {
        systemLevel = LoggingLevel.DEBUG;
        prefix += '[DEBUG] ';
      }
    }

    System.debug(systemLevel, prefix + message);
  }
}
