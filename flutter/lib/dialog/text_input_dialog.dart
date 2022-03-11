import 'package:flutter/material.dart';
import 'dart:math' as math;

class TextInputDialog extends StatefulWidget {
  final String defaultInput;

  const TextInputDialog(
    this.defaultInput, {Key? key}
  ) : super(key: key);

  @override
  _TextInputDialogState createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late TextEditingController _textEditingController;

  @override
  void initState(){
    super.initState(); 

    _textEditingController = TextEditingController(text: widget.defaultInput);
    _textEditingController.addListener((){ 
      _textEditingController.value = _textEditingController.value.copyWith( text: _textEditingController.text);
      setState(() { });
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();

    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    Widget _body = _content(context);
    return AlertDialog(
      title   : const Text("タイトル入力"),
      content : SizedBox(
        width: math.max(700, MediaQuery.of(context).size.width/2),
        child: _body,
      ),
      actions : <Widget>[
        OutlinedButton(
          child: const Text("キャンセル"),
          onPressed: (){
            Navigator.of(context, rootNavigator: true).pop(null);
          },
        ),
        ElevatedButton(
          child: const Text("決定"),
          onPressed: titleStringValidate(_textEditingController.text) != null ? null : (){
            Navigator.of(context, rootNavigator: true).pop(_textEditingController.text);
          },
        ),

      ]
    );
  }

  Widget _content(BuildContext context){
    List<Widget> bodyList = [ textInput() ];

    return SingleChildScrollView( child: Column(children: bodyList, mainAxisSize: MainAxisSize.min,));
  }


  Widget textInput(){
    Widget inputField = TextFormField(
      autovalidateMode: AutovalidateMode.always,
      controller      : _textEditingController,
      autofocus       : true,
      decoration      : const InputDecoration( labelText: "タイトル", ),
      validator    : titleStringValidate,
    );

    return Padding(
      padding   : const EdgeInsets.symmetric(horizontal: 5.0),
      child     : inputField,
    );
  }


  String? titleStringValidate(String? posString){
    if(posString == null ) return null;
    if(posString.isEmpty) return "何か入力して下さい";

    return null;
  }
}