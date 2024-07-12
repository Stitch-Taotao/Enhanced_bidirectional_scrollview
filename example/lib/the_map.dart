import 'package:flutter/material.dart';

import 'page_tools/map_to_listview.dart';

import 'pages/sync/auto_sync.dart' as auto_sync;
import 'pages/sync/drag_sync.dart' as drag_sync;
import 'pages/async/auto_async.dart' as auto_async;
import 'pages/async/drag_async.dart' as drag_async;

final root = <String, dynamic>{
  "同步": {
    '自动加载': auto_sync.Home(),
    '下拉加载': drag_sync.Home(),
  },
  "异步": {
    '自动加载': auto_async.Home(),
    '下拉加载': drag_async.Home(),
  },
};
Widget entry = MapToScreenUtil.single.generateAllPages(root);
