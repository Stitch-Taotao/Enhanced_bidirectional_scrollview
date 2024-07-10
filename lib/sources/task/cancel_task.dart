// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/foundation.dart';

typedef CompleteCallback<T> = void Function(T value);
typedef CancelCallback = void Function({required Object? error});

/// 取消保证执行的是cancelCallback
/// 并且是同步执行取消调用
/// 不保证取消task任务
class CancelTask<T> {
  Future<T> task;
  CompleteCallback? completeCallback;
  CancelCallback? cancelCallback;
  CancelTask({
    this.completeCallback,
    this.cancelCallback,
    required this.task,
  }) {
    _init();
  }
  void _init() {
    if (task is SynchronousFuture) {
      task.then((value) {
        completeCallback?.call(value);
      });
    } else {
      task.then((value) {
        completeCallback?.call(value);
      }).onError((error, stackTrace) {
        cancelCallback?.call(error: error);
      });
      _completer.future.then((value) {
        completeCallback?.call(value);
      }).catchError((e) {
        if (e is _CancelTaskError) {
          cancelCallback?.call(error: null);
        } else {
          cancelCallback?.call(error: e);
          assert(false);
        }
      });
    }
  }

  final Completer<T> _completer = Completer.sync();

  void cancel() {
    _completer.completeError(_CancelTaskError());
  }

  void complete() {
    _completer.complete();
  }
}

class _CancelTaskError {}
