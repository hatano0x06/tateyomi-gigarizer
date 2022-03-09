import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CornerBallWidget extends StatefulWidget {
  final Function() onDragStart;
  final Function(Offset) onDrag;
  final Function() onDragEnd;
  final double ballDiameter;
  final SystemMouseCursor cursor;

  const CornerBallWidget({
    Key? key, 
    required this.onDragStart, 
    required this.onDrag, 
    required this.onDragEnd, 
    required this.ballDiameter, 
    required this.cursor, 
  }):super(key:key);


  @override
  _CornerBallWidgetState createState() => _CornerBallWidgetState();
}

class _CornerBallWidgetState extends State<CornerBallWidget> {
  _handleStart(DragStartDetails details) {
    widget.onDragStart();
  }

  _handleUpdate(DragUpdateDetails details) {
    widget.onDrag(Offset(details.globalPosition.dx, details.globalPosition.dy - kToolbarHeight));
  }

  _handleEnd(DragEndDetails details) {
    widget.onDragEnd();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor  : widget.cursor,
      child   : GestureDetector(
        onPanStart  : _handleStart,
        onPanUpdate : _handleUpdate,
        onPanEnd    : _handleEnd,
        child: Container(
          width: widget.ballDiameter,
          height: widget.ballDiameter,
          decoration: const BoxDecoration(
            color: Colors.blue,
            // color: Colors.blue.withOpacity(200),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}