// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bidirectional_load_scrollview/sources/utils/logs/log_config.dart';
import 'package:flutter/material.dart';

import '../../task/load_trigger.dart';
import '../../task/tasks.dart';
import '../../utils/frame_util.dart';
import '../indicator.dart';
import '../indicator_task_manager.dart';

class MTAutoIndicator<T extends Object> extends MTIndicator with BuilderMixin, PixelAwareMixin {
  final LoadTrigger loadTrigger;
  MTProcessingManager processManager;
  Widget? Function(BuildContext context,MTAutoIndicator indicator)? builder;
  MTAutoIndicator({
    required this.loadTrigger,
    required this.processManager,
    required this.isHeader,
    this.builder,
  });

  void beginLoading() {
    mtLog("触发加载：${FrameUtil.debugFrameCount} ${FrameUtil.debugPhase}",tag:TagsConfig.tagSyncAutoFrame);
    assert(isProcessingNotifier.value == false, "当前正在加载中，请勿重复加载");
    appendTask = processManager.generateTask() as AppendTask<T>;
    isProcessingNotifier.value = true;
    appendTask?.taskStatus.listenComplete(() {
      mtLog("加载结束：${FrameUtil.debugFrameCount} ${FrameUtil.debugPhase}",tag:TagsConfig.tagSyncAutoFrame);
      isProcessingNotifier.value = false;
    });
    appendTask?.taskStatus.listenCancel(() {
      isProcessingNotifier.value = false;
    });
  }

  AppendTask<T>? appendTask;

  @override
  double get indicatorHeight => 70;

  @override
  double get maxOverScrollExtent => 120;

  final ValueNotifier<bool> isProcessingNotifier = ValueNotifier(false);
  @override
  bool get physicProcessing => isProcessingNotifier.value;

  @override
  ScrollPositionWithSingleContext get position => loadTrigger.infiniteScorllController.scrollController.position;

  @override
  Widget? build(BuildContext context) {
    if (builder != null) {
      return builder!(context, this);
    }
    // return Positioned(
    //   top: isHeader ? 0 : null,
    //   bottom: isHeader ? null : 0,
    //   left: 0,
    //   right: 0,
    //   child: Center(
    //     child: SizedBox(
    //       height: indicatorHeight,
    //       child: ValueListenableBuilder(
    //         valueListenable: isProcessing,
    //         builder: (context, value, child) {
    //           return Center(
    //             child: Visibility(
    //                 visible: isProcessing.value,
    //                 child: const SizedBox(
    //                     child: CircularProgressIndicator(
    //                   backgroundColor: Colors.amberAccent,
    //                 ))),
    //           );
    //         },
    //       ),
    //     ),
    //   ),
    // );
    return null;
  }

  ValueNotifier<double> pixels = ValueNotifier(0);

  @override
  void changePixel({required double oldPixel, required double newPixel}) {
    pixels.value = newPixel;
  }

  @override
  bool isHeader;

  @override
  bool get needIndicatorHeight => false;

  @override
  bool get needShowFullIndicator => false;
}
