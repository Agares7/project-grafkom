import 'dart:ui';
import 'package:flutter/material.dart';
import 'data.dart';

class Painter extends StatefulWidget {
  final PainterController painterController;
  Offset startOffset;
  Offset endOffset;

  Painter(PainterController painterController)
      : this.painterController = painterController,
        super(key: new ValueKey<PainterController>(painterController));

  @override
  _PainterState createState() => new _PainterState();
}

class _PainterState extends State<Painter> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = new CustomPaint(
      willChange: true,
      painter: new _PainterPainter(widget.painterController._pathHistory,
          repaint: widget.painterController),
    );
    child = new ClipRect(child: child);
    child = new GestureDetector(
      child: child,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
    );

    return new Container(
      child: child,
      width: double.infinity,
      height: double.infinity,
    );
  }

  void _onPanStart(DragStartDetails start) {
    if (mode == DrawMode.pencil) {
      Offset pos = (context.findRenderObject() as RenderBox)
          .globalToLocal(start.globalPosition);
      widget.painterController._pathHistory.add(pos);
    } else if (mode == DrawMode.rect) {
      widget.startOffset = (context.findRenderObject() as RenderBox)
          .globalToLocal(start.globalPosition);
    } else if (mode == DrawMode.line) {
      widget.startOffset = (context.findRenderObject() as RenderBox)
          .globalToLocal(start.globalPosition);
      widget.painterController._pathHistory.add(widget.startOffset);
    } else if (mode == DrawMode.triangle || mode == DrawMode.circle) {
      widget.startOffset = (context.findRenderObject() as RenderBox)
          .globalToLocal(start.globalPosition);
    }

    widget.painterController._notifyListeners();
  }

  void _onPanUpdate(DragUpdateDetails update) {
    if (mode == DrawMode.pencil) {
      Offset pos = (context.findRenderObject() as RenderBox)
          .globalToLocal(update.globalPosition);
      widget.painterController._pathHistory.updateCurrent(pos);
    } else {
      widget.endOffset = (context.findRenderObject() as RenderBox)
          .globalToLocal(update.globalPosition);
    }

    widget.painterController._notifyListeners();
  }

  void _onPanEnd(DragEndDetails end) {
    if (mode == DrawMode.rect) {
      widget.painterController._pathHistory
          .addRect(widget.startOffset, widget.endOffset);
    } else if (mode == DrawMode.line) {
      widget.painterController._pathHistory.add(widget.endOffset);
      widget.painterController._pathHistory.updateCurrent(widget.endOffset);
    } else if (mode == DrawMode.triangle) {
      Path path = new Path();
      widget.painterController._pathHistory._drawTriangle(
          path, widget.startOffset, widget.endOffset);
      widget.painterController._pathHistory._paths
          .add(new MapEntry<Path, Paint>(
              path, widget.painterController._pathHistory.currentPaint));
    } else if (mode == DrawMode.circle) {
      Path path = new Path();
      widget.painterController._pathHistory._drawCircle(
          path, widget.startOffset, widget.endOffset);
      widget.painterController._pathHistory._paths
          .add(new MapEntry<Path, Paint>(
              path, widget.painterController._pathHistory.currentPaint));
    }

    widget.painterController._pathHistory.endCurrent();
    widget.painterController._notifyListeners();
  }
}

class _PainterPainter extends CustomPainter {
  final _PathHistory _path;

  _PainterPainter(this._path, {Listenable repaint}) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    _path.draw(canvas, size);
  }

  @override
  bool shouldRepaint(_PainterPainter oldDelegate) {
    return true;
  }
}

class _PathHistory {
  List<MapEntry<Path, Paint>> _paths;
  Paint currentPaint;
  Paint _backgroundPaint;
  bool _inDrag;

  _PathHistory() {
    _paths = new List<MapEntry<Path, Paint>>();
    _inDrag = false;
    _backgroundPaint = new Paint();
  }

  void setBackgroundColor(Color backgroundColor) {
    _backgroundPaint.color = backgroundColor;
  }

  void undo() {
    if (!_inDrag && _paths.isNotEmpty) _paths.removeLast();
  }

  void clear() {
    if (!_inDrag) _paths.clear();
  }

  void add(Offset startPoint) {
    if (!_inDrag) {
      _inDrag = true;
      Path path = new Path();
      if (mode == DrawMode.pencil || mode == DrawMode.line) {
        path.moveTo(startPoint.dx, startPoint.dy);
        _paths.add(new MapEntry<Path, Paint>(path, currentPaint));
      }
    }
  }

  void addRect(Offset startPoint, Offset endPoint) {
    if (!_inDrag && mode == DrawMode.rect) {
      _inDrag = true;
      Path path = new Path();
      path.addRect(Rect.fromLTRB(
          startPoint.dx, startPoint.dy, endPoint.dx, endPoint.dy));
      _paths.add(new MapEntry<Path, Paint>(path, currentPaint));
    }
  }

  void updateCurrent(Offset nextPoint) {
    if (_inDrag) {
      Path path = _paths.last.key;
      path.lineTo(nextPoint.dx, nextPoint.dy);
    }
  }

  void endCurrent() {
    _inDrag = false;
  }

  void _drawTriangle(Path path, Offset startPoint, Offset endPoint) {
    if (!_inDrag && mode == DrawMode.triangle) {
      _inDrag = true;
      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(startPoint.dx, endPoint.dy);
      path.lineTo(endPoint.dx, endPoint.dy);
      path.close();
    }
  }

  void _drawCircle(Path path, Offset startPoint, Offset endPoint) {
    if (!_inDrag && mode == DrawMode.circle) {
      _inDrag = true;
      double radius = (endPoint.dx - startPoint.dx) / 2;
      Offset center = Offset(
          startPoint.dx + radius, startPoint.dy + radius);
      path.addOval(Rect.fromCircle(center: center, radius: radius));
    }
  }

  void draw(Canvas canvas, Size size) {
    canvas.drawRect(
        new Rect.fromLTWH(0.0, 0.0, size.width, size.height), _backgroundPaint);
    for (MapEntry<Path, Paint> path in _paths)
      canvas.drawPath(path.key, path.value);
  }
}

class PainterController extends ChangeNotifier {
  Color _drawColor = selectedColor;
  Color _backgroundColor = new Color.fromARGB(255, 255, 255, 255);

  double _thickness = 1.0;

  _PathHistory _pathHistory;

  PainterController() {
    _pathHistory = new _PathHistory();
  }

  Color get drawColor => _drawColor;

  set drawColor(Color color) {
    _drawColor = color;
    _updatePaint();
  }

  Color get backgroundColor => _backgroundColor;

  set backgroundColor(Color color) {
    _backgroundColor = color;
    _updatePaint();
  }

  double get thickness => _thickness;

  set thickness(double t) {
    _thickness = t;
    _updatePaint();
  }

  void _updatePaint() {
    Paint paint = new Paint();
    paint.color = drawColor;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = thickness;
    _pathHistory.currentPaint = paint;
    _pathHistory.setBackgroundColor(backgroundColor);
    notifyListeners();
  }

  void undo() {
    _pathHistory.undo();
    notifyListeners();
  }

  void _notifyListeners() {
    notifyListeners();
  }

  void clear() {
    _pathHistory.clear();
    notifyListeners();
  }
}
