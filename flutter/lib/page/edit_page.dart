// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';
import 'package:tateyomi_gigarizer/page/corner_ball.dart';
import 'dart:ui' as ui;

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
//  画像を大きさ変換

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

      showWidgetList.add(_frameWidget(_frameData));
    }

    if(showWidgetList.isEmpty) return Center( child: inputFileButton());

    return Stack(
      children: showWidgetList,
    );
  }

  // コマの表示（大きさ変えるための、角に四角配置
  Widget _frameWidget(FrameImage _frameData){
    double ballDiameter = 20.0;
    return Stack(
      children: [
        // 左上
        Positioned(
          left  : _frameData.position.x - ballDiameter / 2,
          top   : _frameData.position.y - ballDiameter / 2,
          child: CornerBallWidget(
            onDrag: (dx, dy) {
              print( "$dx : $dy");
              // var mid = (dx + dy) / 2;
              // var newHeight = height - 2 * mid;
              // var newWidth = width - 2 * mid;
            },
          ),
        ),
        _frameDraggingWidget(_frameData)
      ],
    );
  }

  // コマの表示（ドラッグ
  Widget _frameDraggingWidget(FrameImage _frameData){
    frameWidgetUnit(bool isDragging){
      return Opacity(
        opacity: isDragging ? 0.5 : 1.0,
        child: Image.memory(
          _frameData.byteData!, 
          width: _frameData.size.x, height: _frameData.size.y,
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
          _frameData.position = Point<double>(offset.dx, offset.dy - kToolbarHeight);
          setState(() { });
        }
      ),
    );

    return Positioned(
      left  : _frameData.position.x,
      top   : _frameData.position.y,
      child : dragging,
    );
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
          if(_file.extension == null ) continue;


          // 画像読み込み
          if( _file.extension == "png"){
            if(_file.bytes == null) continue;

            Future<ui.Image> _loadImage(Uint8List _charThumbImg) async {
              final Completer<ui.Image> completer = Completer();

              ui.decodeImageFromList(_charThumbImg, (ui.Image convertedImg) {
                return completer.complete(convertedImg);
              });
              return completer.future;
            }
                        
            ui.Image _image = await _loadImage(_file.bytes!);

            print(_image);

            try{
              FrameImage frameImage = frameImageList.singleWhere((_frameImage) => _frameImage.name == _file.name);
              frameImage.byteData = _file.bytes;
              frameImage.size = Point(_image.width.toDouble(), _image.height.toDouble());
            } catch(e){
              // TODO: 本当はファイル読み込み時にやるべきな気がする
              frameImageList.add(
                FrameImage(
                  dbInstance  : widget.dbInstance,
                  byteData    : _file.bytes, 
                  name        : _file.name,
                  position    : const Point<double>(0,0),
                  sizeRate    : 1.0,
                  size        : Point(_image.width.toDouble(), _image.height.toDouble())
                )
              );
            }
            continue;
          }


          // 設定読み込み
          if( _file.extension == "json"){
            // TODO: 
            //  すでにあるなら、無視
            //  ないなら、ファイルを作って保存処理＋自然配置
            continue;
          }
        }

      },
    );

  }
}