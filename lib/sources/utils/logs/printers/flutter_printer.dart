class FlutterPrinter {
  static void debug(
    Object? obj, {
    Object? tag,
    StackTrace? stackTrace,
  }) {
    // ignore: avoid_print
    print("${padString('[Tag:$tag]')} - $obj");
  }

  static String padString(String s) {
    return s.padRight(20);
  }
}
