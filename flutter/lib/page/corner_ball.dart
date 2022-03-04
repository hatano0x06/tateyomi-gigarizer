import 'package:flutter/material.dart';

class CornerBallWidget extends StatefulWidget {
    final Function onDrag;

    const CornerBallWidget({
      Key? key, 
      required this.onDrag, 
    }):super(key:key);


    @override
    _CornerBallWidgetState createState() => _CornerBallWidgetState();
  }

  class _CornerBallWidgetState extends State<CornerBallWidget> {
    double? initX;
    double? initY;

    _handleDrag(details) {
      setState(() {
        initX = details.globalPosition.dx;
        initY = details.globalPosition.dy;
      });
    }

    _handleUpdate(details) {
      var dx = details.globalPosition.dx - initX;
      var dy = details.globalPosition.dy - initY;
      initX = details.globalPosition.dx;
      initY = details.globalPosition.dy;
      widget.onDrag(dx, dy);
    }

    @override
    Widget build(BuildContext context) {
      double ballDiameter = 20;
      return GestureDetector(
        onPanStart: _handleDrag,
        onPanUpdate: _handleUpdate,
        child: Container(
          width: ballDiameter,
          height: ballDiameter,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
  }