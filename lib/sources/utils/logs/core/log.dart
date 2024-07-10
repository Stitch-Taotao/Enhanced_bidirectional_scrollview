// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'logger_wrapper.dart';
import 'core_tag.dart';

typedef LogTagFunction = void Function(
  Object? obj, {
  Object? tag,
  StackTrace? stackTrace,
});
typedef LogFunction = void Function(
  String msg, {
  StackTrace? stackTrace,
});
typedef OutputFormatFunction = String Function(Object? obj, {required Object tag});

abstract mixin class MixinLogCall {
  void call(
    Object? obj, {
    Object? tag,
    StackTrace? stackTrace,
  });
}

abstract class AbsCoreLog with MixinLogCall {
  late LogBuilder logBuilder;
  OutputFormatFunction? outputFormat;
  AbsCoreLog({
    this.outputFormat,
  }) {
    updateConfig();
  }
  LogBuilder generateLogbuilder();
  late AbsMixinConfig config;
  late LoggerWrapper loggerWrapper;
  void updateConfig() {
    logBuilder = generateLogbuilder();
    config = logBuilder.tagConfigBuilder();
    loggerWrapper = logBuilder.loggerWrapperBuilder();
  }

  @override
  void call(
    Object? obj, {
    Object? tag,
    StackTrace? stackTrace,
  }) {
    debug(obj, tag: tag, stackTrace: stackTrace);
  }

  LogTagFunction get debug => (obj, {tag, stackTrace}) {
        updateConfig();
        tag ??= config.defaultTag;
        if (shouldLog(tag: tag, config: config)) {
          doDebug(_outPut(obj, tag: tag), stackTrace: stackTrace);
        }
      };
  LogFunction get doDebug => loggerWrapper.debug;
  LogTagFunction get error => (obj, {tag, stackTrace}) {
        updateConfig();
        tag ??= config.defaultTag;
        if (shouldLog(tag: tag, config: config)) {
          doError(_outPut(obj, tag: tag), stackTrace: stackTrace);
        }
      };
  LogFunction get doError => loggerWrapper.error;
  String _outPut(Object? obj, {required Object tag}) {
    String logStr = outputFormat?.call(obj, tag: tag) ?? _defaultOutPut(obj, tag: tag);
    return logStr;
  }

  String _defaultOutPut(Object? obj, {required Object tag}) {
    String logStr = '';
    logStr = '''--- TAG:<<<$tag>>> ---
$obj''';
    return logStr;
  }

  bool shouldLog({required Object tag, required AbsMixinConfig config}) {
    if (!config.enable) {
      return false;
    }
    for (var element in config.showLogTags) {
      if (element == tag) {
        return true;
      }
    }
    return false;
  }
}

typedef LoggerWrapperBuilder = LoggerWrapper Function();
typedef TagConfigBuilder = AbsMixinConfig Function();

class LogBuilder {
  LoggerWrapperBuilder loggerWrapperBuilder;
  TagConfigBuilder tagConfigBuilder;
  LogBuilder({
    required this.loggerWrapperBuilder,
    required this.tagConfigBuilder,
  });
}
