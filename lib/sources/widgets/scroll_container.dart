// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import '../scroll_config/scroll_infinite_controller.dart';

class ScrollContainer extends StatefulWidget {
  const ScrollContainer({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final InfiniteScorllController controller;

  @override
  State<ScrollContainer> createState() => _ScrollContainerState();
}

class _ScrollContainerState extends State<ScrollContainer> {
  @override
  void initState() {
    super.initState();
    widget.controller.init();
    widget.controller.updateUi = () {
      if (mounted) {
        setState(() {});
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    /// TODO: 一定要注意第一次initState到build的阶段是在idle阶段的，其他除外
    final phase = widget.controller.phase;
    for (var element in widget.controller.beforeUpdateItems) {
      element();
    }

    /// 允许在执行过程中追加任务，可能发生在：当加载更多的时候本身已经在beforeUpdateItems中，
    /// 内部触发删除任务，删除任务为了必须在手势、动画处理完毕后检测，是否应该被取消！所以删除任务放在了beforeUpdateItems中
    /// 疑问：既然已经是这一帧了，那么放在beforeUpdateItems的意义？
    /// 删除任务有两种情况：在ideal中触发，由于数据加载是异步完成导致，如果是在idel阶段，那么直接检测取消即可
    /// 还有一种是在persisitent中触发，而且是beforeUpdateItems执行中触发，同理直接取消即可。
    widget.controller.beforeUpdateItems.clear();
    // widget.controller.modifyDataAndCorrectPixelCallback();
    widget.controller.updateItems();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
  }

  List<Widget> get items {
    return widget.controller.source.keyItemMap.values.map((e) => e as Widget).toList();
  }
}
