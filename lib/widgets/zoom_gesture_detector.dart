import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

///
/// Created by Kozári László in 2020.01.01
/// lostinwar22@gmail.com
///

class ZoomGestureDetector extends StatefulWidget {
  final Widget child;
  final void Function(Offset initialPoint) onPanStart;
  final void Function(Offset initialPoint, Offset delta) onPanUpdate;
  final void Function() onPanEnd;
  final void Function(Offset initialFocusPoint) onScaleStart;
  final void Function(Offset changedFocusPoint, double scale) onScaleUpdate;
  final void Function() onScaleEnd;
  final void Function(double dx) onHorizontalDragUpdate;
  final void Function(double dy) onVerticalDragUpdate;
  final int panDistanceToActivate;

  const ZoomGestureDetector({
    this.child,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onHorizontalDragUpdate,
    this.onVerticalDragUpdate,
    this.panDistanceToActivate
  });

  @override
  _ZoomGestureDetectorState createState() => _ZoomGestureDetectorState();
}

class _ZoomGestureDetectorState extends State<ZoomGestureDetector> {
  final List<Touch> _touches = [];
  double _initialScalingDistance;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      child: widget.child,
      gestures: {
        ImmediateMultiDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<ImmediateMultiDragGestureRecognizer>(
          () => ImmediateMultiDragGestureRecognizer(),
          (ImmediateMultiDragGestureRecognizer instance) {
            instance.onStart = (Offset offset) {
              final touch = Touch(
                offset,
                (drag, details) => _onTouchUpdate(drag, details),
                (drag, details) => _onTouchEnd(drag, details),
              );
              _onTouchStart(touch);
              return touch;
            };
          },
        ),
      },
    );
  }

  void _onTouchStart(Touch touch) {
    _touches.add(touch);
    if (_touches.length == 1) {
      if (widget.onPanStart != null) widget.onPanStart(touch._startOffset);
    } else if (_touches.length == 2) {
      _initialScalingDistance = (_touches[0]._currentOffset - _touches[1]._currentOffset).distance;
      if (widget.onScaleStart != null) widget.onScaleStart((_touches[0]._currentOffset + _touches[1]._currentOffset) / 2);
    }
  }

  void _onTouchUpdate(Touch touch, DragUpdateDetails details) {
    assert(_touches.isNotEmpty);
    touch._currentOffset = details.localPosition;

    if (_touches.length == 1) {
      if (widget.onPanUpdate != null) widget.onPanUpdate(touch._startOffset, details.localPosition - touch._startOffset);

      if (widget.onHorizontalDragUpdate != null) {
        final dx = (details.localPosition.dx - touch._startOffset.dx).abs();
        if (dx > widget.panDistanceToActivate ?? 50) widget.onHorizontalDragUpdate((details.localPosition.dx - touch._startOffset.dx).clamp(-2.0, 2.0));
      }

      if (widget.onVerticalDragUpdate != null) {
        final dy = (details.localPosition.dy - touch._startOffset.dy).abs();
        if (dy > widget.panDistanceToActivate ?? 50) widget.onVerticalDragUpdate((details.localPosition.dy - touch._startOffset.dy).clamp(-2.0, 2.0));
      }

    } else {
      var newDistance = (_touches[0]._currentOffset - _touches[1]._currentOffset).distance;

      if (widget.onScaleUpdate != null) widget.onScaleUpdate((_touches[0]._currentOffset + _touches[1]._currentOffset) / 2, newDistance / _initialScalingDistance);
    }
  }

  void _onTouchEnd(Touch touch, DragEndDetails details) {
    _touches.remove(touch);
    if (_touches.length == 0) {
      if (widget.onPanEnd != null) widget.onPanEnd();
    } else if (_touches.length == 1) {
      if (widget.onScaleEnd != null) widget.onScaleEnd();

      _touches[0]._startOffset = _touches[0]._currentOffset;
      if (widget.onPanStart != null) widget.onPanStart(_touches[0]._startOffset);
    }
  }
}

class Touch extends Drag {
  Offset _startOffset;
  Offset _currentOffset;

  final void Function(Drag drag, DragUpdateDetails details) onUpdate;
  final void Function(Drag drag, DragEndDetails details) onEnd;

  Touch(this._startOffset, this.onUpdate, this.onEnd) {
    _currentOffset = _startOffset;
  }

  @override
  void update(DragUpdateDetails details) {
    super.update(details);
    onUpdate(this, details);
  }

  @override
  void end(DragEndDetails details) {
    super.end(details);
    onEnd(this, details);
  }
}
