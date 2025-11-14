import 'package:logger/logger.dart';

class LoggerService {
  static late Logger _logger;
  
  static void init() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
  }
  
  static void debug(String message, [dynamic error]) {
    _logger.d(message, error: error);
  }
  
  static void info(String message, [dynamic error]) {
    _logger.i(message, error: error);
  }
  
  static void warning(String message, [dynamic error]) {
    _logger.w(message, error: error);
  }
  
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}