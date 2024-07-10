import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../scroll_config/viewport.dart';

class MTSingleChildScrollView extends StatelessWidget {
  /// Creates a box in which a single widget can be scrolled.
  const MTSingleChildScrollView({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.padding,
    this.primary,
    this.physics,
    this.controller,
    this.child,
    this.dragStartBehavior = DragStartBehavior.start,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  }) : assert(
         !(controller != null && (primary ?? false)),
         'Primary ScrollViews obtain their ScrollController via inheritance '
         'from a PrimaryScrollController widget. You cannot both set primary to '
         'true and pass an explicit controller.',
       );

  /// {@macro flutter.widgets.scroll_view.scrollDirection}
  final Axis scrollDirection;

  /// Whether the scroll view scrolls in the reading direction.
  ///
  /// For example, if the reading direction is left-to-right and
  /// [scrollDirection] is [Axis.horizontal], then the scroll view scrolls from
  /// left to right when [reverse] is false and from right to left when
  /// [reverse] is true.
  ///
  /// Similarly, if [scrollDirection] is [Axis.vertical], then the scroll view
  /// scrolls from top to bottom when [reverse] is false and from bottom to top
  /// when [reverse] is true.
  ///
  /// Defaults to false.
  final bool reverse;

  /// The amount of space by which to inset the child.
  final EdgeInsetsGeometry? padding;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  ///
  /// Must be null if [primary] is true.
  ///
  /// A [ScrollController] serves several purposes. It can be used to control
  /// the initial scroll position (see [ScrollController.initialScrollOffset]).
  /// It can be used to control whether the scroll view should automatically
  /// save and restore its scroll position in the [PageStorage] (see
  /// [ScrollController.keepScrollOffset]). It can be used to read the current
  /// scroll position (see [ScrollController.offset]), or change it (see
  /// [ScrollController.animateTo]).
  final ScrollController? controller;

  /// {@macro flutter.widgets.scroll_view.primary}
  final bool? primary;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics? physics;

  /// The widget that scrolls.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// {@macro flutter.widgets.scrollable.restorationId}
  final String? restorationId;

  /// {@macro flutter.widgets.scroll_view.keyboardDismissBehavior}
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  AxisDirection _getDirection(BuildContext context) {
    return getAxisDirectionFromAxisReverseAndDirectionality(context, scrollDirection, reverse);
  }

  @override
  Widget build(BuildContext context) {
    final AxisDirection axisDirection = _getDirection(context);
    Widget? contents = child;
    if (padding != null) {
      contents = Padding(padding: padding!, child: contents);
    }
    final bool effectivePrimary = primary
        ?? controller == null && PrimaryScrollController.shouldInherit(context, scrollDirection);

    final ScrollController? scrollController = effectivePrimary
        ? PrimaryScrollController.maybeOf(context)
        : controller;

    Widget scrollable = Scrollable(
      dragStartBehavior: dragStartBehavior,
      axisDirection: axisDirection,
      controller: scrollController,
      physics: physics,
      restorationId: restorationId,
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        return MTSingleChildViewport(
          axisDirection: axisDirection,
          offset: offset,
          clipBehavior: clipBehavior,
          child: contents,
        );
      },
    );

    if (keyboardDismissBehavior == ScrollViewKeyboardDismissBehavior.onDrag) {
      scrollable = NotificationListener<ScrollUpdateNotification>(
        child: scrollable,
        onNotification: (ScrollUpdateNotification notification) {
          final FocusScopeNode focusNode = FocusScope.of(context);
          if (notification.dragDetails != null && focusNode.hasFocus) {
            focusNode.unfocus();
          }
          return false;
        },
      );
    }

    return effectivePrimary && scrollController != null
      // Further descendant ScrollViews will not inherit the same
      // PrimaryScrollController
      ? PrimaryScrollController.none(child: scrollable)
      : scrollable;
  }
}
class MTSingleChildViewport extends SingleChildRenderObjectWidget {
  const MTSingleChildViewport({super.key, 
    this.axisDirection = AxisDirection.down,
    required this.offset,
    super.child,
    required this.clipBehavior,
  });

  final AxisDirection axisDirection;
  final ViewportOffset offset;
  final Clip clipBehavior;

  @override
  MTRenderSingleChildViewport createRenderObject(BuildContext context) {
    return MTRenderSingleChildViewport(
      axisDirection: axisDirection,
      offset: offset,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, MTRenderSingleChildViewport renderObject) {
    // Order dependency: The offset setter reads the axis direction.
    renderObject
      ..axisDirection = axisDirection
      ..offset = offset
      ..clipBehavior = clipBehavior;
  }

  @override
  SingleChildRenderObjectElement createElement() {
    return _SingleChildViewportElement(this);
  }
}

class _SingleChildViewportElement extends SingleChildRenderObjectElement with NotifiableElementMixin, ViewportElementMixin {
  _SingleChildViewportElement(MTSingleChildViewport super.widget);
}
