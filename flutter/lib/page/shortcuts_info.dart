import 'package:flutter/material.dart';
import 'dart:math' as math;

class ShortCutInfoDialog extends StatefulWidget {
  const ShortCutInfoDialog({Key? key}) : super(key: key);

  @override
  _ShortCutInfoDialogState createState() => _ShortCutInfoDialogState();
}

class _ShortCutInfoDialogState extends State<ShortCutInfoDialog> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose(){
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      title   : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon      : const Icon(Icons.close, size: 25,),
            onPressed : (){ Navigator.of(context, rootNavigator: true).pop(); },
          ),
          const Expanded(child: Center(child: Text("ショートカット"))),
        ]
      ), 
      content : SizedBox(
        width: math.max(700, MediaQuery.of(context).size.width/2),
        child: body(),
      ),
    );

  }

  Widget body(){
    Map<String, List<String>> bodyList = {
      "コマの移動": 
        [
          "通常移動 : コマをドラッグ",
          "微小移動 : コマをクリック後、WASD",
        ],
      "コマの拡大縮小": 
        [
          "コマの角にある円のドラッグ"
        ],
      "特定のコマより下にあるコマも従属して動かす": 
        [
          "ctrlを押しながら操作（赤色に縁がつくコマが従属されます"
        ]

      // "asdfasdfasdf": ["1111", "22222"]
    };

    return ListView.builder(
      shrinkWrap  : true,
      itemBuilder : (BuildContext context, int index) {
        String keyText = bodyList.keys.toList()[index];
        List<Widget> body = [];

        bodyList[keyText]?.forEach((_text){
          body.add( 
            Align(
              alignment: Alignment.centerLeft,
              child : Text(_text)
            ),
          );
        });


        return Card(
          color: Colors.grey[400],
          child : ListTile(
            title : Text(keyText, style: const TextStyle( fontWeight: FontWeight.bold),),
            subtitle  : Column(mainAxisSize: MainAxisSize.min, children: body,),
          ),
        );
      },
      itemCount: bodyList.length,
    );  

  }
}