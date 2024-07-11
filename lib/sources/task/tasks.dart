// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../scroll_config/keys.dart';
import '../utils/frame_util.dart';
import '../utils/logs/log_config.dart';
import 'errors.dart';
import 'task_manager.dart';
import 'task_status.dart';
import 'user_operation.dart';

enum TaskType {
  appendLeading,
  appendTrailing,
}

/// 【只考虑点击是同步进行的，不存在点击是异步的情况】
/// 1.只要手动点击了替换，那么必须要取消掉同帧其他的保持滚动的任务
/// 2.将添加、添加导致的删除和保持滚动分开成三个任务
/// 3.假设还有一个主动删除，并保持滚动位置
///
///
///
/// 我们把任务排个序，但是先不执行，在persisitent开始的时候统一执行，比如：build前执行
/// 那么保持滚动的事件就可以统一处理，只处理一个了。

extension DebugObjectExt on Object {
  String get debugHash => "（hash:$hashCode）";
  String get debugRuntimeType => "（运行时类型:$runtimeType）";
}

enum TaskState {
  init,
  readyToComplete, //准备去完成，但是真正完成是在persisitent阶段之前统一处理的。
  complete,
  cancel,
}

enum TaskAddStrategy {
  appendInTrailing, // 追加到列表最后
  appendInLeadingCancelOhter, // 追加到最前面，并且将其他任务统统移除掉
  noAppend, // 压根不追加。
}

abstract class Task<T extends Object> {
  // static Task<ST> runTask<ST extends Object>(Task<ST> task) {
  //   task._intialiaze();
  //   return task;
  // }

  final TaskManager<T> manager;
  final Completer<int> _doneCompleter = Completer();
  // late CancelableOperation<int> _cancelableOperation;

  /// 任务是否完成
  /// 1 代表完成
  /// 2 代表被取消
  /// 3 代表由于排斥，未被追加上
  /// 可取消的操作
  // Future<int> get isDone => _cancelableOperation.value;
  late TaskStatus<T> _taskStatus;
  TaskStatus<T> get taskStatus => _taskStatus;

  /// 创建任务的帧数
  late int initFrameCount;
  SchedulerPhase get phase => FrameUtil.phase;
  String get debugPhase => FrameUtil.debugPhase;

  /// 任务准备好去完成的帧数,注意不代表就执行任务的内容，执行的内容全部安排在persisitent阶段之前处理
  late int readyFrameCount;
  TaskState state = TaskState.init;
  Task({
    required this.manager,
  }) {
    _intialiaze();
  }

  void _intialiaze() {
    // _cancelableOperation = CancelableOperation.fromFuture(_doneCompleter.future);
    _taskStatus = TaskStatus<T>();
    initFrameCount = FrameUtil.frameCount;
    bool taskIsAdd = false;
    switch (canAddTask()) {
      case TaskAddStrategy.noAppend:
        doneState(3);
        break;
      case TaskAddStrategy.appendInTrailing:
        // manager.allOriginTask.add(this);
        taskIsAdd = tryAddOriginTask();
        break;
      case TaskAddStrategy.appendInLeadingCancelOhter:
        bool run = true;
        while (run) {
          final allTasks = manager.getAllOriginTasks();
          if (allTasks.isNotEmpty) {
            final task = allTasks.removeLast();
            task.cancel(reason: "由于$debugIdentify 的策略是‘appendInLeadingCancelOhter’ 所以移除了已添加的任务${task.debugIdentify}");
            // allTasks.add(this);
          } else {
            run = false;
          }
        }
        taskIsAdd = tryAddOriginTask();
        break;
    }
    if (taskIsAdd) {
      tryReady();
    }
  }

  /// 这个任务可以添加
  TaskAddStrategy canAddTask();
  bool tryAddOriginTask();

  /// 尝试准备任务
  void tryReady() {
    ready();
  }

  bool get isFinished {
    return state == TaskState.complete || state == TaskState.cancel;
  }

  void ready() {
    readyFrameCount = FrameUtil.frameCount;
    mtLog("$debugIdentify - 完成前后： 前:$initFrameCount, 后:$readyFrameCount $debugPhase");
    _debugAssertReadyPhase();
    assert(state == TaskState.init);
    state = TaskState.readyToComplete;
    manager.addMicroTask(this);
  }

  String get debugIdentify => " - TASK：$debugRuntimeType$debugHash$shouldOverrideDetailDesc";
  String get shouldOverrideDetailDesc => "";
  void _debugAssertReadyPhase() {
    assert(() {
      /// 只要不是微任务，就一定是在idel阶段完成的。
      final lphase = phase;

      /// || phase == SchedulerPhase.transientCallbacks
      /// 我们暂且认为，所有的任务触发不可能在transientCallbacks，也就是说不会由动画来触发产生任务
      /// 其实就算是动画产生的，只要我们没有执行，那么就一直存在

      /// phase == SchedulerPhase.persistentCallbacks 阶段可能性是：初始化的时候执行了JumpToExistKeyTask
      /// 对于其他情况，即便是同步执行，也是应该idle 或者transientCallbacks阶段
      /// 还有在middleMicroTask阶段出现的可能性，不过暂时还未想好这种情况，如有遇到，可以向作者反馈场景，帮助调查。

      ///这种情况已经不可能发生了，因为我们保证初始化的过程不通过Task来执行跳转！
      // final right = phase == SchedulerPhase.idle || phase == SchedulerPhase.persistentCallbacks;
      final right = phase == SchedulerPhase.idle;
      if (!right) {
        /// 如果由动画触发的添加任务，并且之后异步任务请求是同步完成的，那么就是transientCallbacks阶段
        /// 目前假定没有在微任务阶段完成的任务，如果有的话，可能需要做一个延迟处理机制，但是目前暂时没有发现微任务完成任务的情况
        if (lphase == SchedulerPhase.transientCallbacks) {
          final appendTask = this as AppendTask<T>;
          if (appendTask.maySyncFuture is SynchronousFuture) {
            return true;
          } else {
            return false;
          }
        }
      }
      return right;
    }(), "如果不是ideal阶段完成，莫非还有在middleMicro阶段完成？");

    /// 有没有可能是在微任务触发？
  }

  String get _debugCompleteOrCancelReason => "状态state:$state,原因是:$_completeOrCancelReason";

  String? _completeOrCancelReason;
  void complete({required String reason}) {
    assert(_completeOrCancelReason == null);
    assert(FrameUtil.phase == SchedulerPhase.midFrameMicrotasks, "目前我们处理的流程是固定在midMicro进行完成的，如有变动请仔细检查该动情况");
    _completeOrCancelReason = reason;
    state = TaskState.complete;
    manager.removeTask(this);
    doneState(1);
    mtLog("$debugIdentify 完成:$_debugCompleteOrCancelReason $debugPhase");
  }

  void cancel({required String reason}) {
    assert(_completeOrCancelReason == null);
    _completeOrCancelReason = reason;
    assert(state == TaskState.init || state == TaskState.readyToComplete);
    state = TaskState.cancel;
    manager.removeTask(this);
    doneState(2);
    mtLog("任务$debugIdentify 取消:$_completeOrCancelReason");
  }

  /// 整体任务完成情况
  void doneState(int i) {
    assert(i == 1 || i == 2 || i == 3);
    switch (i) {
      case 1:
        _taskStatus.complete();
        break;
      case 2:
        _taskStatus.cancel();
        // _cancelableOperation.cancel();
        break;
      case 3:
        _taskStatus.cancel();
        // _cancelableOperation.cancel();
        break;
      default:
    }
    _doneCompleter.complete(i);
  }

  /// 每个任务在准备好后，就可能存在修改数据的操作
  ModifyDataOp<T>? modifyDataOp;

  /// 是否需要调整位置
  // AbsAdjustPixelEvent<T>? adjustPixelEvent;
}

mixin MixinAsyncReadyTask<T extends Object> {
  /// 准备阶段完成之后触发的的监听，这里我们将待添加的keys暴露出来
  void Function(AppendTask<T>) get whenReady;
}

/// 添加任务
class AppendTask<T extends Object> extends Task<T> with MixinAsyncReadyTask<T> {
  Future<List<T>> asyncTask;
  bool appendLeading;

  Completer<List<T>>? _completer;
  bool _isSync = false;
  late Future<List<T>> maySyncFuture;

  /// 准备阶段完成之后触发的的监听，这里我们将待添加的keys暴露出来
  @override
  void Function(AppendTask<T>) whenReady;
  AppendTask({
    required super.manager,
    required this.asyncTask,
    required this.appendLeading,
    required this.whenReady,
  });
  @override
  void _intialiaze() {
    if (asyncTask is SynchronousFuture) {
      _isSync = true;
      maySyncFuture = asyncTask;
    } else {
      // _completer = Completer();
      _completer = Completer.sync();

      maySyncFuture = _completer!.future;
      asyncTask.then((value) {
        /// 有可能，在任务触发之前就已经cacel了，那么就不能完成了
        if (!_completer!.isCompleted) {
          _completer!.complete(value);
        }
      });
    }
    super._intialiaze();
  }

  @override
  void cancel({required String reason}) {
    /// 只有非同步的才有必要取消
    if (!_isSync && !isFinished) {
      if (!_completer!.isCompleted) {
        _completer!.completeError(CancelTaskError());
      }
    }
    super.cancel(reason: reason);
  }

  Future<List<T>> get _then => maySyncFuture;
  @override
  TaskAddStrategy canAddTask() {
    bool canAppend = false;
    canAppend = manager.canAddAppendTask(appendLeading);
    return canAppend ? TaskAddStrategy.appendInTrailing : TaskAddStrategy.noAppend;
  }

  List<T>? keys;
  @override
  Future<void> tryReady() async {
    try {
      keys = await _then;
      if (isFinished) {
        mtLog("任务$debugIdentify 已经完成，完成原因：$_completeOrCancelReason");
        assert(false, "已经完成了? - 原因：$_completeOrCancelReason");
        return;
      }
      // task.complete();
    } on CancelTaskError {
      /// 主动触发取消任务无需做任何事情
      mtLog("【X】主动取消任务，$debugIdentify,$_debugCompleteOrCancelReason,原本要添加的元素是: $keys");
      // cancel(reason: "请求发生了错误，导致整个任务退出");
      return;
    } finally {
      if (keys == null) {
        // 正在取消,还未取消
        assert(state != TaskState.cancel);
      } else if (keys!.isEmpty) {
        cancel(reason: "$debugIdentify : 因为追加的数据是空的列表，所以取消该任务");
      } else {
        /// 应对可能出现的在midMicroTask完成的情况,好像处理与不处理都是没有任何问题的
        /// 假设统一处理所有任务和新来的任务叫A，B
        /// 如果A发生在B之前，那么B在本帧处理数据和跳转的操作不会触发，而是留到下一帧或者之后某一帧处理（要注意的是，如果一直没刷新，
        /// 那么这个任务会导致所有后续的添加追加任务无法添加进来，因为追加任务一直加不进来，没任务能触发modifyAndJump，这个任务一直
        /// 不释放，死锁了）
        /// 同时还有一个问题就是，这一帧结束，taskManager中还有一个persisitent任务。。。
        if (FrameUtil.phase == SchedulerPhase.midFrameMicrotasks) {
          /// TODO:
          assert(false, "待调查分析");
        }
        super.tryReady();
      }
    }
  }

  @override
  String get shouldOverrideDetailDesc => " [详细描述 --- 任务类型是：添加${appendLeading ? "Leading" : "Trailing"}] ";
  @override
  void ready() {
    super.ready();
    assert(keys != null && keys!.isNotEmpty);
    whenReady(this);
    modifyDataOp = AppendDataOp(task: this, keys: keys!, appendLeading: appendLeading);
  }

  @override
  void complete({required String reason}) {
    super.complete(reason: reason);
    assert(keys != null && keys!.isNotEmpty);
  }

  @override
  AppendDataOp<T>? get modifyDataOp => super.modifyDataOp as AppendDataOp<T>?;

  @override
  bool tryAddOriginTask() {
    if (manager.canAddAppendTask(appendLeading)) {
      manager.addOriginTask(this);
      return true;
    }
    return false;
  }
}

/// 用户主动触发的任务
abstract class UserTask<T extends Object> extends Task<T> {
  UserTask({required super.manager});

  @override
  TaskAddStrategy canAddTask() {
    return TaskAddStrategy.appendInLeadingCancelOhter;
  }

  @override
  bool tryAddOriginTask() {
    manager.debugOriginTaskIsEmpty(info: "所有主动由Uer触发的任务，在添加时任务列表一定是空，因为其他任务已经全部移除掉了");
    manager.addOriginTask(this);
    return true;
  }
}

// /// 手动触发删除
// class UserDeleteTask<T extends Object> extends UserTask<T> {
//   final List<T> keys;
//   UserDeleteTask({
//     required super.manager,
//     required this.keys,
//   });
//   @override
//   void ready() {
//     super.ready();
//     modifyDataOp = DeleteDataOp(task: this, keys: keys);
//   }
// }

// /// 替换任务
// class UserReplaceTask<T extends Object> extends UserTask<T> {
//   final List<T> keys;
//   UserReplaceTask({
//     required super.manager,
//     required this.keys,
//   });
//   @override
//   void ready() {
//     super.ready();
//     modifyDataOp = ReplaceDataOp(task: this, keys: keys);
//   }

//   @override
//   ReplaceDataOp<T>? get modifyDataOp => super.modifyDataOp as ReplaceDataOp<T>?;
// }

/// 跳转到某个位置
/// 要么是主动跳转到已知的某个位置，这个是没有依赖的
class JumpToExistKeyTask<T extends Object> extends UserTask<T> {
  T? tag;
  Tag? showTag;
  double releateOffset;
  JumpToExistKeyTask({
    required super.manager,
    required this.tag,
    this.showTag,
    this.releateOffset = 0.0,
  });
}

/// 要么是主动跳转到某个未知的位置
/// 可能是追加、替换 + 跳转
class JumpToNoExistTask<T extends Object> extends UserTask<T> {
  JumpToNoExistTask({required super.manager, required this.operation});
  UserReplaceOperation<T> operation;

}

/// 每一帧，有几个阶段
/// 修改数据阶段
/// 触发自动删除数据阶段
/// 跳转位置阶段
/// 对于已经到达准备好状态的任务，在persisitent完成的时候必须要结束

/// 修改数据
abstract class ModifyDataOp<T extends Object> {
  /// 父类的task是什么
  Task<T> task;

  ModifyDataOp({
    required this.task,
  });
}

class AppendDataOp<T extends Object> extends ModifyDataOp<T> {
  final List<T> keys;
  final bool appendLeading;
  AppendDataOp({
    required super.task,
    required this.keys,
    required this.appendLeading,
  });
}

/// 明确指出的删除数据应该是什么
class DeleteDataOp<T extends Object> extends ModifyDataOp<T> {
  final List<T> keys;
  DeleteDataOp({required this.keys, required super.task});
}

/// 明确指出替换后的数据应该是什么
class ReplaceDataOp<T extends Object> extends ModifyDataOp<T> {
  final List<T> keys;
  ReplaceDataOp({required this.keys, required super.task});
}

/// 被动触发删除多少数据，这个不属于任何任务触发，只是每次都会进行检测处理！
/// 检测依据是，检查头部删除一半会不会包含当前屏幕可见区域，不会则删除头部，
/// 否则，检测尾部删除一半会不会包含当前屏幕可见区域，不会则删除尾部，否则，删除尾部
/// 如果删除了头部，则会要求保持屏幕位置
/// 另外要求本次任务类型必须是追加任务（AppendTask触发的才会进行自动删除，其他暂时放任不管）
// class NeedAutoDeleteMoreData<T extends Object> {
//   NeedAutoDeleteMoreData();
// }

/// ------ 修改pixel的事件
abstract class AbsAdjustPixelEvent<T extends Object> {
  /// 父类的task是什么
  Task<T> task;
  AbsAdjustPixelEvent({
    required this.task,
  });
}

// class ApAutoKeepVisualWindow<T extends Object> extends AbsAdjustPixelEvent<T> {
//   ApAutoKeepVisualWindow({required super.task});
// }

class ApJumpToExistKey<T extends Object> extends AbsAdjustPixelEvent<T> {
  final T jumpToKey;
  ApJumpToExistKey({
    required this.jumpToKey,
    required super.task,
  });
}
