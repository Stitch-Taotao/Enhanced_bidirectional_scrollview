// import 'dart:async';

import 'package:async/async.dart';

void main(List<String> args) {
  test1();
}

void test1() {
  print("begin test1");
  // CancelableCompleter completer = CancelableCompleter();
  Future.microtask(() {
    print("Future.microtask");
  });
  CancelableOperation operation = CancelableOperation.fromFuture(
    Future.delayed(Duration(seconds: 3), (){
      print("future then test1");
    }),
    onCancel: () {
      print("onCancel test1");
      return Future.delayed(Duration(seconds: 1), () {
        print("onCancel test1 delay");
        return 3;
      });
    },
  );
  
  final res = operation.cancel();
  res.then((value) {
    print("res then test1 - value $value");
  });
  operation.then((value) {
    print("operation then test1 - value $value");
  });
  print("end test1");
}
