// // ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'package:mt_log/mt_log.dart';
// import 'package:mt_log/src/core/internal/logger_wrapper.dart';

// class LogUtil {
//   List<String> excludePaths;

//   LogUtil({
//     this.excludePaths = const [],
//   }) {
//     log = MTLogImpl(
//       configFunc: () {
//         final config = TagsConfig();
//         return LogImplLoggerConfig(
//           tagsConfig: config,
//           enable: true,
//           excludePaths: [...excludePaths, ...config.excludePaths],
//         );
//       },
//     );
//   }

//   late MTLogImpl log;
// }

// class TagsConfig extends BaseTagsConfig {
//   TagsConfig._();

//   factory TagsConfig() => TagsConfig._();
//   List<String> excludePaths = [
//     // "package:mt_log/src",
//   ];

//   static const String tagIndicator = "tagIndicator";
//   static const String tagActivity = "tagActivity";
//   static const String tagPixel = "tagPixel";
//   static const String tagChangeDimension = "tagChangeDimension";
//   static const String tagBuildPhaseStatus = "tagBuildPhaseStatus";
//   static const String tagUnnormal = "tagUnnormal"; // 比较少见的意外情况
//   static const String tagTestMicroQues =
//       "tagTestMicroQues"; // 验证任务（和request同步异步无关）完成completer实际添加了微任务来执行，loading到loaed过程
//   static const String tagShouldRejectBallistic = "tagShouldRejectBallistic";
//   static const String tagNeedCorrectPixels = "tagNeedCorrectPixels";
//   static const String tagIndicatorNotifer = " tagIndicatorNotifer";
//   static const String tagOnPointerEvent = " tagOnPointerEvent";
//   static const String tagAnimationController = " tagAnimationController";
//   static const String tagIndicatorShow = " tagIndicatorShow";
//   @override
//   bool get includeDefautTag => false;
//   @override
//   List<String> get tags => [
//         // tagIndicator,
//         // tagActivity,
//         // tagPixel,
//         // tagChangeDimension,
//         // // tagBuildPhaseStatus,
//         // tagUnnormal,
//         // tagShouldRejectBallistic,
//         // tagNeedCorrectPixels,
//         tagIndicatorNotifer,
//         // tagOnPointerEvent,
//         // tagAnimationController,
//         tagIndicatorShow,
//       ];
// }

// typedef LogFunction = void Function(
//   Object? obj, {
//   Object? tag,
//   StackTrace? stackTrace,
// });
// // final mtLog = LoggerPrinter.debug;
// // ignore: prefer_const_declarations
// final LogFunction mtLog = LogUtil2().log.debug;
// // ignore: non_constant_identifier_names
// final LogFunction MTLog = mtLog;
// final LogFunction mtError = LogUtil().log.error;
// // ignore: non_constant_identifier_names
// final LogFunction MTError = mtError;

// class LogUtil2 {
//   LogUtil2() {
//     log = MTLogImpl(
//       configFunc: () {
//         final config = TagsConfig();
//         return FlutterPrinter(tagsConfig: config, enable: true);
//       },
//     );
//   }

//   late MTLogImpl log;
// }

// class FlutterPrinter extends AbsLogConfig {
//   FlutterPrinter({required super.tagsConfig, required super.enable}) {
//     _loggerWrapper = LoggerWrapper(
//       debug: (obj, {stackTrace}) {
//         debug(obj, stackTrace: stackTrace);
//       },
//       error: (obj, {stackTrace}) {
//         debug(obj, stackTrace: stackTrace);
//       },
//     );
//   }

//   void debug(
//     Object? obj, {
//     Object? tag,
//     StackTrace? stackTrace,
//   }) {
//     mtLog("$obj");
//   }

//   static String padString(String s) {
//     return s.padRight(20);
//   }

//   late LoggerWrapper _loggerWrapper;

//   @override
//   LoggerWrapper get logConvert => _loggerWrapper;
// }

// class LoggerPrinter {
//   static final debug = LogUtil().log.debug;
// }
