// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'core/core_tag.dart';
import 'core/log.dart';
import 'core/logger_wrapper.dart';

class TagsConfig extends BaseConfig {
  TagsConfig._();
  factory TagsConfig() => TagsConfig._();
  List<String> excludePaths = [
    // "package:mt_log/src",
  ];

  static const String tagIndicator = "tagIndicator";
  static const String tagActivity = "tagActivity";
  static const String tagPixel = "tagPixel";
  static const String tagChangeDimension = "tagChangeDimension";
  static const String tagBuildPhaseStatus = "tagBuildPhaseStatus";
  static const String tagUnnormal = "tagUnnormal"; // 比较少见的意外情况
  static const String tagTestMicroQues = "tagTestMicroQues"; // 验证任务（和request同步异步无关）完成completer实际添加了微任务来执行，loading到loaed过程
  static const String tagShouldRejectBallistic = "tagShouldRejectBallistic";
  static const String tagNeedCorrectPixels = "tagNeedCorrectPixels";
  static const String tagIndicatorNotifer = " tagIndicatorNotifer";
  static const String tagOnPointerEvent = " tagOnPointerEvent";
  static const String tagAnimationController = " tagAnimationController";
  static const String tagIndicatorShow = " tagIndicatorShow";
  @override
  bool get includeDefautTag => false;
  @override
  List<String> get tags => [
        // tagIndicator,
        // tagActivity,
        // tagPixel,
        // tagChangeDimension,
        // // tagBuildPhaseStatus,
        // tagUnnormal,
        // tagShouldRejectBallistic,
        // tagNeedCorrectPixels,
        // tagIndicatorNotifer,
        // tagOnPointerEvent,
        // tagAnimationController,
        // tagIndicatorShow,
      ];
}

class MyLog extends AbsCoreLog {
  @override
  LogBuilder generateLogbuilder() {
    return LogBuilder(
      loggerWrapperBuilder: () {
        final logConvert = LoggerWrapper(
          debug: (obj, {stackTrace}) {
            print(obj);
          },
          error: (obj, {stackTrace}) {
            print(obj);
          },
        );
        return logConvert;
      },
      tagConfigBuilder: () {
        return TagsConfig();
      },
    );
  }
}

// ignore: non_constant_identifier_names
final MixinLogCall MTLog = MyLog();
final MixinLogCall mtLog = MTLog;
