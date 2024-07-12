import 'dart:math';

import 'package:flutter/material.dart';

import '../drives_indicator/drive_indicator.dart';
import '../drives_indicator/header_indicator.dart';

// class ClassicHeaderIndicator<T extends Object> extends HeaderIndicator<T> {
//   ClassicHeaderIndicator({required super.processManager, required super.loadTrigger}) : super(builder: _builder);

//   static IndicatorBuilder get _builder => (indicatorNotifer) {
//         return _ClassicHeader(indicatorNotifierStatus: indicatorNotifer);
//       };
// }

class ClassicHeader extends StatefulWidget {
  final IndicatorNotifierStatus indicatorNotifierStatus;
  const ClassicHeader({super.key, required this.indicatorNotifierStatus});

  @override
  State<ClassicHeader> createState() => _ClassicHeaderState();
}

class _ClassicHeaderState extends State<ClassicHeader> with TickerProviderStateMixin {
  IndicatorNotifierStatus get indcatorStatus => widget.indicatorNotifierStatus;
  HeaderIndicator get indicator => indcatorStatus.indicator as HeaderIndicator;
  // late GlobalKey _iconAnimatedSwitcherKey;

  /// Icon animation controller.
  late AnimationController _iconAnimationController;
  @override
  void initState() {
    super.initState();
    // _iconAnimatedSwitcherKey = GlobalKey();
    _iconAnimationController = AnimationController(
      value: 0,
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _iconAnimationController.addListener(() {
      if (mounted) {
        setState(() {
          // mtLog("_iconAnimationController.value:${_iconAnimationController.value}", tag: TagsConfig.tagAnimationController);
        });
      }
    });
    indcatorStatus.dragDirectionChange.addListener(changeDragDirection);
  }

  void changeDragDirection() {
    bool isDown = indcatorStatus.dragDirectionChange.value;
    // mtLog("isDown:$isDown - ${_iconAnimationController.value}", tag: TagsConfig.tagAnimationController);

    if (isDown) {
      _iconAnimationController.reverse();
    } else {
      _iconAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    indcatorStatus.dragDirectionChange.removeListener(changeDragDirection);
    super.dispose();
  }

  Widget _buildVerticalBody() {
    return Container(
      alignment: Alignment.center,
      height: indicator.indicatorHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            alignment: Alignment.center,
            child: _buildIcon(),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            // width: widget.textDimension,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildText(),
                _buildMessage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build text.
  Widget _buildMessage() {
    return const Padding(padding: EdgeInsets.only(top: 4), child: Text("MESSAGE"));
  }

  /// Build icon.
  Widget _buildIcon() {
    final status = indicator.status;
    Widget? icon;
    switch (status) {
      case DivenIndicatorStatusEnum.idle:
        icon = SizedBox(
            child: Transform.rotate(
          angle: 0,
          child: const SizedBox(),
        ));
        break;
      case DivenIndicatorStatusEnum.dragForward:
      case DivenIndicatorStatusEnum.dragbackward:
        icon = SizedBox(
            child: Transform.rotate(
          angle: pi * _iconAnimationController.value,
          child: const Icon(
            Icons.arrow_upward,
          ),
        ));
        break;
      // case IndicatorStatusEnum.dragbackward:
      //   icon = SizedBox(
      //       child: Transform.rotate(
      //     angle: -pi / 2,
      //     child: const Icon(
      //       Icons.arrow_back,
      //     ),
      //   ));
      //   break;
      case DivenIndicatorStatusEnum.ready:
        icon = SizedBox(
            child: Transform.rotate(
          angle: 0,
          child: const Icon(
            Icons.run_circle_outlined,
          ),
        ));
        break;
      case DivenIndicatorStatusEnum.loading:
        icon =  Container(
          padding: const EdgeInsets.all(8),
          width: 40,
          height: 40,
          child: const CircularProgressIndicator(
            strokeWidth: 3,
            color: Colors.blueAccent,
          ),
        );
        break;
      case DivenIndicatorStatusEnum.loaded:
        icon = SizedBox(
            child: Transform.rotate(
          angle: 0,
          child: const Icon(
            Icons.done,
          ),
        ));
        break;
      case DivenIndicatorStatusEnum.end:
        break;
    }
    icon ??= const SizedBox();
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      child: icon,
    );
  }

  /// Build text.
  Widget _buildText() {
    final status = indicator.status;
    final v = switch (status) {
      DivenIndicatorStatusEnum.idle => "idle",
      DivenIndicatorStatusEnum.dragForward => "dragForward",
      DivenIndicatorStatusEnum.dragbackward => "dragbackward",
      DivenIndicatorStatusEnum.ready => "ready",
      DivenIndicatorStatusEnum.loading => "loading",
      DivenIndicatorStatusEnum.loaded => "loaded",
      DivenIndicatorStatusEnum.end => "end",
    };
    var padRight = v.padRight(20);
    return Container(width: 100, child: Text(padRight));
  }

  @override
  Widget build(BuildContext context) {
    return _buildVerticalBody();
  }
}
