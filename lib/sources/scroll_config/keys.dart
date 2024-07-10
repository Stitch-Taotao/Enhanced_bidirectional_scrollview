import 'package:flutter/material.dart';

class Tagkey<T extends Tag> extends ValueKey<T> {
  const Tagkey(
    super.value,
  );
  @override
  bool operator ==(covariant Tagkey<T> other) {
    if (identical(this, other)) return true;

    return other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

class Tag {
  final Object category;
  Tag({
    required this.category,
  });

  @override
  bool operator ==(covariant Tag other) {
    if (identical(this, other)) return true;

    return other.category == category;
  }

  @override
  int get hashCode => category.hashCode;
}

class InfiniteKey<T extends Object> {
  
  final T dataKey;
  InfiniteKey({
    required this.dataKey,
  });
  final GlobalKey globalKey = GlobalKey();

  @override
  bool operator ==(covariant InfiniteKey other) {
    if (identical(this, other)) return true;

    return other.dataKey == dataKey;
  }

  @override
  int get hashCode => dataKey.hashCode;
}

// class AnchorWidget<T extends Object> extends SingleChildRenderObjectWidget {
//   const AnchorWidget({required Tagkey<T> key, super.child}) : super(key: key);

//   @override
//   RenderObject createRenderObject(BuildContext context) {
//     return RenderAnchorWidget();
//   }
// }

// class RenderAnchorWidget extends RenderProxyBox {}

// class Tagkey<T extends Object, Tag extends Object> extends ValueKey<InfiniteKey<T>> {
//   const Tagkey(super.value, {required this.tag});
//   final Tag tag;
// }
