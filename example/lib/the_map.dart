import 'package:flutter/material.dart';

import 'page_tools/map_to_listview.dart';

import 'pages/combine_eaxmple.dart' as combine;

final root = <String, dynamic>{
  '综合例子': const combine.Home(),
};
Widget entry = MapToScreenUtil.single.generateAllPages(root);
