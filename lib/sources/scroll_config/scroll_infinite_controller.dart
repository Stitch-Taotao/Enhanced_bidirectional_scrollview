// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../exts/double_ext.dart';
import '../task/load_trigger.dart';
import '../task/task_manager.dart';
import '../task/tasks.dart';
import '../task/user_operation.dart';
import '../utils/frame_util.dart';
// ignore: unused_import
import '../utils/log_util.dart';
import '../utils/logs/log_config.dart';
import '../utils/rb_util.dart';
import '../widgets/tag_widget.dart';
import 'keys.dart';
import 'scoll_coordinator.dart';
import 'scroll_controller.dart';
import 'viewport.dart';

enum PutItemsType { init, appendLeading, appendTrailing, replace, delete }

typedef WhenNokeyFindFunc<T extends Object> = UserExpectOperation<T> Function({required InfiniteScorllController<T> controller});

class InfiniteScorllController<T extends Object> {
  final DataSource<T> _source = DataSource.empty();

  DataSource<T> get source => _source;
  late MTScrollController scrollController;
  late TaskManager<T> taskManager;
  final int maxCount;
  AccumuateOffset accumuateOffset = AccumuateOffset();
  late ScrollCoordinator coordinator;

  LoadTrigger<T>? _loadTrigger;
  LoadTrigger<T> get loadTrigger => _loadTrigger!;

  InfiniteScorllController({
    required this.initList, // 初始化列表
    required this.buildItem, // 构建列表项
    this.shouldTriggerLoadMore,
    this.maxCount = 600,
    LoadTrigger<T>? loadTrigger,
  }) {
    scrollController = MTScrollController(this);
    taskManager = TaskManager<T>(infiniteScorllController: this);
    if (loadTrigger != null) {
      updateLoadTrigger(loadTrigger);
    }
  }

  void updateLoadTrigger(LoadTrigger<T> loadTrigger) {
    _loadTrigger = loadTrigger;
    coordinator = ScrollCoordinator.init(loadTrigger);
    loadTrigger.assemble(this);
  }

  bool isFirstInit = true;

  /// 是否包含某个T
  bool hasKey(T key) {
    return source.tagKeyMap.containsKey(key);
  }

  /// 初始化列表，并指定滚动位置
  UserInitOperation<T> Function() initList;

  Widget Function(InfiniteKey<T> key) buildItem;
  bool Function(ScrollUpdateNotification notification)? shouldTriggerLoadMore;

  // late UserExpectOperation initOperation;

  bool _debugIsFirstLaunch = true;

  void init() async {
    if (!isFirstInit) {
      /// TODO：如果是reload的话，可能虽然controller是同一个，但是会触发多次init
      return;
    }
    isFirstInit = false;
    _debugIsFirstLaunch = true;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _debugIsFirstLaunch = false;
    });
    final initOperation = initList();
    // initOperation = initS;
    final keys = await initOperation.keys;
    assert(updateUi == null, "如果不为空，说明是非同步完成的，这是不可能的");
    taskManager.debugOriginTaskIsEmpty(info: "初始化的时候，任务列表一定是空的啦");
    _modifyItems(keys, PutItemsType.init);
    T? showKey = initOperation.showKey;
    Tag? showTag = initOperation.showTag;
    final releateOffset = initOperation.releateOffset;
    final key = source.tagKeyMap[showKey];

    /// 如果没有找到要跳转的key，那么就显示第一个元素的位置
    if (key == null) {
      if (source.keyItemMap.keys.isNotEmpty) {
        showKey = source.keyItemMap.keys.first.dataKey;
      }
      showTag = null;
    }
    if (showKey != null) {
      _deliverJumpToExistKey(tag: showKey, showTag: showTag, releateOffset: releateOffset, afterLayout: true);
    }
  }

  /// 更新之前的回调
  List<VoidCallback> beforeUpdateItems = [];
  VoidCallback? _modifyDataAndCorrectPixelCallback;

  VoidCallback get modifyDataAndCorrectPixelCallback {
    _modifyDataAndCorrectPixelCallback ??= () {
      try {
        if (_builderContext == null || !_builderContext!.mounted) {
          taskManager.clearAllTask();
          return;
        }

        ///
        updateUi?.call();
        final tasks = taskManager.getAllMicroTasks();
        if (tasks.isEmpty) {
          return;
        }

        if (tasks.length > 1) {
          for (var task in tasks) {
            assert(task is AppendTask<T>, "只有追加数据才可能出现两个任务");
          }
          _handleAppendTask(tasks.cast<AppendTask<T>>());
        } else {
          final task = tasks.first;
          // if (task is UserReplaceTask<T>) {
          //   final modifyDataOp = task.modifyDataOp;
          //   if (modifyDataOp != null) {
          //     _modifyItems(modifyDataOp.keys, PutItemsType.replace);
          //   } else {
          //     assert(false, "如果是追加数据的任务，那么一定是有修改操作的");
          //   }
          // } else
          if (task is AppendTask<T>) {
            // _handleAppendTask(tasks as List<AppendTask<T>>);
            _handleAppendTask(tasks.cast<AppendTask<T>>());
          } else if (task is JumpToExistKeyTask<T>) {
            final tag = task.tag;
            final showTag = task.showTag;
            final releateOffset = task.releateOffset;
            _deliverJumpToExistKey(tag: tag!, showTag: showTag, releateOffset: releateOffset, afterLayout: true);
            task.complete(reason: "正常完成任务");
          } else if (task is JumpToNoExistTask<T>) {
            int debugCount = 0;
            debugCount = 1;
            () async {
              final keys = await task.operation.keys;
              replaceDatasAndJump(keys, task.operation);
              debugCount = 2;
            }();
            assert(debugCount == 2, "立即执行");
            task.complete(reason: "正常完成任务");
          }
        }
        taskManager.debugBuildTaskIsEmpty();
      } catch (e, stackTrace) {
        /// TODO 如何比较好的处理进入时间循环的堆栈信息呢？
        mtLog("(((------", tag: TagsConfig.tagCatchError);
        mtLog(e, tag: TagsConfig.tagCatchError);
        debugPrintStack(stackTrace: stackTrace, maxFrames: 10, label: "未捕获到的错误");
        mtLog("------)))", tag: TagsConfig.tagCatchError);
        assert(false);
        rethrow;
      }
      // final task = tasks.first;
    };
    return _modifyDataAndCorrectPixelCallback!;
  }

  void _handleAppendTask(List<AppendTask<T>> tasks) {
    void modifyAppendTask(WrapReason wReason, AppendTask<T> task) {
      final modifyDataOp = task.modifyDataOp;
      if (modifyDataOp != null) {
        if (modifyDataOp.appendLeading) {
          _modifyItems(modifyDataOp.keys, PutItemsType.appendLeading);
          // task.adjustPixelEvent = ApAutoKeepVisualWindow(task: task);
          wReason.reason += KeepVisualWindowsReason.appendLeading;
        } else {
          _modifyItems(modifyDataOp.keys, PutItemsType.appendTrailing);
        }
      } else {
        assert(false, "如果是追加数据的任务，那么一定是有修改操作的");
      }
      task.complete(reason: "正常完成任务");
    }

    void tryDeleteMoreItemTask(WrapReason wrapReason) {
      /// 检测是否超出一定的数量，超过的话需要进行删除
      bool deleteLeading = _tryAutoDeleteOldData(deleteLeading: true);
      if (deleteLeading) {
        wrapReason.reason += KeepVisualWindowsReason.deleteLeading;
      } else {
        _tryAutoDeleteOldData(deleteLeading: false);
      }
    }

    WrapReason wrapReason = WrapReason();
    if (tasks.length > 1) {
      while (tasks.length >= 1) {
        final task = tasks.removeAt(0);
        modifyAppendTask(wrapReason, task);
      }
      // for (var task in tasks) {
      //   modifyAppendTask(wrapReason, task);
      // }
      tryDeleteMoreItemTask(wrapReason);
    } else {
      assert(tasks.isNotEmpty, "前面已经判断过了");
      final task = tasks.first;
      modifyAppendTask(wrapReason, task);
      tryDeleteMoreItemTask(wrapReason);
    }
    if (wrapReason.reason != KeepVisualWindowsReason.none) {
      keepCurrentVisualWindow(shouldAppendOffset: true, wrapReason: wrapReason);
    }
  }

  void _deliverJumpToExistKey({
    required T tag,
    Tag? showTag,
    double releateOffset = 0.0,
    required bool afterLayout,
  }) {
    assert(afterLayout || phase == SchedulerPhase.midFrameMicrotasks, "目前处理阶段一定是mid阶段");

    /// 去除初始化的时候,其实初始化的时候放开也没问题
    if (phase == SchedulerPhase.midFrameMicrotasks) {
      coordinator.needCorrectPixels(correctType: CorrectEnum.jmmpToItem);
    }
    final key = source.tagKeyMap[tag];
    void jump() {
      final targetRenderChild = findRenderObjectByKeyAndTag(key!, showTag);
      if (targetRenderChild == null) {
        return;
      }
      MTRenderSingleChildViewport viewportRb = getViewportRenderObjectByContext();

      RenderBox? renderBox = targetRenderChild as RenderBox;
      viewportRb.scrollToRenderInBound(descendant: renderBox, scrollOffset: releateOffset, needStopScroll: true);
    }

    if (afterLayout) {
      _afterLayoutCallback(() {
        jump();
      });
    } else {
      jump();
    }
  }

  void replaceDatasAndJump(List<T> keys, UserReplaceOperation<T> operation) {
    assert(phase == SchedulerPhase.midFrameMicrotasks, "目前处理阶段一定是mid阶段");
    source.clear();
    _modifyItems(keys, PutItemsType.replace);
    T? showKey = operation.showKey;
    Tag? showTag = operation.showTag;
    final releateOffset = operation.releateOffset;
    final key = source.tagKeyMap[showKey];

    /// 如果没有找到要跳转的key，那么就显示第一个元素的位置
    if (key == null) {
      if (source.keyItemMap.keys.isNotEmpty) {
        showKey = source.keyItemMap.keys.first.dataKey;
      }
      showTag = null;
    }
    if (showKey != null) {
      _deliverJumpToExistKey(tag: showKey, showTag: showTag, releateOffset: releateOffset, afterLayout: true);
    }
  }

  /// 更新Widget
  void updateItems() {
    final keys = source.keyItemMap.keys.toList();
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      Widget w = buildItem(key);
      w = TagWidget<T>(
        key: key.globalKey,
        metaData: key,
        child: w,
      );
      source.keyItemMap[key] = w;
    }
  }

  void _modifyItems(
    List<T> keys,
    PutItemsType type,
  ) {
    // 移除空判断，是为了这个方法传空，可以直接做删除，统一处理更加方便
    // if (keys.isEmpty) {
    //   return;
    // }
    if (type == PutItemsType.init) {
      if (!_debugIsFirstLaunch) {
        assert(phase == SchedulerPhase.midFrameMicrotasks);
      }
    } else {
      assert(phase == SchedulerPhase.midFrameMicrotasks);
    }
    Map<InfiniteKey<T>, Widget?> newItems = {};

    void add() {
      /// 新加Widget
      for (var key in keys) {
        final infiniteKey = InfiniteKey<T>(dataKey: key);
        assert(() {
          if (source.tagKeyMap.containsKey(key)) {
            return false;
          } else {
            return true;
          }
        }(), "Key不能有重复");
        source.tagKeyMap[key] = infiniteKey;

        // Widget w = buildItem(infiniteKey);
        // w = TagWidget<T>(
        //   key: infiniteKey.globalKey,
        //   metaData: key,
        //   child: w,
        // );
        // /// 保持之前已有的Widget
        // // newItems[infiniteKey] = source.keyItemMap[infiniteKey];
        // newItems[infiniteKey] = w;
        /// 注意，这里一定要给Null，因为下面会用到检测，只有非空的，才会去寻找
        newItems[infiniteKey] = null;
      }
    }

    void delete() {
      for (var key in keys) {
        final infiniteKey = source.tagKeyMap[key];
        assert(infiniteKey != null, "请检查逻辑问题");
        source.keyItemMap.remove(infiniteKey);
        // final w = source.keyItemMap.remove(infiniteKey);
        source.tagKeyMap.remove(key);

        // assert(w != null, "请检查为什么Widget为空"); // 可能是空
      }
    }

    switch (type) {
      case PutItemsType.init:
        add();
        source.keyItemMap = {
          ...newItems,
        };
        break;
      case PutItemsType.appendLeading:
        add();
        source.keyItemMap = {
          ...newItems,
          ...source.keyItemMap,
        };
        break;
      case PutItemsType.appendTrailing:
        add();
        source.keyItemMap = {
          ...source.keyItemMap,
          ...newItems,
        };
        break;
      case PutItemsType.replace:
        add();
        source.keyItemMap = {
          ...newItems,
        };
        break;
      case PutItemsType.delete:
        delete();
        break;
      default:
    }
    assert(source.keyItemMap.length == source.tagKeyMap.length, "请检查逻辑问题");
  }

  /// 达到某个条件（假设超过了1000条数据) 触发删除，可能需要删除的条目
  List<T> _caculAutoDeleteItems({required bool deleteLeading}) {
    /// 删除最大容量的一半
    int keepStore = maxCount ~/ 2;
    final keyItemMap = source.keyItemMap;
    final keys = keyItemMap.keys.toList();
    List<T> newkeys = [];
    if (deleteLeading) {
      int start = keys.length - keepStore;
      for (var i = 0; i < start; i++) {
        final key = keys[i];
        newkeys.add(key.dataKey);
      }
    } else {
      int start = keys.length - keepStore;
      for (int i = start; i < keys.length; i++) {
        final key = keys[i];
        newkeys.add(key.dataKey);
      }
    }
    return newkeys;
  }

  BuildContext? _builderContext;

  bind(BuildContext context) {
    _builderContext = context;
  }

  /// 工具方法
  MTRenderSingleChildViewport getViewportRenderObjectByContext() {
    late RenderBox viewPortRenderObject;
    _builderContext?.visitAncestorElements((element) {
      if (element is RenderObjectElement && element.renderObject is MTRenderSingleChildViewport) {
        viewPortRenderObject = element.renderObject as RenderBox;
        return false;
      }
      return true;
    });
    return viewPortRenderObject as MTRenderSingleChildViewport;
  }

  bool frameChange = false;

  /// 为了调试
  // static int get frameCount => WidgetsBinding.instance.frameCount;
  static int get _frameCount => FrameUtil.frameCount;

  static String get debugFrameCount => '（帧:$_frameCount)';

  SchedulerPhase get phase => WidgetsBinding.instance.schedulerPhase;

  String get debugPhase => '[阶段:$phase]';

  /// 代理滚动
  void notifyScroll(ScrollNotification notification) {
    return;

    // /// 目前只处理ScrollUpdateNotification通知，后续有新的思路再考虑其他
    // if (notification is! ScrollUpdateNotification) {
    //   return;
    // }
    // // mtLog("ScrollUpdateNotification : ${position.pixels.short} ${instance.schedulerPhase} $debugFrameCount ${notification.scrollDelta?.short}");
    // final delta = notification.scrollDelta ?? 0;
    // if (shouldTriggerLoadMore != null) {
    //   shouldTriggerLoadMore?.call(notification);
    // } else {}
    // notifyScrollDelta(delta);
  }

  void notifyScrollDelta(double scrollDelta) {
    /// 是否能触发追加数据
    if (loadTrigger is AutoLoadTrigger) {
      final autoTriggerType = loadTrigger as AutoLoadTrigger<T>;
      if (scrollDelta < 0) {
        if (autoTriggerType.appendHeadTask != null) {
          if (taskManager.canAddAppendTask(true)) {
            final needTriggerCallback = autoTriggerType.needTriggerHeader;
            final needTrigger = needTriggerCallback.call(scrollController, scrollDelta);
            if (needTrigger) {
              autoTriggerType.headerIndicator?.beginLoading();
            }
          }
        }
      } else if (scrollDelta > 0) {
        if (autoTriggerType.appendFootTask != null) {
          if (taskManager.canAddAppendTask(false)) {
            final needTriggerCallback = autoTriggerType.needTriggerFooter;
            final needTrigger = needTriggerCallback.call(scrollController, scrollDelta);
            if (needTrigger) {
              autoTriggerType.footerIndicator?.beginLoading();
            }
          }
        }
      }
    }
  }

  /// 触发追加数据
  AppendTask<T> trickAppendData({required bool appendLeading, required Future<List<T>> Function() request}) {
    // final can = taskManager.canAddAppendTask(appendLeading);
    // if (!can) {
    //   return null;
    // }
    return AppendTask<T>(
        asyncTask: request(),
        manager: taskManager,
        whenReady: (task) {
          // updateUi?.call(); // 没有必要调用刷新，统一移动到一起处理了
          mtLog("${task.debugIdentify}加载前keys:${source.keyItemMap.keys.map((e) => e.dataKey).toList()} 要加载的keys:${task.keys}");
        },
        appendLeading: appendLeading);
  }

  void trickReplace() {}
  VisualEdgeItemData<T>? _currentFrameVisualItemData;

  VisualEdgeItemData<T>? _findVisualItem() {
    if (_currentFrameVisualItemData != null) {
      return _currentFrameVisualItemData!;
    }
    final viewportRb = getViewportRenderObjectByContext();
    RenderFlex? renderflex = viewportRb.child as RenderFlex?;
    RenderBox? renderBox = renderflex?.firstChild;
    RenderBox? leadingRenderBox;
    // RenderBox? trailingRenderBox;
    Rect localLeadingRect = Rect.zero;
    // Rect localTrailingRect = Rect.zero;
    InfiniteKey<T>? leadingFirstkey;
    InfiniteKey<T>? leadingLastkey;

    /// 可能存在topest item并不在Edge上
    /// 正向查找
    while (renderBox != null) {
      final pd = renderBox.parentData as FlexParentData;
      if (renderBox is RenderTagWidget<T>) {
        // mtLog((renderBox as RenderMetaData).metaData);
        final topOffset = renderBox.localToGlobal(Offset.zero, ancestor: viewportRb);
        if (topOffset.dy >= 0) {
          leadingFirstkey = (renderBox).metaData;
          localLeadingRect = topOffset & renderBox.size;
          leadingRenderBox = renderBox;
          break;
        }
        if (topOffset.dy <= 0 && topOffset.dy + renderBox.size.height > 0) {
          leadingFirstkey = (renderBox).metaData;
          localLeadingRect = topOffset & renderBox.size;
          leadingRenderBox = renderBox;
          break;
        }
      }
      renderBox = pd.nextSibling;
    }

    /// 逆向查找
    renderBox = renderflex?.lastChild;
    final maxExtent = viewportRb.size.height;
    while (renderBox != null) {
      final pd = renderBox.parentData as FlexParentData;
      if (renderBox is RenderTagWidget<T>) {
        final topOffset = renderBox.localToGlobal(Offset.zero, ancestor: viewportRb);
        if (topOffset.dy + renderBox.size.height <= maxExtent) {
          leadingLastkey = (renderBox).metaData;
          break;
        }
        if (topOffset.dy < maxExtent && topOffset.dy + renderBox.size.height >= maxExtent) {
          leadingLastkey = (renderBox).metaData;
          break;
        }
      }
      renderBox = pd.previousSibling;
    }

    /// 现在的计算法方式，保证即便是有单个Item远超屏幕高度也依然不会有问题
    Rect renderFlexRect = leadingRenderBox!.localToGlobal(Offset.zero, ancestor: renderflex!) & leadingRenderBox.size;
    if (leadingFirstkey == null || leadingLastkey == null) {
      return null;
    }
    _currentFrameVisualItemData ??= VisualEdgeItemData(
      leadingFirstkey: leadingFirstkey,
      localLeadingRect: localLeadingRect,
      // localTrailingRect: localTrailingRect,
      renderBox: leadingRenderBox,
      leadingLastkey: leadingLastkey,
      renderFlexRect: renderFlexRect,
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _currentFrameVisualItemData = null;
    });
    return _currentFrameVisualItemData!;
  }

  bool _hasKeepVisualWindow = false;

  /// 保持上一帧的滚动状态，并追加偏移值
  void keepCurrentVisualWindow({required bool shouldAppendOffset, required WrapReason wrapReason}) {
    if (_hasKeepVisualWindow) {
      /// 目前还没发现同时触发了两个保持当前窗口的情况
      assert(false);
      return;
    }
    coordinator.needCorrectPixels(correctType: CorrectEnum.keepCurrentVisualWindow);
    final reason = wrapReason.reason;
    _hasKeepVisualWindow = true;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _hasKeepVisualWindow = false;
    });
    late InfiniteKey<T> leadingFirstKey;
    final visualItemInfo = _findVisualItem();
    if (visualItemInfo == null) {
      mtLog("由于没有发现可视窗口上的item，所以无法保持当前窗口", tag: TagsConfig.tagUnnormal);
      return;
    }
    leadingFirstKey = visualItemInfo.leadingFirstkey;
    RenderBox renderBox = visualItemInfo.renderBox;
    double localLeading = -visualItemInfo.localLeadingRect.top;
    // assert(localLeading >= 0, "上一帧渲染的第一个可见item的top值必须小于等于0");
    assert(() {
      return (leadingFirstKey.globalKey.currentContext?.findRenderObject() == renderBox);
    }(), "检查出错问题");
    assert(phase == SchedulerPhase.midFrameMicrotasks, "现已经把保持位置放在build阶段了，如果不是，请检查出错问题");

    /// 下面是真正的计算跳转
    MTRenderSingleChildViewport viewportRb = getViewportRenderObjectByContext();

    /// 注意这里获取到的并不是上一渲染周期的pixel值！所以不能用这个去对比assert
    final beforeLayoutPixel = scrollController.position.pixels;
    final topOffset2 = renderBox.localToGlobal(Offset(0, localLeading), ancestor: viewportRb.child);

    final preFrameOffsetPixel = topOffset2.dy;

    /// 在最后滚动之后布局开始之前的offset一定是和上一帧的渲染offset和滚动偏移值关系一致的
    {
      double scrollOffset = accumuateOffset.accumulatedOffset;
      // preFrameOffsetPixel:125.77933394089578 scrollOffset:-157.81449622222104 lastBeforeLayoutPixel:-32.03516228132526
      final lastBeforeLayoutPixel = scrollController.position.pixels;
      if ((preFrameOffsetPixel + scrollOffset - lastBeforeLayoutPixel) >= 1e-6) {
        //  "理论上布局之前，这两个值一定相等"
        mtLog(
            "$debugFrameCount $debugPhase preFrameOffsetPixel:${preFrameOffsetPixel.short} scrollOffset:${scrollOffset.short} lastBeforeLayoutPixel:${lastBeforeLayoutPixel.short}",
            tag: TagsConfig.tagCatchError);
        mtLog("${preFrameOffsetPixel + scrollOffset},$lastBeforeLayoutPixel", tag: TagsConfig.tagCatchError);

        /// TODO: 这里需要调查为什么同步auto加载，如果页面销毁可能会导致断言错误
        // assert(false);
      }
    }

    /// 最大的问题在于，maxScrollExtend可能会在当前帧中发生变化，也就是说现在获取了，但是在performLayout阶段可能发生变化。
    /// 假设第42帧触发加载更多，但是到第43帧才开始加载更多，并且，第43帧加载更多会触发删除leading，并且删除之后会继续刷新UI
    /// 42帧触发加载更多的时候
    final oldMaxExtent = scrollController.position.maxScrollExtent + viewportRb.size.height;
    final renderFlexHeight = viewportRb.child!.size.height;
    assert(() {
      return renderFlexHeight == oldMaxExtent;
    }(), "检查出错问题");
    // final beforeItems = source.tagKeyMap.keys;
    final beforeItems = source.keyItemMap.keys.map((e) => e.dataKey).toList();
    mtLog("保持滚动-前 reason:$reason beforeItems:$beforeItems $debugFrameCount $debugPhase");

    /// 上一帧这个顶部元素之上的高度
    final preTopVisulItemTop = visualItemInfo.renderFlexRect.top;
    void scoll() {
      // final t = this;
      final viewportRb = getViewportRenderObjectByContext();
      RenderFlex? renderflex = viewportRb.child as RenderFlex?;
      final newVisualItem = leadingFirstKey.globalKey.currentContext!.findRenderObject()! as RenderBox;
      final curTopVisulItemTop = newVisualItem.localToGlobal(Offset.zero, ancestor: renderflex).dy;
      var sizeAppend = curTopVisulItemTop - preTopVisulItemTop;
      // final debugVisualItem = visualItemInfo;
      // assert(() {

      // }(),"既然是同一帧，必定是一致的");
      final newMaxExtent = scrollController.position.maxScrollExtent + viewportRb.size.height;
      final renderFlexHeight = viewportRb.child!.size.height;
      assert(() {
        return renderFlexHeight == newMaxExtent;
      }(), "检查出错问题");
      final afterLayoutPixel = scrollController.position.pixels;
      double scrollOffset = shouldAppendOffset ? accumuateOffset.accumulatedOffset : 0;
      // final afterItems = source.tagKeyMap.keys;
      final afterItems = source.keyItemMap.keys.map((e) => e.dataKey).toList();

      mtLog("保持滚动-后 reason:$reason beforeItems:$beforeItems afterItems:$afterItems $debugFrameCount $debugPhase");
      // mtLog("当前帧$debugFrameCount，items的列表变化情况：beforeItems：$beforeItems - afterItems:$afterItems");

      RenderBox? renderBox = leadingFirstKey.globalKey.currentContext!.findRenderObject()! as RenderBox;

      /// 新的renderBox是：
      while (renderBox != null) {
        if (renderBox is RenderTagWidget) {
          break;
        }
        renderBox = renderBox.parent as RenderBox?;
      }

      /// MARK : 这里为什么获取到的viewportRb中和renderflex中的位置不一样呢？
      /// 因为viewPort中的位置是以viewPort的起始点算的和renderFlex不一回事，因为renderFlex在viewPort中是有偏移的
      // final topOffset = renderBox!.localToGlobal(Offset(0, localLeading), ancestor: viewportRb);
      // mtLog("添加内容后topOffset:$topOffset topOffset2:$topOffset2 key.tag:${key.tag} leading:$localLeading");
      final topOffset2 = renderBox!.localToGlobal(Offset(0, localLeading), ancestor: viewportRb.child);
      final noOffsetPosition = topOffset2.dy;
      final targetOffset = noOffsetPosition + scrollOffset;
      const tolerr = 0.001;

      mtLog(
          "当前帧$debugFrameCount累计偏移为:${scrollOffset.short} 数值： beforeLayoutPixel:${beforeLayoutPixel.short} afterLayoutPixel :${afterLayoutPixel.short} ，noOffsetPosition:${noOffsetPosition.short} preFrameOffsetPixel:$preFrameOffsetPixel ");
      mtLog("触发保持屏幕滚动的reason:$reason，$debugFrameCount $debugPhase");
      // var sizeAppend = newMaxExtent - oldMaxExtent;
      // if (newMaxExtent >= oldMaxExtent) {
      /// 先触发追加，再触发删除，但是保持屏幕位置的代码却是在追加和删除之后才会触发的。
      /// 假设最大容纳60个，每次加载20个，则可能出现20,40,60,50个的情况，因为60-30+20
      // 如果是触发了删除元素，则不应该这样计算！
      // assert((noOffsetPosition - (preFrameOffsetPixel + sizeAppend)).abs() < tolerr, "滚动衔接没有处理好，请检查哪里出问题了！");
      /// MARK 【上一帧的渲染位置和这一帧的渲染位置的关系？真正相等的其实是，加上这个item之前的区域的改变量，而不是所有的改变量】
      assert((noOffsetPosition - (preFrameOffsetPixel + sizeAppend)).abs() < tolerr, "滚动衔接没有处理好，请检查哪里出问题了！");

      if (!(sizeAppend.abs() > 0)) {
        /// TODO: 删除了之后，pixel会被修正，而这个修正并不一定是对的，所以afterLayoutPixel不能作为判断依据
        if (!((afterLayoutPixel - (preFrameOffsetPixel + scrollOffset)).abs() < tolerr)) {
          mtLog("滚动衔接没有处理好，请检查哪里出问题了！阶段：${WidgetsBinding.instance.schedulerPhase}");
          mtLog("oldMaxExtent: $oldMaxExtent,newMaxExtent: $newMaxExtent");
          assert(false);
        }
      }

      assert(scrollOffset == accumuateOffset.accumulatedOffset, "累计偏移量不一致");

      // viewportRb.scrollTo(descendant: renderBox!, scrollOffset: scrollOffset, needTrickLisiner: false, needStopScroll: needStopScroll);
      viewportRb.scrollToOffsetUnBound(scrollOffset: targetOffset, needTrickLisiner: true, needStopScroll: false);

      /// 如果是惯性动画，则一定要重新设置惯性动画
      final activity = viewportRb.offset.activity;
      assert(() {
        return activity is IdleScrollActivity || activity is BallisticScrollActivity || activity is DragScrollActivity;
      }(), "检查出错问题");

      /// 没有必要reset，因为BallisticScrollActivity内部在更新尺寸的时候已经重新设置过了，只不过问题是，这个效果不是我想要的,
      /// 因为内部经过physic的判断直接将速度变为0了
      /// TODO：另外要注意的是：DrivenScrollActivity 内部并没有这种处理，如果是主动触发的动画，触发了尺寸变化怎么办？由于to的值不变
      ///，是否意味着会跳帧
      // if (activity is BallisticScrollActivity) {
      //   activity.resetActivity();
      // }
    }

    _afterLayoutCallback(scoll);
  }

  _afterLayoutCallback(void Function() callback) {
    final renderViewport = getViewportRenderObjectByContext();
    if (phase == SchedulerPhase.midFrameMicrotasks) {
      renderViewport.markNeedsLayout();
    }
    final position = scrollController.position;
    return position.addBetweenLayoutAndPaintTask(() {
      callback();
    });
  }

  void jumpExistKey({
    required T tag,
    Tag? showTag,
    double releateOffset = 0.0,
  }) {
    /// 创建一个JumpToExistKeyTask
    JumpToExistKeyTask(manager: taskManager, tag: tag, showTag: showTag, releateOffset: releateOffset);
  }

  /// 无法找到key，请问怎么处理
  /// 暂且只进行替换操作，后续考虑其他操作
  void jumpNoExistkey({required UserHandleOperation<T> operation}) {
    operation.checkAssert();
    final useExpectType = operation.opType;
    switch (useExpectType) {
      case UserExpectOpEnum.appendLeading:

        /// TODO:这里需要处理
        trickAppendData(appendLeading: true, request: () => operation.keys);
        break;
      case UserExpectOpEnum.appdendTrailing:
        trickAppendData(appendLeading: false, request: () => operation.keys);
        break;
      case UserExpectOpEnum.replace:
        assert(operation is UserReplaceOperation<T>);
        final castOperation = operation as UserReplaceOperation<T>;
        JumpToNoExistTask(manager: taskManager, operation: castOperation);
        break;
      default:
        assert(false, "检查是否遗漏什么情况");
    }
  }

  void deleteKeys() {}

  /// 根据key和Tag找到对应的要跳转到的renderObject
  RenderObject? findRenderObjectByKeyAndTag(InfiniteKey<T> key, Tag? showTag) {
    var currentContext = key.globalKey.currentContext;
    if (currentContext == null) {
      return null;
    }
    Tagkey? tagKey;
    if (showTag != null) {
      tagKey = Tagkey(showTag);
    }
    Element? tElement;
    if (tagKey != null) {
      tElement = RbUtil.findChildElementByTag(currentContext as Element, tagKey);
    } else {
      tElement = currentContext as Element;
    }
    if (tElement == null) {
      return null;
    }
    final tRb = RbUtil.findNearstRenderObject(tElement);
    return tRb;
  }

  /// 找不到key
  void Function()? updateUi;

  bool _checkIfReachCapacity() {
    final keyItemMap = source.keyItemMap;
    final keys = keyItemMap.keys.toList();
    return keys.length > maxCount;
  }

  bool _tryAutoDeleteOldData({required bool deleteLeading}) {
    assert(phase == SchedulerPhase.midFrameMicrotasks, "phase其实是$phase");
    bool exceedCount = _checkIfReachCapacity();
    if (!exceedCount) {
      return false;
    }
    final needDeletekeys = _caculAutoDeleteItems(deleteLeading: deleteLeading);
    if (needDeletekeys.isEmpty) {
      return false;
    }
    assert(() {
      final keys = source.keyItemMap.keys;
      mtLog("触发删除 deleteLeading:$deleteLeading 删除之前【${keys.firstOrNull?.dataKey},${keys.lastOrNull?.dataKey},要删除的元素是:$needDeletekeys");
      return true;
    }());

    /// 创建删除任务
    final visualItemInfo = _findVisualItem();
    if (visualItemInfo != null) {
      /// 添加前直接判断需不需要添加这个删除more事件，因为，可能会存在不需要删除more的情况
      if (needDeletekeys.contains(visualItemInfo.leadingFirstkey.dataKey) ||
          needDeletekeys.contains(visualItemInfo.leadingLastkey.dataKey)) {
        return false;
      }
    }

    _modifyItems(needDeletekeys, PutItemsType.delete);
    return true;
  }
}

class DataSource<T extends Object> {
  Map<InfiniteKey<T>, Widget?> keyItemMap;

  /// 通过tag寻找InfinityKey
  Map<T, InfiniteKey<T>> tagKeyMap = {};

  DataSource({
    required this.keyItemMap,
  });

  factory DataSource.empty() {
    return DataSource(keyItemMap: {});
  }

  void clear() {
    keyItemMap.clear();
    tagKeyMap.clear();
  }
}

class VisualEdgeItemData<T extends Object> {
  InfiniteKey<T> leadingFirstkey;
  InfiniteKey<T> leadingLastkey;
  Rect localLeadingRect; // 在viewport坐标系
  // Rect localTrailingRect; // 在viewport坐标系
  Rect renderFlexRect; // 在viewport的renderFlex坐标系

  RenderBox renderBox;

  VisualEdgeItemData({
    required this.leadingFirstkey,
    required this.leadingLastkey,
    required this.localLeadingRect,
    // required this.localTrailingRect,
    required this.renderBox,
    required this.renderFlexRect,
  });
}

class AccumuateOffset {
  double accumulatedOffset = 0.0;
}

enum KeepVisualWindowsReason {
  none,
  appendLeading,
  deleteLeading,
  both;
}

class WrapReason {
  KeepVisualWindowsReason reason;

  WrapReason() : reason = KeepVisualWindowsReason.none;
}

extension PositionExtension on KeepVisualWindowsReason {
  KeepVisualWindowsReason operator +(KeepVisualWindowsReason other) {
    switch (this) {
      case KeepVisualWindowsReason.none:
        return other;
      case KeepVisualWindowsReason.appendLeading:
        return (other == KeepVisualWindowsReason.deleteLeading || other == KeepVisualWindowsReason.both)
            ? KeepVisualWindowsReason.both
            : this;
      case KeepVisualWindowsReason.deleteLeading:
        return (other == KeepVisualWindowsReason.appendLeading || other == KeepVisualWindowsReason.both)
            ? KeepVisualWindowsReason.both
            : this;
      case KeepVisualWindowsReason.both:
        return KeepVisualWindowsReason.both;
      default:
        return this;
    }
  }
}
