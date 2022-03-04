// ignore_for_file: avoid_print

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
            },
          ),
        ]
      ),

      body : SafeArea( child : _body() ),
    );
  }

  Widget _body(){
    return Container();
  }
}