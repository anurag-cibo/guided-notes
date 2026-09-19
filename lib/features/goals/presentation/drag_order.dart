import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum OrderKind { goal, milestone }

class OrderDrag {
  OrderDrag(this.kind, this.id, {this.goalId});
  final OrderKind kind;
  final int id;
  final int? goalId;
  Offset anchor = Offset.zero;
}

/// Long press keeps ordinary taps and scrolling available without an edit mode.
/// Group headers also use this as a drop-only target, including empty groups.
class DragOrder extends StatefulWidget {
  const DragOrder({
    super.key,
    this.data,
    required this.accepts,
    required this.onDrop,
    required this.child,
    this.enabled = true,
  });
  final OrderDrag? data;
  final bool Function(OrderDrag) accepts;
  final void Function(OrderDrag, bool after) onDrop;
  final Widget child;
  final bool enabled;

  @override
  State<DragOrder> createState() => _DragOrderState();
}

class _DragOrderState extends State<DragOrder>
    with AutomaticKeepAliveClientMixin {
  bool _after = false;
  bool _dragging = false;
  bool _cancelled = false;
  EdgeDraggingAutoScroller? _scroller;
  Offset? _pointer;
  OrderDrag? _activeData;

  void _scrollAtPointer() {
    if (mounted && _dragging && _pointer != null) {
      _scroller?.startAutoScrollIfNecessary(
        Rect.fromCenter(center: _pointer!, width: 1, height: 100),
      );
    }
  }

  // A stationary finger can have a new target after auto-scrolling. Resolve the
  // current hit path on release rather than using the last pointer-move target.
  void _dropAt(Offset pointer, OrderDrag data) {
    final hits = HitTestResult();
    WidgetsBinding.instance.hitTestInView(
      hits,
      pointer,
      View.of(context).viewId,
    );
    for (final hit in hits.path) {
      final render = hit.target;
      if (render is RenderMetaData && render.metaData is _DragOrderState) {
        final target = render.metaData as _DragOrderState;
        if (target.mounted &&
            target.widget.enabled &&
            target.widget.data?.id != data.id &&
            target.widget.accepts(data)) {
          target.widget.onDrop(data, target._isAfter(pointer));
          return;
        }
      }
    }
  }

  @override
  bool get wantKeepAlive => _dragging;

  @override
  void dispose() {
    _pointer = null;
    _scroller?.stopAutoScroll();
    super.dispose();
  }

  bool _isAfter(Offset position) {
    final box = context.findRenderObject()! as RenderBox;
    return box.globalToLocal(position).dy > box.size.height / 2;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!widget.enabled) return widget.child;
    return Listener(
      onPointerDown: (_) => _cancelled = false,
      onPointerCancel: (_) => _cancelled = true,
      child: MetaData(
        metaData: this,
        behavior: HitTestBehavior.translucent,
        child: DragTarget<OrderDrag>(
          onWillAcceptWithDetails: (details) =>
              details.data.id != widget.data?.id &&
              widget.accepts(details.data),
          onMove: (details) {
            final after = _isAfter(details.offset + details.data.anchor);
            if (after != _after) setState(() => _after = after);
          },
          builder: (context, candidates, rejected) {
            final targeted = candidates.isNotEmpty;
            final child = Stack(
              children: [
                widget.child,
                Positioned(
                  top: _after && widget.data != null ? null : 0,
                  bottom: _after && widget.data != null ? 0 : null,
                  left: 4,
                  right: 4,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: targeted ? 1 : 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            );
            if (widget.data == null) return child;
            return LayoutBuilder(
              builder: (context, constraints) {
                return LongPressDraggable<OrderDrag>(
                  axis: Axis.vertical,
                  data: widget.data,
                  dragAnchorStrategy: (draggable, context, position) {
                    final anchor = childDragAnchorStrategy(
                      draggable,
                      context,
                      position,
                    );
                    widget.data!.anchor = anchor;
                    _activeData = widget.data;
                    return anchor;
                  },
                  delay: const Duration(milliseconds: 600),
                  maxSimultaneousDrags: 1,
                  feedback: InheritedTheme.captureAll(
                    context,
                    Material(
                      elevation: 8,
                      color: Theme.of(context).colorScheme.surface,
                      clipBehavior: Clip.antiAlias,
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: widget.child,
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(opacity: .22, child: child),
                  onDragStarted: () {
                    _dragging = true;
                    updateKeepAlive();
                    final scrollable = Scrollable.maybeOf(context);
                    if (scrollable != null) {
                      _scroller = EdgeDraggingAutoScroller(
                        scrollable,
                        velocityScalar: 12,
                        onScrollViewScrolled: _scrollAtPointer,
                      );
                    }
                  },
                  onDragUpdate: (details) {
                    _pointer = details.globalPosition;
                    _scrollAtPointer();
                  },
                  onDragEnd: (details) {
                    _scroller?.stopAutoScroll();
                    _pointer = null;
                    final data = _activeData;
                    if (!_cancelled && data != null) {
                      _dropAt(details.offset + data.anchor, data);
                    }
                    _activeData = null;
                    _dragging = false;
                    updateKeepAlive();
                  },
                  child: child,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
