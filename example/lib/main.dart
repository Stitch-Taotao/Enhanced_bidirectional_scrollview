import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'the_map.dart';

void main() {
  runApp(const MyApp());
  if (Platform.isAndroid) {
    RawSocket;
    // 以下两行 设置android状态栏为透明的沉浸。写在组件渲染之后，是为了在渲染后进行set赋值，覆盖状态栏，写在渲染之前MaterialApp组件会覆盖掉这个值。
    const SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(statusBarColor: Colors.transparent);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Image.network;
    SingleTickerProviderStateMixin;
    AnimationController;
    return MaterialApp(
      title: 'Material App',
      home: Scaffold(body: entry),
    );
  }
}
