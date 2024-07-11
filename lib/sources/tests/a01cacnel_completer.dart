// import 'dart:async';

import 'package:async/async.dart';

import '../utils/logs/log_config.dart';

void main(List<String> args) {
  test1();
}

void test1() {
  mtLog("begin test1");
  // CancelableCompleter completer = CancelableCompleter();
  Future.microtask(() {
    mtLog("Future.microtask");
  });
  CancelableOperation operation = CancelableOperation.fromFuture(
    Future.delayed(Duration(seconds: 3), (){
      mtLog("future then test1");
    }),
    onCancel: () {
      mtLog("onCancel test1");
      return Future.delayed(Duration(seconds: 1), () {
        mtLog("onCancel test1 delay");
        return 3;
      });
    },
  );
  
  final res = operation.cancel();
  res.then((value) {
    mtLog("res then test1 - value $value");
  });
  operation.then((value) {
    mtLog("operation then test1 - value $value");
  });
  mtLog("end test1");
}
