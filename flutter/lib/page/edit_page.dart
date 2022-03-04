// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';

class EditPage extends StatefulWidget {
  final DbImpl? dbInstance;

  const EditPage({
    Key? key,
    this.dbInstance, 
  }):super(key:key);
  
  @override
  EditPageState createState() => EditPageState();
}

class EditPageState extends State<EditPage> {

  Map<String, Uint8List> frameImageMap = {};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // key   : Key("memoEditPage"),
      appBar: AppBar(
        title   : const Text( "編集ページ" ),
        actions : [
          IconButton(
            icon: const Icon(Icons.file_open),
            tooltip: 'ファイルの読み込み',
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                allowMultiple     : true,
                type              : FileType.custom,
                allowedExtensions : ['png', 'json'],
              );

              if(result == null) return; 
              print( result.files.length.toString() );

              setState(() { });

              for (PlatformFile _file in result.files) {
                if(_file.extension == null ) return;
                if( _file.extension == "png"){
                  if(_file.bytes != null) frameImageMap[_file.name] = _file.bytes!;
                  return;
                }
                if( _file.extension == "json"){
                  // TODO: asdf
                  return;
                }                


                print( _file.name + " | " + (_file.extension ?? "noneEx") );
              }
            },
          ),
        ]
      ),

      body : SafeArea( child : _body() ),
    );
  }

  Widget _body(){


    if( frameImageMap.isEmpty ) return Container();

    List<Widget> showWidgetList = [];
    for (Uint8List _imageBytes in frameImageMap.values.toList()) {
      showWidgetList.add(
        Image.memory(
          _imageBytes, 
          width: 1000, 
          fit: BoxFit.fitWidth, 
          filterQuality: FilterQuality.high,
        )
      );
    }

    return Column(
      children: showWidgetList,
    );
  }
}