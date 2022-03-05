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
import 'dart:math' as math;
import 'dart:convert';

class EditPage extends StatefulWidget {
  final DbImpl dbInstance;

  const EditPage({
    Key? key,
    required this.dbInstance, 
  }):super(key:key);
  
  @override
  EditPageState createState() => EditPageState();
}

class EditPageState extends State<EditPage> {
  List<FrameImage> frameImageList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title   : const Text( "編集ページ" ),
      ),

      body : SafeArea( child : _body() ),
    );
  }

  Widget _body(){
    List<Widget> showWidgetList = [];
    for (FrameImage _frameData in frameImageList) {
      if( _frameData.byteData == null ) continue;
      if( _frameData.sizeRate == 0.0 ) continue;

      showWidgetList.add(_frameWidget(_frameData));
    }

    if(showWidgetList.isEmpty) return Center( child: inputFileButton());

    return Stack(
      children: showWidgetList,
    );
  }

  // コマの表示（大きさ変えるための、角に四角配置

  Point<double> dragStartLeftTopPos = const Point(0,0);
  Point<double> dragStartRightBottomPos = const Point(0,0);
  Widget _frameWidget(FrameImage _frameData){
    if(isDragging) return _frameDraggingWidget(_frameData);

    void tempSavePos(){
      dragStartLeftTopPos     = _frameData.position;
      dragStartRightBottomPos = Point(
        _frameData.position.x + _frameData.size.x * _frameData.sizeRate,
        _frameData.position.y + _frameData.size.y * _frameData.sizeRate,
      );
    }

    double ballDiameter = 10.0;
    return Stack(
      children: [
        _frameDraggingWidget(_frameData),

        // 左上
        Positioned(
          left  : _frameData.position.x - ballDiameter / 2,
          top   : _frameData.position.y - ballDiameter / 2,
          child: CornerBallWidget(
            cursor      : SystemMouseCursors.resizeUpLeftDownRight,
            ballDiameter: ballDiameter,
            onDragStart : (){ tempSavePos(); },
            onDragEnd   : (){ _frameData.save(); },
            onDrag      : (dragPos) {
              _frameData.sizeRate = math.max(
                (dragPos.dx - dragStartRightBottomPos.x).abs()/_frameData.size.x, 
                (dragPos.dy - dragStartRightBottomPos.y).abs()/_frameData.size.y, 
              );
              _frameData.position = Point(
                dragStartRightBottomPos.x - _frameData.size.x * _frameData.sizeRate,
                dragStartRightBottomPos.y - _frameData.size.y * _frameData.sizeRate,
              );

              setState(() { });
            },
          ),
        ),

        // 右上
        Positioned(
          left  : _frameData.position.x + _frameData.size.x * _frameData.sizeRate - ballDiameter / 2,
          top   : _frameData.position.y - ballDiameter / 2,
          child: CornerBallWidget(
            cursor      : SystemMouseCursors.resizeUpRightDownLeft,
            ballDiameter: ballDiameter,
            onDragStart : (){ tempSavePos(); },
            onDragEnd   : (){ _frameData.save(); },
            onDrag      : (dragPos) {
              _frameData.sizeRate = math.max(
                (dragPos.dx - dragStartLeftTopPos.x).abs()/_frameData.size.x, 
                (dragPos.dy - dragStartRightBottomPos.y).abs()/_frameData.size.y, 
              );
              _frameData.position = Point(
                _frameData.position.x,
                dragStartRightBottomPos.y - _frameData.size.y * _frameData.sizeRate,
              );

              setState(() { });
            },
          ),
        ),

        // 左下
        Positioned(
          left  : _frameData.position.x - ballDiameter / 2,
          top   : _frameData.position.y + _frameData.size.y * _frameData.sizeRate - ballDiameter / 2,
          child: CornerBallWidget(
            cursor      : SystemMouseCursors.resizeUpRightDownLeft,
            ballDiameter: ballDiameter,
            onDragStart : (){ tempSavePos(); },
            onDragEnd   : (){ _frameData.save(); },
            onDrag      : (dragPos) {
              _frameData.sizeRate = math.max(
                (dragPos.dx - dragStartRightBottomPos.x).abs()/_frameData.size.x, 
                (dragPos.dy - dragStartLeftTopPos.y).abs()/_frameData.size.y, 
              );
              _frameData.position = Point(
                dragStartRightBottomPos.x - _frameData.size.x * _frameData.sizeRate,
                _frameData.position.y,
              );

              setState(() { });
            },
          ),
        ),

        // 右下
        Positioned(
          left  : _frameData.position.x + _frameData.size.x * _frameData.sizeRate - ballDiameter / 2,
          top   : _frameData.position.y + _frameData.size.y * _frameData.sizeRate - ballDiameter / 2,
          child: CornerBallWidget(
            cursor      : SystemMouseCursors.resizeUpLeftDownRight,
            ballDiameter: ballDiameter,
            onDragStart : (){ tempSavePos(); },
            onDragEnd   : (){ _frameData.save(); },
            onDrag      : (dragPos) {
              _frameData.sizeRate = math.max(
                (dragPos.dx - dragStartLeftTopPos.x).abs()/_frameData.size.x, 
                (dragPos.dy - dragStartLeftTopPos.y).abs()/_frameData.size.y, 
              );
              setState(() { });
            },
          ),
        ),

      ],
    );
  }

  // コマの表示（ドラッグ
  bool isDragging = false;
  Widget _frameDraggingWidget(FrameImage _frameData){
    frameWidgetUnit(bool _isDragging){
      return Opacity(
        opacity: _isDragging ? 0.5 : 1.0,
        child: Image.memory(
          _frameData.byteData!, 
          width: _frameData.size.x * _frameData.sizeRate, 
          // height: _frameData.size.y,
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
        feedback          : frameWidgetUnit(true),
        onDragStarted: (){
          isDragging = true;
          setState(() { });
        },
        onDraggableCanceled: (Velocity velocity, Offset offset){
          isDragging = false;
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

        // 画像読み込み
        for (PlatformFile _file in result.files.where((_file) => _file.extension != null && _file.extension == "png").toList()) {
          if(_file.bytes == null) continue;

          Future<ui.Image> _loadImage(Uint8List _charThumbImg) async {
            final Completer<ui.Image> completer = Completer();

            ui.decodeImageFromList(_charThumbImg, (ui.Image convertedImg) {
              return completer.complete(convertedImg);
            });
            return completer.future;
          }
                      
          ui.Image _image = await _loadImage(_file.bytes!);

          try{
            FrameImage frameImage = frameImageList.singleWhere((_frameImage) => _frameImage.name == _file.name);
            frameImage.byteData = _file.bytes;
            frameImage.size = Point(_image.width.toDouble(), _image.height.toDouble());
          } catch(e){
            frameImageList.add(
              FrameImage(
                dbInstance  : widget.dbInstance,
                byteData    : _file.bytes, 
                name        : _file.name,
                sizeRate    : 0.0,
                position    : const Point<double>(0,0),
                size        : Point(_image.width.toDouble(), _image.height.toDouble())
              )
            );
          }
          continue;
        }

        // 設定読み込み
        for (PlatformFile _file in result.files.where((_file) => _file.extension != null && _file.extension == "json").toList()) {
          if(_file.bytes == null) continue;

          List<dynamic> jsonData = json.decode(utf8.decode(_file.bytes!)); 
          // List<List<Map<String, dynamic>>> jsonData = json.decode(utf8.decode(_file.bytes!)); 
          // print( jsonData );

          jsonData.asMap().forEach((_pageIndex, _pageValueJson) {
            List<dynamic> _pageJson  = _pageValueJson as List<dynamic>;

            // print( "frameNum in Page : $_pageIndex" );
            _pageJson.asMap().forEach((_frameIndex, _frameValuejson) {

              String _imageTitle(){
                int pageNumCutLength = jsonData.length >= 100 ? -3:-2;
                String fullPageNum = '00000' + (_pageIndex+1).toString();
                String cutPageNum  = fullPageNum.substring(fullPageNum.length+pageNumCutLength);

                int frameNumCutLength = _pageJson.length >= 100 ? -3:-2;
                String fullFrameNum = '00000' + (_frameIndex+1).toString();
                String cutFrameNum  = fullFrameNum.substring(fullFrameNum.length+frameNumCutLength);

                return cutPageNum + "p_" + cutFrameNum + ".png";
              }

              // すでにwebに設定済みのデータがある（読み込み済み）なら、なにもせずに終了
              int targetFrameIndex = frameImageList.indexWhere((_frameImage) => _frameImage.name == _imageTitle());

              print( _imageTitle() + " : $targetFrameIndex" );

              if( targetFrameIndex < 0 ) return;
              if( frameImageList[targetFrameIndex].sizeRate >= 0 ) return;

              // TODO: canvas
              // Map<String, dynamic> _framejson  = _frameValuejson as Map<String, dynamic>;
              // frameImageList[targetFrameIndex].position
              // frameImageList[targetFrameIndex].sizeRate
            });
          });

          //  ないなら、ファイルを作って保存処理＋自然配置
          continue;
        }
      }
    );

  }
}