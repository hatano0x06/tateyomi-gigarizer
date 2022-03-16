import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:tateyomi_gigarizer/model/background_color_change.dart';

class BackGroundColorDetailWidget extends StatefulWidget {
  final BackGroundColorChange backGroundColorChange; 
  final List<BackGroundColorChange> backGroundColorChangeList; 
  final void Function() mainBuild;
  final void Function() unfocusBackGround;

  const BackGroundColorDetailWidget({
    Key? key, 
    required this.backGroundColorChange,
    required this.backGroundColorChangeList,
    required this.mainBuild, 
    required this.unfocusBackGround, 
  }):super(key:key);


  @override
  BackGroundColorDetailWidgetState createState() => BackGroundColorDetailWidgetState();
}

class BackGroundColorDetailWidgetState extends State<BackGroundColorDetailWidget> {
  late TextEditingController textController;
  final FocusNode focusNode = FocusNode();

  @override
  void initState(){
    super.initState();

    String hexColorString(){
      return '${widget.backGroundColorChange.targetColor.red.toRadixString(16).padLeft(2, '0')}'
      '${widget.backGroundColorChange.targetColor.green.toRadixString(16).padLeft(2, '0')}'
      '${widget.backGroundColorChange.targetColor.blue.toRadixString(16).padLeft(2, '0')}';
    }

    textController = TextEditingController(text: hexColorString());
  }

  @override
  void dispose(){
    if(widget.backGroundColorChange.dbIndex.isNotEmpty) widget.backGroundColorChange.save();
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  bool isFocus(){
    return focusNode.hasFocus;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
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
              child :  Text("背景の編集", style: TextStyle( fontWeight: FontWeight.bold), ),
            ),
            ColorPicker(
              pickerColor   : widget.backGroundColorChange.targetColor,
              onColorChanged: (Color color) {
                widget.mainBuild();
                widget.backGroundColorChange.targetColor = color;
              },
              portraitOnly: true,
              enableAlpha   : false,
              hexInputController: textController,
            ),
            TextField(
              controller: textController,
              maxLength: 6,
              decoration      : const InputDecoration( hintText: "Hex Color( #なしで入力）", ),
              inputFormatters: [
                UpperCaseTextFormatter(),
                FilteringTextInputFormatter.allow(RegExp(kValidHexPattern)),
              ],
            ),
            Align(
              alignment : Alignment.centerLeft,
              child     : IconButton(
                icon: const Icon(Icons.delete),
                onPressed: (){
                  widget.backGroundColorChangeList.remove(widget.backGroundColorChange);
                  widget.backGroundColorChange.delete();
                  widget.backGroundColorChange.dbIndex = "";

                  widget.unfocusBackGround();
                }, 
              )
            )
          ],
        ),
      ),
    );
  }


}