import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';
import 'package:tateyomi_gigarizer/model/keyboard.dart';
import 'package:tateyomi_gigarizer/model/project.dart';

import 'dart:math' as math;

class FrameDetailWidget extends StatefulWidget {
  final Project project;
  final FrameImage focusFrame;
  final List<FrameImage> focusFrameDependList;
  final void Function() mainBuild;

  const FrameDetailWidget({
    Key? key, 
    required this.project,
    required this.focusFrame, 
    required this.focusFrameDependList, 
    required this.mainBuild, 
  }):super(key:key);


  @override
  FrameDetailWidgetState createState() => FrameDetailWidgetState();
}

class FrameDetailWidgetState extends State<FrameDetailWidget> {
  final TextEditingController framePosXController = TextEditingController();
  final TextEditingController framePosYController = TextEditingController();
  final TextEditingController frameSizeRateController = TextEditingController();
  final FocusNode framePosXFocusNode = FocusNode();
  final FocusNode framePosYFocusNode = FocusNode();
  final FocusNode frameSizeRateFocusNode = FocusNode();

  void updateTextField(){
    framePosXController.value = framePosXController.value.copyWith( text: widget.focusFrame.position.x.toString() );
    framePosYController.value = framePosYController.value.copyWith( text: widget.focusFrame.position.y.toString() );
    frameSizeRateController.value = frameSizeRateController.value.copyWith( text: widget.focusFrame.sizeRate.toString() );

    setState(() { });
  }

  bool isFocus(){
    return framePosXFocusNode.hasFocus || framePosYFocusNode.hasFocus || frameSizeRateFocusNode.hasFocus;
  }

  @override
  void initState(){
    super.initState();
    
    framePosXController.value = framePosXController.value.copyWith( text: widget.focusFrame.position.x.toString() );
    framePosYController.value = framePosYController.value.copyWith( text: widget.focusFrame.position.y.toString() );
    frameSizeRateController.value = frameSizeRateController.value.copyWith( text: widget.focusFrame.sizeRate.toString() );

    framePosXController.addListener((){
      if(posStringValidate(framePosXController.text) != null ) return;

      widget.focusFrame.position = Point<double>(double.parse(framePosXController.text), widget.focusFrame.position.y);
      widget.focusFrame.save();

      widget.mainBuild();
    });    

    framePosYController.addListener((){
      if(posStringValidate(framePosYController.text) != null ) return;

      double prePosY = widget.focusFrame.position.y;
      double newPosY = double.parse(framePosYController.text);

      widget.focusFrame.position = Point<double>(widget.focusFrame.position.x, newPosY);
      widget.focusFrame.save();

      double diffY = prePosY - newPosY;
      for (FrameImage _depandFrame in widget.focusFrameDependList) {
        _depandFrame.position = Point(_depandFrame.position.x, _depandFrame.position.y-diffY);
        _depandFrame.save();
      }

      widget.mainBuild();
    });    

    frameSizeRateController.addListener((){
      if(rateStringValidate(frameSizeRateController.text) != null ) return;

      double _rate = double.parse(frameSizeRateController.text);
      _rate = math.max(_rate, 0.01);

      double preBottom = widget.focusFrame.rotateSize.y * widget.focusFrame.sizeRate;
      double newBottom = widget.focusFrame.rotateSize.y * _rate;

      widget.focusFrame.sizeRate = _rate;
      widget.focusFrame.save();

      double diffY = preBottom - newBottom;
      for (FrameImage _depandFrame in widget.focusFrameDependList) {
        _depandFrame.position = Point(_depandFrame.position.x, _depandFrame.position.y-diffY);
        _depandFrame.save();
      }

      widget.mainBuild();
    });
  }

  @override
  void dispose(){
    framePosXController.dispose();
    framePosYController.dispose();
    frameSizeRateController.dispose();

    framePosXFocusNode.dispose();
    framePosYFocusNode.dispose();
    frameSizeRateFocusNode.dispose();

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
              child :  Text("コマの編集", style: TextStyle( fontWeight: FontWeight.bold), ),
            ),
            textFormWidget(framePosXController, framePosXFocusNode, "X位置", [FilteringTextInputFormatter.allow(RegExp('[0123456789.-]'))], 
              (String? value){
                if( value == null ) return null;
                return posStringValidate(value);
              }
            ),
            textFormWidget(framePosYController, framePosYFocusNode, "Y位置", [FilteringTextInputFormatter.allow(RegExp('[0123456789.-]'))], 
              (String? value){
                if( value == null ) return null;
                return posStringValidate(value);
              }
            ),
            textFormWidget(frameSizeRateController, frameSizeRateFocusNode, "大きさ倍率", [FilteringTextInputFormatter.allow(RegExp('[0123456789.]'))], 
              (String? value){
                if( value == null ) return null;
                return rateStringValidate(value);
              }
            ),
            Container(
              padding   : const EdgeInsets.symmetric(vertical: 10),
              alignment : Alignment.centerLeft,
              child : Text("右端からの距離 : " + (widget.project.canvasSize.width - (widget.focusFrame.position.x + widget.focusFrame.rotateSize.x * widget.focusFrame.sizeRate)).toString() ),
            ),
            Align(
              alignment : Alignment.centerLeft,
              child     : IconButton(
                icon: const Icon(Icons.rotate_right_outlined),
                onPressed: (){
                  widget.focusFrame.angle += 1;
                  widget.focusFrame.angle = widget.focusFrame.angle%4;
                  widget.mainBuild();
                }, 
              )
            )
          ],
        ),
      ),
    );
  }


}