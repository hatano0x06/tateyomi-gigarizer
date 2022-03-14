import 'package:flutter/material.dart';

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
    super.dispose();
  }

  // create some values
  Color? pickerColor;

  // ValueChanged<Color> callback
  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('色選択'),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor   : pickerColor ?? Colors.white,
          onColorChanged: changeColor,
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