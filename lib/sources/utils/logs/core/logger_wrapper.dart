typedef LogFunction = void Function(Object obj, {StackTrace? stackTrace});

class LoggerWrapper {
  LogFunction debug;
  LogFunction error;
  LoggerWrapper({
    required this.debug,
    required this.error,
  });
}
