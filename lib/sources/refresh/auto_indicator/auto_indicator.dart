// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import '../../task/load_trigger.dart';
import '../../task/tasks.dart';
import '../indicator.dart';
import '../indicator_task_manager.dart';

class MTAutoIndicator<T extends Object> extends MTIndicator with BuilderMixin, PixelAwareMixin {
  final LoadTrigger loadTrigger;
  MTProcessingManager processManager;
  MTAutoIndicator({
    required this.loadTrigger,
    required this.processManager,
    required this.isHeader,
  });

  void beginLoading() {
    assert(isProcessing.value == false, "当前正在加载中，请勿重复加载");
    appendTask = processManager.generateTask() as AppendTask<T>;
    isProcessing.value = true;
    appendTask?.taskStatus.listenComplete(() {
      isProcessing.value = false;
    });
    appendTask?.taskStatus.listenCancel(() {
      isProcessing.value = false;
    });
  }

  AppendTask<T>? appendTask;

  @override
  double get indicatorHeight => 70;

  @override
  double get maxOverScrollExtent => 120;

  final ValueNotifier<bool> isProcessing = ValueNotifier(false);
  @override
  bool get physicProcessing => isProcessing.value;

  @override
  ScrollPositionWithSingleContext get position => loadTrigger.infiniteScorllController.scrollController.position;

  @override
  Widget? build(BuildContext context) {
    return Positioned(
      top: isHeader ? 0 : null,
      bottom: isHeader ? null : 0,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          height: indicatorHeight,
          child: ValueListenableBuilder(
            valueListenable: isProcessing,
            builder: (context, value, child) {
              return Center(
                child: Visibility(
                    visible: isProcessing.value,
                    child: const SizedBox(
                        child: CircularProgressIndicator(
                      backgroundColor: Colors.amberAccent,
                    ))),
              );
            },
          ),
        ),
      ),
    );
  }

  ValueNotifier<double> pixels = ValueNotifier(0);

  @override
  void changePixel({required double oldPixel, required double newPixel}) {
    pixels.value = newPixel;
  }

  @override
  bool isHeader;

  @override
  bool get needIndicatorHeight => true;

  @override
  bool get needShowFullIndicator => false;
}
