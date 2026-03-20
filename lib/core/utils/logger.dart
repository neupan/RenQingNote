import 'dart:developer' as dev;

class AppLogger {
  static void db(String message) => dev.log(message, name: 'DB');
  static void provider(String message) => dev.log(message, name: 'Provider');
  static void ui(String message) => dev.log(message, name: 'UI');
  static void auth(String message) => dev.log(message, name: 'Auth');
  static void backup(String message) => dev.log(message, name: 'Backup');
  static void error(String message, [Object? error, StackTrace? stack]) =>
      dev.log(message, name: 'ERROR', error: error, stackTrace: stack);
}
