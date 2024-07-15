import 'dart:math';

import 'package:flutter/material.dart';

import '../drives_indicator/builder_indicator.dart';
import '../drives_indicator/drive_indicator.dart';

class ClassicIndicator extends StatefulWidget {
  final IndicatorNotifierStatus indicatorNotifierStatus;
  const ClassicIndicator({super.key, required this.indicatorNotifierStatus});

  @override
  State<ClassicIndicator> createState() => _ClassicIndicatorState();
}

class _ClassicIndicatorState extends State<ClassicIndicator> with TickerProviderStateMixin {
  IndicatorNotifierStatus get indcatorStatus => widget.indicatorNotifierStatus;
  BuilderIndicator get indicator => indcatorStatus.indicator as BuilderIndicator;
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
  }

  /// 改变动画
  void changeAnimation() {
    final status = indicator.status;
    switch (status) {
      case DivenIndicatorStatusEnum.idle:
        break;
      case DivenIndicatorStatusEnum.dragForward:
        _iconAnimationController.forward();
        break;
      case DivenIndicatorStatusEnum.dragbackward:
        _iconAnimationController.forward();
        break;
      case DivenIndicatorStatusEnum.ready:
        _iconAnimationController.reverse();
      case DivenIndicatorStatusEnum.end:
        _iconAnimationController.reset();
      default:
    }
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
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
    changeAnimation();
    final status = indicator.status;
    Widget? icon;
    switch (status) {
      case DivenIndicatorStatusEnum.idle:
        icon = SizedBox(
            child: Transform.rotate(
          angle: 0,
          child: const Icon(
            Icons.arrow_upward,
          ),
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
      case DivenIndicatorStatusEnum.ready:
        icon = SizedBox(
            child: Transform.rotate(
                angle: pi * _iconAnimationController.value,
                child: const Icon(
                  Icons.arrow_upward,
                )));
        break;
      case DivenIndicatorStatusEnum.loading:
        icon = Container(
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

  Widget _buildText() {
    final status = indicator.status;
    final v = switch (status) {
      DivenIndicatorStatusEnum.idle => "idle",
      DivenIndicatorStatusEnum.dragForward => "下拉加载",
      DivenIndicatorStatusEnum.dragbackward => "下拉加载",
      DivenIndicatorStatusEnum.ready => "松开加载",
      DivenIndicatorStatusEnum.loading => "加载中...",
      DivenIndicatorStatusEnum.loaded => "加载完成",
      DivenIndicatorStatusEnum.end => "end",
    };
    var padRight = v.padRight(20);
    return SizedBox(width: 100, child: Text(padRight));
  }

  @override
  Widget build(BuildContext context) {
    return _buildVerticalBody();
  }
}
