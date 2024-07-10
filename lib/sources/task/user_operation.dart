import 'package:flutter/foundation.dart';

import '../scroll_config/keys.dart';

/// 用户期望的操作
abstract class UserExpectOperation<T extends Object> {
  final Future<List<T>> keys;
  final UserExpectOpEnum opType;
  final T? showKey;
  final Tag? showTag;
  final double releateOffset;
  UserExpectOperation({
    required this.opType,
    required this.keys,
    this.showKey,
    this.showTag,
    this.releateOffset = 0.0,
  });
  UserExpectOperation.sync({
    required this.opType,
    required List<T> keys,
    this.showKey,
    this.showTag,
    this.releateOffset = 0.0,
  }) : keys = SynchronousFuture(keys);
}

class User {}

class UserInitOperation<T extends Object> extends UserExpectOperation<T> {
  UserInitOperation({required super.keys, super.showKey, super.showTag, super.releateOffset}) : super.sync(opType: UserExpectOpEnum.init);
}

class UserHandleOperation<T extends Object> extends UserExpectOperation<T> {
  void checkAssert() {}
  UserHandleOperation.sync({
    required super.opType,
    required super.keys,
    super.showKey,
    super.showTag,
    super.releateOffset,
  }) : super.sync();
}

class UserAppendOperation<T extends Object> extends UserHandleOperation<T> {
  @override
  void checkAssert() {
    final useExpect = opType;
    assert(useExpect == UserExpectOpEnum.appendLeading || useExpect == UserExpectOpEnum.appdendTrailing, "只有这两种类型");
  }

  // UserAppendOperation({required UserAppendOpType type, required super.keys, super.showKey, super.showTag, super.releateOffset})
  //     : super(opType: convertTypeToEnum(type));
  UserAppendOperation.sync({required UserAppendOpType type, required List<T> keys, super.showKey, super.showTag, super.releateOffset})
      : super.sync(keys: keys, opType: convertAppendTypeToAll(type));
}

class UserReplaceOperation<T extends Object> extends UserHandleOperation<T> {
  UserReplaceOperation.sync({required List<T> keys, super.showKey, super.showTag, super.releateOffset})
      : super.sync(keys: keys, opType: UserExpectOpEnum.replace);
}

enum UserAppendOpType {
  appendLeading,
  appdendTrailing,
}

UserExpectOpEnum convertAppendTypeToAll(UserAppendOpType type) {
  UserExpectOpEnum enumValue;
  switch (type) {
    case UserAppendOpType.appendLeading:
      enumValue = UserExpectOpEnum.appendLeading;
      break;
    case UserAppendOpType.appdendTrailing:
      enumValue = UserExpectOpEnum.appdendTrailing;
      break;
  }
  return enumValue;
}

enum UserExpectOpEnum {
  none,
  init,
  appendLeading,
  appdendTrailing,
  replace,
}
