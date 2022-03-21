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
  final void Function() update;

  const CanvasDetailWidget({
    Key? key, 
    required this.project,
    required this.frameImageList, 
    required this.mainBuild, 
    required this.update, 
  }):super(key:key);


  @override
  CanvasDetailWidgetState createState() => CanvasDetailWidgetState();
}

class CanvasDetailWidgetState extends State<CanvasDetailWidget> {
  final TextEditingController canvasSizeYController = TextEditingController();
  final FocusNode canvasSizeYFocusNode = FocusNode();

  void updateTextField(){
    canvasSizeYController.value = canvasSizeYController.value.copyWith( text: widget.project.canvasSize.height.toString() );

    setState(() { });
  }

  bool isFocus(){
    return canvasSizeYFocusNode.hasFocus;
  }

  @override
  void initState(){
    super.initState();
    
    canvasSizeYController.value = canvasSizeYController.value.copyWith( text: widget.project.canvasSize.height.toString() );
  }

  @override
  void dispose(){
    canvasSizeYController.dispose();
    canvasSizeYFocusNode.dispose();

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    Widget textFormWidget(
      TextEditingController editController, FocusNode focusNode, String labeltext, 
      List<TextInputFormatter> formatList, String? Function(String?)? validatorFunc, void Function() onChanged,
    ){
      return TextFormField(
        autovalidateMode: AutovalidateMode.always,
        controller  : editController,
        focusNode   : focusNode,
        decoration      : InputDecoration( labelText: labeltext, ),
        inputFormatters : formatList,
        validator    : validatorFunc,
        onChanged    : (_){ onChanged(); },
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
            textFormWidget(canvasSizeYController, canvasSizeYFocusNode, "縦", [FilteringTextInputFormatter.allow(RegExp('[0123456789.]'))], 
              (String? value){
                if( value == null ) return null;
                return rateStringValidate(value);
              },
              (){
                if(posStringValidate(canvasSizeYController.text) != null ) return;

                widget.update();

                widget.project.canvasSize = Size(widget.project.canvasSize.width, double.parse(canvasSizeYController.text));
                widget.project.save();

                widget.mainBuild();
              }
            ),
          ],
        ),
      ),
    );
  }


}