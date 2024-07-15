// ignore_for_file: avoid_print

import 'dart:async';


void main(List<String> args) {
  test1();
}

void test1() {
  final complter = Completer.sync();
  final future = complter.future;
  future.then((value) {
    print('then1: $value');
  });
  future.then((value) {
    print('then2: $value');
  });
  future.then((value) {
    print('then3: $value');
  });

  complter.complete('hello');
  print("end");
}
