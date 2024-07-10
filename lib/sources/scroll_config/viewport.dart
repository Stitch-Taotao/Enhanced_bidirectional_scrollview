import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;

import 'scroll_position.dart';

class MTRenderSingleChildViewport extends RenderBox with RenderObjectWithChildMixin<RenderBox> implements RenderAbstractViewport {
  MTRenderSingleChildViewport({
    AxisDirection axisDirection = AxisDirection.down,
    required ViewportOffset offset,
    RenderBox? child,
    required Clip clipBehavior,
  })  : _axisDirection = axisDirection,
        _offset = offset,
        _clipBehavior = clipBehavior {
    this.child = child;
  }

  AxisDirection get axisDirection => _axisDirection;
  AxisDirection _axisDirection;
  set axisDirection(AxisDirection value) {
    if (value == _axisDirection) {
      return;
    }
    _axisDirection = value;
    markNeedsLayout();
  }

  Axis get axis => axisDirectionToAxis(axisDirection);

  MTScrollPositionWithSingleContext get offset => _offset as MTScrollPositionWithSingleContext;
  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    if (value == _offset) {
      return;
    }
    if (attached) {
      _offset.removeListener(_hasScrolled);
    }
    _offset = value;
    if (attached) {
      _offset.addListener(_hasScrolled);
    }
    markNeedsLayout();
  }

  @override
  void markNeedsLayout() {
    /// 方便调试
    super.markNeedsLayout();
  }

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none], and must not be null.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.none;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  void _hasScrolled() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void setupParentData(RenderObject child) {
    // We don't actually use the offset argument in BoxParentData, so let's
    // avoid allocating it at all.
    if (child.parentData is! ParentData) {
      child.parentData = ParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(_hasScrolled);
  }

  @override
  void detach() {
    _offset.removeListener(_hasScrolled);
    super.detach();
  }

  @override
  bool get isRepaintBoundary => true;

  double get _viewportExtent {
    assert(hasSize);
    switch (axis) {
      case Axis.horizontal:
        return size.width;
      case Axis.vertical:
        return size.height;
    }
  }

  double get _minScrollExtent {
    assert(hasSize);
    return 0.0;
  }

  double get _maxScrollExtent {
    assert(hasSize);
    if (child == null) {
      return 0.0;
    }
    switch (axis) {
      case Axis.horizontal:
        return math.max(0.0, child!.size.width - size.width);
      case Axis.vertical:
        return math.max(0.0, child!.size.height - size.height);
    }
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    switch (axis) {
      case Axis.horizontal:
        return constraints.heightConstraints();
      case Axis.vertical:
        return constraints.widthConstraints();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child != null) {
      return child!.getMinIntrinsicWidth(height);
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child != null) {
      return child!.getMaxIntrinsicWidth(height);
    }
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null) {
      return child!.getMinIntrinsicHeight(width);
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null) {
      return child!.getMaxIntrinsicHeight(width);
    }
    return 0.0;
  }

  // We don't override computeDistanceToActualBaseline(), because we
  // want the default behavior (returning null). Otherwise, as you
  // scroll, it would shift in its parent if the parent was baseline-aligned,
  // which makes no sense.

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (child == null) {
      return constraints.smallest;
    }
    final Size childSize = child!.getDryLayout(_getInnerConstraints(constraints));
    return constraints.constrain(childSize);
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    if (child == null) {
      size = constraints.smallest;
    } else {
      child!.layout(_getInnerConstraints(constraints), parentUsesSize: true);
      size = constraints.constrain(child!.size);
    }
    offset.applyViewportDimension(_viewportExtent);
    offset.applyContentDimensions(_minScrollExtent, _maxScrollExtent);

    /// JMT CHANGE
    // ignore: unnecessary_this
    final scollPositon = this.offset;
    int taskLength = scollPositon.betweenTasks.length;
    // print("performLayout");
    while (scollPositon.betweenTasks.isNotEmpty) {
      final task = scollPositon.betweenTasks.removeFirst();
      task();
      taskLength--;
    }
    assert(taskLength == 0, "执行task过程中不能添加新的任务，否则可能造成死锁");
  }

  /// JMT -Change 这里是不对的，因为position的改变是在layout之前可能就改变无数次，所以这里不能用offset.pixels
  Offset get _paintOffset => _jmtOffset;
  Offset _jmtOffset = Offset.zero;

  /// 上一次绘制的偏移值
  Offset preOffset = Offset.zero;

  /// 这一帧绘制完毕之后的偏移值
  Offset get currentOffset => _paintOffset;
  Offset _paintOffsetForPosition(double position) {
    switch (axisDirection) {
      case AxisDirection.up:
        return Offset(0.0, position - child!.size.height + size.height);
      case AxisDirection.down:
        return Offset(0.0, -position);
      case AxisDirection.left:
        return Offset(position - child!.size.width + size.width, 0.0);
      case AxisDirection.right:
        return Offset(-position, 0.0);
    }
  }

  bool _shouldClipAtPaintOffset(Offset paintOffset) {
    assert(child != null);
    switch (clipBehavior) {
      case Clip.none:
        return false;
      case Clip.hardEdge:
      case Clip.antiAlias:
      case Clip.antiAliasWithSaveLayer:
        return paintOffset.dx < 0 || paintOffset.dy < 0 || paintOffset.dx + child!.size.width > size.width || paintOffset.dy + child!.size.height > size.height;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    /// paint之前，设置偏移之前调用回调
    // for (var element in this.offset.controller.beforeUpdateItems) {
    //   element();
    // }
    // this.offset.controller.beforeUpdateItems.clear();

    // /// JMT CHANGE
    // final scollPositon = this.offset;
    // int taskLength = scollPositon.betweenTasks.length;
    // // print("performLayout");

    // if (scollPositon.betweenTasks.isNotEmpty) {
    //   assert(taskLength == scollPositon.betweenTasks.length, "执行task过程中不能添加新的任务，否则可能造成死锁");
    //   final task = scollPositon.betweenTasks.removeFirst();
    //   taskLength -= 1;
    //   task();
    // }
    _jmtOffset = _paintOffsetForPosition(this.offset.pixels);
    if (child != null) {
      final Offset paintOffset = _paintOffset;

      void paintContents(PaintingContext context, Offset offset) {
        context.paintChild(child!, offset + paintOffset);
      }

      if (_shouldClipAtPaintOffset(paintOffset)) {
        _clipRectLayer.layer = context.pushClipRect(
          needsCompositing,
          offset,
          Offset.zero & size,
          paintContents,
          clipBehavior: clipBehavior,
          oldLayer: _clipRectLayer.layer,
        );
      } else {
        _clipRectLayer.layer = null;
        paintContents(context, offset);
      }
    }
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer = LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final Offset paintOffset = _paintOffset;
    // print("applyPaintTransform - paintOffset : $paintOffset");
    transform.translate(paintOffset.dx, paintOffset.dy);
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject? child) {
    if (child != null && _shouldClipAtPaintOffset(_paintOffset)) {
      return Offset.zero & size;
    }
    return null;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (child != null) {
      return result.addWithPaintOffset(
        offset: _paintOffset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position + -_paintOffset);
          return child!.hitTest(result, position: transformed);
        },
      );
    }
    return false;
  }

  @override
  RevealedOffset getOffsetToReveal(RenderObject target, double alignment, {Rect? rect,Axis? axis}) {
    rect ??= target.paintBounds;
    if (target is! RenderBox) {
      return RevealedOffset(offset: offset.pixels, rect: rect);
    }

    final RenderBox targetBox = target;
    final Matrix4 transform = targetBox.getTransformTo(child);
    final Rect bounds = MatrixUtils.transformRect(transform, rect);
    final Size contentSize = child!.size;

    final double leadingScrollOffset;
    final double targetMainAxisExtent;
    // ignore: unused_local_variable
    final double mainAxisExtent;

    switch (axisDirection) {
      case AxisDirection.up:
        mainAxisExtent = size.height;
        leadingScrollOffset = contentSize.height - bounds.bottom;
        targetMainAxisExtent = bounds.height;
      case AxisDirection.right:
        mainAxisExtent = size.width;
        leadingScrollOffset = bounds.left;
        targetMainAxisExtent = bounds.width;
      case AxisDirection.down:
        mainAxisExtent = size.height;
        leadingScrollOffset = bounds.top;
        targetMainAxisExtent = bounds.height;
      case AxisDirection.left:
        mainAxisExtent = size.width;
        leadingScrollOffset = contentSize.width - bounds.right;
        targetMainAxisExtent = bounds.width;
    }

    /// JMT - CHANGE
    final double targetOffset = leadingScrollOffset - (mainAxisExtent - targetMainAxisExtent) * alignment;
    // final double targetOffset = leadingScrollOffset + (targetMainAxisExtent) * alignment;
    final Rect targetRect = bounds.shift(_paintOffsetForPosition(targetOffset));
    return RevealedOffset(offset: targetOffset, rect: targetRect);
  }

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (!offset.allowImplicitScrolling) {
      return super.showOnScreen(
        descendant: descendant,
        rect: rect,
        duration: duration,
        curve: curve,
      );
    }
    final Rect? newRect = RenderViewportBase.showInViewport(
      descendant: descendant,
      viewport: this,
      offset: offset,
      rect: rect,
      duration: duration,
      curve: curve,
    );
    super.showOnScreen(
      rect: newRect,
      duration: duration,
      curve: curve,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('offset', _paintOffset));
  }

  @override
  Rect describeSemanticsClip(RenderObject child) {
    final double remainingOffset = _maxScrollExtent - offset.pixels;
    switch (axisDirection) {
      case AxisDirection.up:
        return Rect.fromLTRB(
          semanticBounds.left,
          semanticBounds.top - remainingOffset,
          semanticBounds.right,
          semanticBounds.bottom + offset.pixels,
        );
      case AxisDirection.right:
        return Rect.fromLTRB(
          semanticBounds.left - offset.pixels,
          semanticBounds.top,
          semanticBounds.right + remainingOffset,
          semanticBounds.bottom,
        );
      case AxisDirection.down:
        return Rect.fromLTRB(
          semanticBounds.left,
          semanticBounds.top - offset.pixels,
          semanticBounds.right,
          semanticBounds.bottom + remainingOffset,
        );
      case AxisDirection.left:
        return Rect.fromLTRB(
          semanticBounds.left - remainingOffset,
          semanticBounds.top,
          semanticBounds.right + offset.pixels,
          semanticBounds.bottom,
        );
    }
  }

  /// JMT ADD
  /// 滚动到指定的子节点的指定位置
  void scrollToRenderInBound({
    RenderObject? descendant,
    double scrollOffset = 0.0,
    bool needTrickPaint = true, // 主动触发paint
    bool needStopScroll = true,
  }) {
    if (descendant == null) {
      return;
    }
    final RevealedOffset leadingEdgeOffset = getOffsetToReveal(descendant, 0.0, rect: Rect.zero);
    var descendantOffset = leadingEdgeOffset.offset;
    final targetOffset = descendantOffset + scrollOffset;

    /// 判断一下如果要滚动的位置，超出了最大滚动的范围，就只滚动到最大返回即可
    /// 当前的滚动位置相比目标滚动位置的大小，来决定判断是最小滚动和最大滚动问题
    // final currentOffset = offset.pixels;
    double realTarget = targetOffset;
    // if (currentOffset < targetOffset) {
    //   if (targetOffset >= _maxScrollExtent) {
    //     realTarget = _maxScrollExtent;
    //   }
    // } else if (currentOffset > targetOffset) {
    //   if (targetOffset < 0.0) {
    //     return;
    //   }
    // }
    if (targetOffset >= _maxScrollExtent) {
      realTarget = _maxScrollExtent;
    } else if (targetOffset <= _minScrollExtent) {
      realTarget = _minScrollExtent;
    }
    if (needStopScroll) {
      offset.stopAndSetPixel(realTarget);
    } else {
      offset.justSetPixel(realTarget);
    }
    if (needTrickPaint) {
      offset.notifyListeners();
    }
    // }
  }

  /// JMT ADD
  /// 滚动到指定的子节点的指定位置
  void scrollToOffsetUnBound({
    double scrollOffset = 0.0,
    bool needTrickLisiner = true, // 主动触发paint
    bool needStopScroll = true,
  }) {
    // final oldOffset = offset.pixels;
    // print("oldOffset : $oldOffset");
    // final targetOffset = oldOffset + scrollOffset;
    final targetOffset = scrollOffset;
    // if (targetOffset != null) {
    if (needStopScroll) {
      offset.stopAndSetPixel(targetOffset);
    } else {
      offset.justSetPixel(targetOffset);
    }
    if (needTrickLisiner) {
      offset.notifyListeners();
    }
  }

  /// 返回指定的子节点指定位置需要滚动到的偏移量
  double? getDesendentOffsetToReveal({
    RenderObject? descendant,
    Rect? rect,
    required ViewportOffset offset,
  }) {
    if (descendant == null) {
      return null;
    }
    final RevealedOffset leadingEdgeOffset = getOffsetToReveal(descendant, 0.0, rect: rect);
    final RevealedOffset trailingEdgeOffset = getOffsetToReveal(descendant, 1.0, rect: rect);
    final double currentOffset = offset.pixels;

    final RevealedOffset targetOffset;
    if (leadingEdgeOffset.offset < trailingEdgeOffset.offset) {
      // `descendant` is too big to be visible on screen in its entirety. Let's
      // align it with the edge that requires the least amount of scrolling.
      final double leadingEdgeDiff = (offset.pixels - leadingEdgeOffset.offset).abs();
      final double trailingEdgeDiff = (offset.pixels - trailingEdgeOffset.offset).abs();
      targetOffset = leadingEdgeDiff < trailingEdgeDiff ? leadingEdgeOffset : trailingEdgeOffset;
    } else if (currentOffset > leadingEdgeOffset.offset) {
      // `descendant` currently starts above the leading edge and can be shown
      // fully on screen by scrolling down (which means: moving viewport up).
      targetOffset = leadingEdgeOffset;
    } else if (currentOffset < trailingEdgeOffset.offset) {
      // `descendant currently ends below the trailing edge and can be shown
      // fully on screen by scrolling up (which means: moving viewport down)
      targetOffset = trailingEdgeOffset;
    } else {
      // `descendant` is between leading and trailing edge and hence already
      //  fully shown on screen. No action necessary.
      assert(parent != null);
      return null;
    }
    return targetOffset.offset;
  }
}
