import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:tateyomi_gigarizer/model/background_color_change.dart';

class BackGroundColorDetailWidget extends StatefulWidget {
  final BackGroundColorChange backGroundColorChange; 
  final List<BackGroundColorChange> backGroundColorChangeList; 
  final void Function() mainBuild;

  const BackGroundColorDetailWidget({
    Key? key, 
    required this.backGroundColorChange,
    required this.backGroundColorChangeList,
    required this.mainBuild, 
  }):super(key:key);


  @override
  BackGroundColorDetailWidgetState createState() => BackGroundColorDetailWidgetState();
}

class BackGroundColorDetailWidgetState extends State<BackGroundColorDetailWidget> {
  @override
  void initState(){
    super.initState();
  }

  @override
  void dispose(){
    super.dispose();
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
                print("asdfasdfdsf");
                widget.backGroundColorChange.save();
              },
              portraitOnly: true,
              enableAlpha   : false,
              // TODO: asdf
              // hexInputController: textController,
            ),
            Align(
              alignment : Alignment.centerLeft,
              child     : IconButton(
                icon: const Icon(Icons.delete),
                onPressed: (){
                  widget.backGroundColorChangeList.remove(widget.backGroundColorChange);
                  widget.backGroundColorChange.delete();

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