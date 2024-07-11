import 'package:flutter/material.dart';

import 'SimplePages/simple_list_page.dart' as simple_alias;

typedef WrapRouteFunction = Route Function();

// https://stackoverflow.com/questions/55417201/cannot-install-a-materialpageroutevoid-after-disposing-it
// 这里的包装是必不可少的!!!
class MapToScreenUtil {
  MapToScreenUtil._();
  static MapToScreenUtil? _single;
  static MapToScreenUtil get single => _single ??= MapToScreenUtil._();

  final L = simple_alias.SimpleListPage.new;
  final M = simple_alias.SimpleListModel.new;
  int floor = 0;
  Widget generateAllPages(Map<String, dynamic> config, {String? title}) {
    floor++;
    String? theTitle = title;
    if (floor == 1) {
      // theTitle = config.keys.first;
      theTitle = '主页';
    }

    /// 1. Map<String,Map>
    /// 2. Map<String,Widget>
    /// 3. Map<String,Object>
    if (config is Map<String, Map<String, dynamic>>) {
      /// TODO - 如果只是使用 as 转换是会出错的
      /// 但是使用cast新生成一个数据视图就是可以的！！！
      // final castMap = config.cast<String, Map<String, dynamic>>();
      final newMap = config.map((key, value) {
        return MapEntry(key, generateAllPages(value, title: key));
      });
      return L(model: M(map: newMap, title: theTitle));

      /// MARK - 这里是出错的版本
      // config as Map<String, Map<String, dynamic>>;
      // final newMap = config.map((key, value) {
      //   return MapEntry(key, generateAllPages(value, title: key));
      // });
      // return L(model: M(map: newMap, title: theTitle));
    } else if (config is Map<String, Widget>) {
      return L(model: M(map: config, title: theTitle));
    } else {
      final newMap = config.map<String, Widget>((key, value) {
        /// 1. key value 是 String Map
        /// 2. key value 是 String Widget
        if (value is Map<String, dynamic>) {
          // print(value.runtimeType);
          return MapEntry(key, generateAllPages(value));
        } else {
          return MapEntry(key, value);
        }
      });
      return L(model: M(map: newMap, title: theTitle));
    }
    // print(config.runtimeType);
    // throw Exception('数据定义有误');
    // return Container();
  }
}
