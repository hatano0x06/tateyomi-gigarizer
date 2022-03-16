// import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';
import 'package:tateyomi_gigarizer/model/keyboard.dart';
import 'package:tateyomi_gigarizer/model/project.dart';

class CanvasDetailWidget extends StatefulWidget {
  final Project project;
  final List<FrameImage> frameImageList;
  final void Function() mainBuild;

  const CanvasDetailWidget({
    Key? key, 
    required this.project,
    required this.frameImageList, 
    required this.mainBuild, 
  }):super(key:key);


  @override
  CanvasDetailWidgetState createState() => CanvasDetailWidgetState();
}

class CanvasDetailWidgetState extends State<CanvasDetailWidget> {
  // final TextEditingController canvasSizeXController = TextEditingController();
  final TextEditingController canvasSizeYController = TextEditingController();
  // final FocusNode canvasSizeXFocusNode = FocusNode();
  final FocusNode canvasSizeYFocusNode = FocusNode();

  void updateTextField(){
    // canvasSizeXController.value = canvasSizeXController.value.copyWith( text: widget.project.canvasSize.width.toString() );
    canvasSizeYController.value = canvasSizeYController.value.copyWith( text: widget.project.canvasSize.height.toString() );

    setState(() { });
  }

  bool isFocus(){
    return canvasSizeYFocusNode.hasFocus;
    // return canvasSizeXFocusNode.hasFocus || canvasSizeYFocusNode.hasFocus;
  }

  @override
  void initState(){
    super.initState();
    
    // canvasSizeXController.value = canvasSizeXController.value.copyWith( text: widget.project.canvasSize.width.toString() );
    canvasSizeYController.value = canvasSizeYController.value.copyWith( text: widget.project.canvasSize.height.toString() );

    // canvasSizeXController.addListener((){
    //   if(posStringValidate(canvasSizeXController.text) != null ) return;

    //   double preCanvasWidth = widget.project.canvasSize.width;
    //   double newCanvasWidth = double.parse(canvasSizeXController.text);

    //   if(newCanvasWidth < 100) return;

    //   double changeRate = newCanvasWidth/preCanvasWidth;

    //   for (FrameImage _frameImage in widget.frameImageList) {
    //     _frameImage.position = Point(_frameImage.position.x * changeRate, _frameImage.position.y * changeRate);
    //     _frameImage.sizeRate = _frameImage.sizeRate * changeRate;
    //     _frameImage.save();
    //   }

    //   widget.project.canvasSize = Size(newCanvasWidth, widget.project.canvasSize.height);
    //   widget.project.save();

    //   widget.mainBuild();
    // });    

    canvasSizeYController.addListener((){
      if(posStringValidate(canvasSizeYController.text) != null ) return;

      widget.project.canvasSize = Size(widget.project.canvasSize.width, double.parse(canvasSizeYController.text));
      widget.project.save();

      widget.mainBuild();
    });   

  }

  @override
  void dispose(){
    // canvasSizeXController.dispose();
    canvasSizeYController.dispose();
    // canvasSizeXFocusNode.dispose();
    canvasSizeYFocusNode.dispose();

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    Widget textFormWidget(TextEditingController editController, FocusNode focusNode, String labeltext, List<TextInputFormatter> formatList, String? Function(String?)? validatorFunc){
      return TextFormField(
        autovalidateMode: AutovalidateMode.always,
        controller  : editController,
        focusNode   : focusNode,
        decoration      : InputDecoration( labelText: labeltext, ),
        inputFormatters : formatList,
        validator    : validatorFunc,
      );
    }

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all( color: Colors.black, )
      ),
      child: Padding(
        padding : const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child   : Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child :  Text("キャンパスサイズの編集", style: TextStyle( fontWeight: FontWeight.bold), ),
            ),
            // textFormWidget(canvasSizeXController, canvasSizeXFocusNode, "幅", [FilteringTextInputFormatter.allow(RegExp('[0123456789.]'))], 
            //   (String? value){
            //     if( value == null ) return null;
            //     return rateStringValidate(value);
            //   }
            // ),
            textFormWidget(canvasSizeYController, canvasSizeYFocusNode, "縦", [FilteringTextInputFormatter.allow(RegExp('[0123456789.]'))], 
              (String? value){
                if( value == null ) return null;
                return rateStringValidate(value);
              }
            ),
          ],
        ),
      ),
    );
  }


}