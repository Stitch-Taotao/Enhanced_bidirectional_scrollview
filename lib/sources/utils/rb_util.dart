import 'package:flutter/material.dart';

import '../scroll_config/keys.dart';


abstract class RbUtil {
  /// 寻找最近的自己的RenderObject或者子孙RenderObject
  static RenderObject? findNearstRenderObject(Element element) {
    RenderObject? nearstChildRenderObject;
    nearstChildRenderObject = element.findRenderObject();
    nearstChildRenderObject ??= findNearstChildRenderObject(element);
    return nearstChildRenderObject;
  }

  /// 找到最近的子RenderElement
  static RenderObject? findNearstChildRenderObject(Element sElement) {
    RenderObject? tRb;

    /// 查找到对应的element
    sElement.visitChildElements((element) {
      if (element is RenderObjectElement && tRb == null) {
        tRb = element.renderObject;
      } else {
        tRb = findNearstChildRenderObject(element);
      }
    });
    return tRb;
  }

  static Element? findChildElementByTag(Element sElement, Tagkey tagKey) {
    Element? tElement;

    /// 查找到对应的element
    sElement.visitChildElements((element) {
      if (element.widget.key == tagKey) {
        tElement = element;
      } else {
        tElement = findChildElementByTag(element, tagKey);
      }
    });
    return tElement;
  }
}
