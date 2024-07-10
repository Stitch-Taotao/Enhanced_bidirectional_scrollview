// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

typedef CompleteCallback<T> = void Function();
typedef CancelCallback = void Function();

enum _Status {
  init,
  complete,
  cancel,
}

class TaskStatus<T> {
  CompleteCallback? _completeCallback;
  CancelCallback? _cancelCallback;
  TaskStatus();
  _Status _status = _Status.init;
  void complete() {
    assert(_status == _Status.init, "只能调用一次");
    _status = _Status.complete;
    _completeCallback?.call();
  }

  void cancel() {
    assert(_status == _Status.init, "只能调用一次");
    _status = _Status.cancel;
    _cancelCallback?.call();
  }

  void listenComplete(CompleteCallback listener) {
    assert(_completeCallback == null, "只能调用一次");
    _completeCallback = listener;
    if (_status == _Status.complete) {
      _completeCallback?.call();
    }
  }

  void listenCancel(VoidCallback listener) {
    assert(_cancelCallback == null, "只能调用一次");
    _cancelCallback = listener;
    if (_status == _Status.cancel) {
      _cancelCallback?.call();
    }
  }
}
