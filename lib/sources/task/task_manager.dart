import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../scroll_config/scroll_infinite_controller.dart';
import '../utils/frame_util.dart';
import '../utils/log_util.dart';
import '../utils/logs/log_config.dart';
import 'tasks.dart';

class TaskManager<T extends Object> {
  InfiniteScorllController<T> infiniteScorllController;
  AppendTask<T>? get _appendLeadingTask {
    final filtTasks = _allOriginTask.where((element) {
      return (element is AppendTask<T>) && element.appendLeading;
    }).cast<AppendTask<T>>();
    assert(filtTasks.length <= 1, "最多只能存在一个task");
    if (filtTasks.length == 1) {
      assert(!filtTasks.first.isFinished, "因为期望finish和在是否在manager中是绑定死的");
    }
    return filtTasks.isEmpty ? null : filtTasks.first;
  }

  AppendTask<T>? get _appendTrailingTask {
    // _TypeError (type 'WhereIterable<Task<int>>' is not a subtype of type 'Iterable<AppendTask<int>>' in type cast)
    // final filtTasks = _allOriginTask.where((element) {
    //   return (element is AppendTask<T>) && !element.appendLeading;
    // }) as Iterable<AppendTask<T>>;
    final filtTasks = Iterable.castFrom<Task, AppendTask<T>>(_allOriginTask.where((element) {
      return (element is AppendTask<T>) && !element.appendLeading;
    }));
    assert(filtTasks.length <= 1, "最多只能存在一个task");
    if (filtTasks.length == 1) {
      assert(!filtTasks.first.isFinished, "因为期望finish和在是否在manager中是绑定死的");
    }
    return filtTasks.isEmpty ? null : filtTasks.first;
  }

  void removeTask(Task<T> task) {
    _allOriginTask.remove(task);
    _microTasks.remove(task);
  }
  /// 移除所有的任务
  void clearAllTask() {
    _allOriginTask.clear();
    _microTasks.clear();
  }

  bool get hasHighLevelTask {
    final filtTasks = _allOriginTask.whereType<UserTask<T>>();
    return filtTasks.isNotEmpty;
  }

  bool get _canAppendLeading {
    return !hasHighLevelTask && _appendLeadingTask == null;
  }

  bool get _canAppendTrailing {
    return !hasHighLevelTask && _appendTrailingTask == null;
  }

  bool canAddAppendTask(bool appendLeading) {
    if (appendLeading) {
      return _canAppendLeading;
    } else {
      return _canAppendTrailing;
    }
  }

  /// 所有原始触发的任务，不包括附带的任务
  /// 比如：【触发添加的更多】任务属于原始任务，而任务准备好之后又添加删除元素任务和保持屏幕滚动任务非原始任务
  /// 【主动跳转到已知位置】，属于原始任务
  /// 【主动跳转到未知位置】属于原始任务， 但是引起的添加更多任务，以及附带的删除元素任务、跳转到指定key任务为非原始任务
  /// 【主动跳转到未知位置】属于原始任务， 但是引起的删除元素任务、跳转到指定key
  ///
  /// 原始任务有个特点，是除了添加更多任务，最多可以出现两个添加更多任务（一个头部，一个尾部），其他的都是互斥的，同时只能有一个！
  final List<Task<T>> _allOriginTask = [];
  List<Task> getAllOriginTasks() {
    return _allOriginTask;
  }

  void addOriginTask(Task<T> task) {
    _allOriginTask.add(task);
  }

  void debugOriginTaskIsEmpty({String? info}) {
    assert(_allOriginTask.isEmpty, info ?? "原始任务此时一定为空");
  }

  void debugBuildTaskIsEmpty({String? info}) {
    assert(_microTasks.isEmpty, info ?? "build任务此时一定为空");
  }

  /// 所有当前帧需要处理的任务
  final List<Task> _microTasks = [];
  List<Task> getAllMicroTasks() {
    return _microTasks;
  }

  void addMicroTask(Task task) {
    _microTasks.add(task);

    /// 只要添加了任务，则就需要主动触发hook，以便处理事件
    assert(FrameUtil.phase != SchedulerPhase.midFrameMicrotasks,
        "可能需要考虑，如果是在mid微任务阶段触发了任务准备好，会出现什么问题？，因为这种情况一般场景不会出现，暂时图省事先不做考虑了，如果你遇到必须在微任务完成的场景，触发了该断言，你可以报告给作者");
    assert(FrameUtil.phase != SchedulerPhase.persistentCallbacks, "目前初始化跳转不会添加任务，所以不可能出现在persistent阶段任务准备完成的情况");
    addTransientCallbacks();
  }

  /// hasAddTransitentCallback
  bool hasAddTransitentCallback = false;
  TaskManager({
    required this.infiniteScorllController,
  });

  /// 首先，我希望所有的任务都在构建前进行统一处理，
  /// 1.所以要么在build中添加hook来拿到这个时间节点，而且在build中hook的方式必须触发build才行
  /// 2.要么就是在build之前，layout之后，同理可以在layout之后，或者paint过程中添加hook
  /// 3.要么就是添加到微任务队列中，没有任何hook的方式，如果在动画阶段，添加的话没有任何问题
  ///   如果在idle阶段，则添加的微任务会在build和layout之前触发，不满足需求
  void addTransientCallbacks() {
    mtLog("addTransientCallbacks");
    if (hasAddTransitentCallback) {
      return;
    }
    hasAddTransitentCallback = true;
    int beginFrame = FrameUtil.frameCount;
    // ignore: unused_local_variable
    final stackTrace = StackTrace.current;

    /// 如果由动画触发的添加任务，并且之后异步任务请求是同步完成的，那么就是transientCallbacks阶段
    /// transientCallbacks阶段添加transientCallback任务不会在当地立即触了，必须等到下一帧才行
    /// 因此会出现即使是同步任务，仍然非同帧加载
    final phase = FrameUtil.phase;
    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      mtLog("scheduleFrameCallback");
      int transitentFrame = FrameUtil.frameCount;
      Future.microtask(() {
        int micFrame = FrameUtil.frameCount;
        assert(() {
          if (beginFrame == transitentFrame && beginFrame == micFrame) {
            /// 只有最初的任务是build阶段触发，所以可能会出现微任务发生在下一帧
            /// 但是我们在添加任务的时候做一下处理即可。
            return true;
          } else {
            assert(phase == SchedulerPhase.transientCallbacks, "先不考虑mid微任务阶段");
            return true;
          }
          // return false;
        }(), "应该是完全一致的");
        // try {
        mtLog("微任务modifyDataAndCorrectPixelCallback处理之前",tag: TagsConfig.tagTestMicroQues);
        infiniteScorllController.modifyDataAndCorrectPixelCallback();
        mtLog("微任务modifyDataAndCorrectPixelCallback处理之后",tag: TagsConfig.tagTestMicroQues);

        // } catch (e) {
        //   /// TODO 如何比较好的处理进入时间循环的堆栈信息呢？
        //   mtLog("(((------");
        //   mtLog(e);
        //   debugPrintStack(stackTrace: stackTrace, maxFrames: 10, label: "未捕获到的错误");
        //   mtLog("------)))");
        //   assert(false);
        //   rethrow;
        // }
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      hasAddTransitentCallback = false;
    });
  }
}
