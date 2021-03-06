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
  final void Function() delete;
  final void Function(List<FrameImage>) update;

  const FrameDetailWidget({
    Key? key, 
    required this.project,
    required this.focusFrame, 
    required this.focusFrameDependList, 
    required this.mainBuild, 
    required this.delete, 
    required this.update, 
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
    framePosXController.value = framePosXController.value.copyWith( text: widget.focusFrame.position.x.toStringAsFixed(3) );
    framePosYController.value = framePosYController.value.copyWith( text: widget.focusFrame.position.y.toStringAsFixed(3) );
    frameSizeRateController.value = frameSizeRateController.value.copyWith( text: widget.focusFrame.sizeRate.toStringAsFixed(3) );

    setState(() { });
  }

  bool isFocus(){
    return framePosXFocusNode.hasFocus || framePosYFocusNode.hasFocus || frameSizeRateFocusNode.hasFocus;
  }

  @override
  void initState(){
    super.initState();
    
    framePosXController.value = framePosXController.value.copyWith( text: widget.focusFrame.position.x.toStringAsFixed(3) );
    framePosYController.value = framePosYController.value.copyWith( text: widget.focusFrame.position.y.toStringAsFixed(3) );
    frameSizeRateController.value = frameSizeRateController.value.copyWith( text: widget.focusFrame.sizeRate.toStringAsFixed(3) );
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

    Widget textFormWidget(
      TextEditingController editController, 
      FocusNode focusNode, 
      String labeltext, 
      List<TextInputFormatter> formatList, 
      String? Function(String?)? validatorFunc,
      void Function() onChanged,
    ){
      return TextFormField(
        autovalidateMode: AutovalidateMode.always,
        controller  : editController,
        focusNode   : focusNode,
        decoration      : InputDecoration( labelText: labeltext, ),
        inputFormatters : formatList,
        validator    : validatorFunc,
        onChanged: (_){ onChanged(); },
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
              child :  Text("???????????????", style: TextStyle( fontWeight: FontWeight.bold), ),
            ),
            textFormWidget(framePosXController, framePosXFocusNode, "X??????", [FilteringTextInputFormatter.allow(RegExp('[0123456789.-]'))], 
              (String? value){
                if( value == null ) return null;
                return posStringValidate(value);
              },
              (){
                if(posStringValidate(framePosXController.text) != null ) return;
                widget.update([widget.focusFrame.clone()]);

                widget.focusFrame.position = Point<double>(double.parse(framePosXController.text), widget.focusFrame.position.y);
                widget.focusFrame.save();

                widget.mainBuild();                
              }
            ),
            textFormWidget(framePosYController, framePosYFocusNode, "Y??????", [FilteringTextInputFormatter.allow(RegExp('[0123456789.-]'))], 
              (String? value){
                if( value == null ) return null;
                return posStringValidate(value);
              },
              (){
                if(posStringValidate(framePosYController.text) != null ) return;

                List<FrameImage> saveList = [widget.focusFrame.clone()];
                for (FrameImage _depandFrame in widget.focusFrameDependList) { saveList.add(_depandFrame.clone()); }
                widget.update(saveList);

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
              }
            ),
            textFormWidget(frameSizeRateController, frameSizeRateFocusNode, "???????????????", [FilteringTextInputFormatter.allow(RegExp('[0123456789.]'))], 
              (String? value){
                if( value == null ) return null;
                return rateStringValidate(value);
              },
              (){
                if(rateStringValidate(frameSizeRateController.text) != null ) return;

                List<FrameImage> saveList = [widget.focusFrame.clone()];
                for (FrameImage _depandFrame in widget.focusFrameDependList) { saveList.add(_depandFrame.clone() ); }
                widget.update(saveList);

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
                
              }

            ),
            Container(
              padding   : const EdgeInsets.symmetric(vertical: 10),
              alignment : Alignment.centerLeft,
              child : Text("????????????????????? : " + (widget.project.canvasSize.width - (widget.focusFrame.position.x + widget.focusFrame.rotateSize.x * widget.focusFrame.sizeRate)).toStringAsFixed(3) ),
            ),
            Align(
              alignment : Alignment.centerLeft,
              child     : Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.rotate_right_outlined),
                    onPressed: (){
                      List<FrameImage> saveList = [widget.focusFrame.clone()];
                      for (FrameImage _depandFrame in widget.focusFrameDependList) { saveList.add(_depandFrame.clone() ); }
                      widget.update(saveList);

                      double preHeight = widget.focusFrame.rotateSize.y * widget.focusFrame.sizeRate;

                      widget.focusFrame.angle += 1;
                      widget.focusFrame.angle = widget.focusFrame.angle%4;
                      widget.focusFrame.save();

                      double postHeight = widget.focusFrame.rotateSize.y * widget.focusFrame.sizeRate;

                      double diffY = preHeight - postHeight;

                      for (FrameImage _depandFrame in widget.focusFrameDependList) {
                        _depandFrame.position = Point(_depandFrame.position.x, _depandFrame.position.y-diffY);
                        _depandFrame.save();
                      }

                      widget.mainBuild();
                    }, 
                  ),

                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: (){ widget.delete(); }, 
                  )
                ],
              )
            )
          ],
        ),
      ),
    );
  }


}