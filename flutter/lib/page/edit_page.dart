// ignore_for_file: avoid_print

import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';

class EditPage extends StatefulWidget {
  final DbImpl dbInstance;

  const EditPage({
    Key? key,
    required this.dbInstance, 
  }):super(key:key);
  
  @override
  EditPageState createState() => EditPageState();
}

// TODO: 
//  json読み込み
//  画像を並び替え

class EditPageState extends State<EditPage> {
  List<FrameImage> frameImageList = [];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title   : const Text( "編集ページ" ),
        // actions : []
      ),

      body : SafeArea( child : _body() ),
    );
  }

  Widget _body(){
    List<Widget> showWidgetList = [];
    for (FrameImage _frameData in frameImageList) {
      if( _frameData.byteData == null ) continue;

      showWidgetList.add(frameDraggingWidget(_frameData));
    }

    if(showWidgetList.isEmpty) return Center( child: inputFileButton());

    return Stack(
      children: showWidgetList,
    );
  }

  Widget frameDraggingWidget(FrameImage _frameData){
    frameWidgetUnit(bool isDragging){
      return Opacity(
        opacity: isDragging ? 0.5 : 1.0,
        child: Image.memory(
          _frameData.byteData!, 
          width: 1000, 
          fit: BoxFit.fitWidth, 
          filterQuality: FilterQuality.high,
        )
      );
    }

    Widget dragging = MouseRegion(
      cursor  : SystemMouseCursors.click,
      child   : Draggable(
        child             : frameWidgetUnit(false),
        childWhenDragging : frameWidgetUnit(true),
        feedback          : frameWidgetUnit(false),
        onDragStarted: (){
        },
        onDraggableCanceled: (Velocity velocity, Offset offset){
        }
      ),
    );

    return Positioned(
      left  : _frameData.position.x,
      top   : _frameData.position.y,
      child : dragging,
    );

      // Widget _charThumb = Positioned(
      //   left  : charPos.left,
      //   top   : charPos.top,
      //   child : dragging,
      // );
      // showWidgetList.add(
      //   Image.memory(
      //     _frameData.byteData!, 
      //     width: 1000, 
      //     fit: BoxFit.fitWidth, 
      //     filterQuality: FilterQuality.high,
      //   )
      // );


  }

  Widget inputFileButton(){
    return ElevatedButton.icon(
      icon    : const Icon(Icons.file_open),
      label   : const Text('画像・ファイルの読み込み'),
      onPressed: () async { 
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple     : true,
          type              : FileType.custom,
          allowedExtensions : ['png', 'json'],
        );

        if(result == null) return; 

        setState(() { });

        for (PlatformFile _file in result.files) {
          if(_file.extension == null ) return;

          // 画像読み込み
          if( _file.extension == "png"){
            if(_file.bytes == null) return;

            try{
              FrameImage frameImage = frameImageList.singleWhere((_frameImage) => _frameImage.name == _file.name);
              frameImage.byteData = _file.bytes;
            } catch(e){
              // TODO: 本当はファイル読み込み時にやるべきな気がする
              frameImageList.add(
                FrameImage(
                  dbInstance  : widget.dbInstance,
                  byteData    : _file.bytes, 
                  name        : _file.name,
                  position    : const Point<double>(0,0),
                  sizeRate    : 1.0
                )
              );
            }
            return;
          }


          // 設定読み込み
          if( _file.extension == "json"){
            // TODO: 
            //  すでにあるなら、無視
            //  ないなら、ファイルを作って保存処理＋自然配置
            return;
          }
        }

      },
    );

  }
}