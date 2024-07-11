import 'dart:async';

import '../utils/logs/log_config.dart';

void main(List<String> args) {
  test1();
}

void test1() {
  final complter = Completer.sync();
  final future = complter.future;
  future.then((value) {
    mtLog('then1: $value');
  });
  future.then((value) {
    mtLog('then2: $value');
  });
  future.then((value) {
    mtLog('then3: $value');
  });

  complter.complete('hello');
  mtLog("end");
}
