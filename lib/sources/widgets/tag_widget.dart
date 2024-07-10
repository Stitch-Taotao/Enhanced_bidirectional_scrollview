import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../scroll_config/keys.dart';

class TagWidget<T extends Object> extends MetaData {
  const TagWidget({super.key,super.metaData,super.child});
  @override
  InfiniteKey<T> get metaData => super.metaData;

  @override
  RenderTagWidget<T> createRenderObject(BuildContext context) {
    return RenderTagWidget<T>()
      ..metaData = metaData
      ..behavior = behavior;
  }
}

class RenderTagWidget<T extends Object> extends RenderMetaData {
  @override
  InfiniteKey<T> get metaData => super.metaData;
}
