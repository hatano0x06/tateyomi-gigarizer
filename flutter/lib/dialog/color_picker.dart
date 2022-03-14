import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({Key? key}) : super(key: key);

  @override
  _ColorPickerDialogState createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose(){
    textController.dispose();
    super.dispose();
  }

  // create some values
  Color? pickerColor;
  final textController = TextEditingController(text: '');

  // ValueChanged<Color> callback
  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('色選択'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            ColorPicker(
              pickerColor   : pickerColor ?? Colors.white,
              onColorChanged: changeColor,
              enableAlpha   : false,
              hexInputController: textController,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              /* It can be any text field, for example:
              * TextField
              * TextFormField
              * CupertinoTextField
              * EditableText
              * any text field from 3-rd party package
              * your own text field
              so basically anything that supports/uses
              a TextEditingController for an editable text.
              */
              child: TextField(
                controller: textController,
                // Everything below is purely optional.
                // prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.tag)),
                // suffix: IconButton(
                //   icon: const Icon(Icons.content_paste_rounded),
                //   onPressed: () => copyToClipboard(textController.text),
                // ),
                autofocus: true,
                maxLength: 6,
                decoration      : const InputDecoration( hintText: "Hex Color( #なしで入力）", ),
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  FilteringTextInputFormatter.allow(RegExp(kValidHexPattern)),
                ],
              ),
            ),
          ]
        ),
      ),
      actions: <Widget>[
        OutlinedButton(
          child: const Text("キャンセル"),
          onPressed: (){
            Navigator.of(context).pop(null);
          },
        ),
        ElevatedButton(
          child: const Text('決定'),
          onPressed: () {
            Navigator.of(context).pop(pickerColor ?? Colors.white);
          },
        ),
      ],
    );

  }
}