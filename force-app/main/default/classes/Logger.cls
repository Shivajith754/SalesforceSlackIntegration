public with sharing class Logger {
    public enum LogLevel { DEBUG, INFO, WARN, ERROR }

    public static void log(LogLevel level, String message) {
        String logMessage = '[' + level.name() + '] ' + message;
        System.debug(logMessage);
    }

    public static void debug(String message) {
        log(LogLevel.DEBUG, message);
    }

    public static void info(String message) {
        log(LogLevel.INFO, message);
    }

    public static void warn(String message) {
        log(LogLevel.WARN, message);
    }

    public static void error(String message) {
        log(LogLevel.ERROR, message);
    }
}
