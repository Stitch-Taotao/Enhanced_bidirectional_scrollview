import 'package:bidirectional_load_scrollview/bidirectional_load_scrollview.dart';
import 'package:flutter/material.dart';

import '../../exts/double_ext.dart';
import '../../task/load_trigger.dart';
import 'drive_indicator.dart';

typedef IndicatorBuilderFunc = Widget Function(MTDriveIndicator indicatorNotifier);
typedef IndicatorBuilder = Widget Function(IndicatorNotifierStatus status);

abstract class BuilderIndicator<T extends Object> extends MTDriveIndicator<T> {
  IndicatorBuilder? builder;
  // final LoadTrigger loadTrigger;
  final InfiniteScorllController<T> infiniteScorllController;

  BuilderIndicator({
    required this.infiniteScorllController,
    required super.processManager,
    required this.builder,
    // required this.loadTrigger,
  });

  @override
  Widget build(BuildContext context) {
    return defaultBuildIndicatorBuilder(context);
  }

  IndicatorBuilder get defaultBuilder => (notifier) {
        final pixel = notifier.pixels;
        String text = switch (notifier.status) {
          DivenIndicatorStatusEnum.idle => 'idle',
          DivenIndicatorStatusEnum.dragForward => 'dragForward',
          DivenIndicatorStatusEnum.dragbackward => 'dragbackward',
          DivenIndicatorStatusEnum.ready => 'ready',
          DivenIndicatorStatusEnum.loading => 'loading',
          DivenIndicatorStatusEnum.loaded => 'loaded',
          DivenIndicatorStatusEnum.end => 'end',
        };
        // text += " - Header:$isHeader";
        return Container(
          // height: info.triggerOffset,
          // alignment: Alignment.bottomCenter,
          // color: const Color.fromARGB(255, 122, 135, 233),
          child: Container(
            color: const Color.fromARGB(255, 145, 220, 75),
            alignment: Alignment.center,
            height: notifier.indicator.indicatorHeight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 24),
                ),
                Text(
                  pixel.short,
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
        );
      };
  Widget defaultBuildIndicatorBuilder(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: indicatorNotifer,
      builder: (context, indicatorNotifierStatus, child) {
        return (builder ?? defaultBuilder)(indicatorNotifierStatus);
      },
    );
  }

  @override
  ScrollPositionWithSingleContext get position => infiniteScorllController.scrollController.position;
}
