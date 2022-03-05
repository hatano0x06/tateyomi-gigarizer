// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  final ScrollController scrollController = ScrollController();

  Size canvasSize = Size.zero;

  @override
  void initState(){
    super.initState();

    // TODO: こいつも外部からの読み込みにする
    SchedulerBinding.instance?.addPostFrameCallback((_){
      canvasSize = Size(
        MediaQuery.of(context).size.width/2, 
        MediaQuery.of(context).size.height * 10,
      );
      setState(() { });
    });

    scrollController.addListener(() {
      setState(() { });
    });
  }

  @override
  void dispose(){
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print( focusFrame) ;

    // TODO: 左右に範囲外描写つけた方がよさそう
    List<Widget> showWidgetList = [_backGroundBody(), ..._frameBodyList()];
    //   child : Stack( children: showWidgetList )
    // );

    return Scaffold(
      appBar: AppBar(
        title   : const Text( "編集ページ" ),
      ),

      body : SingleChildScrollView(
        controller  : scrollController,
        child       : Stack( children: showWidgetList ),
      ),
      
    );
  }

  Widget _backGroundBody(){
    return Center(
      child: GestureDetector(
        child : Container(
          // width : MediaQuery.of(context).size.width/2,
          // height: MediaQuery.of(context).size.height,
          width : canvasSize.width,
          height: canvasSize.height,
          color: Colors.white,
        ),
        onTapUp: (_){
          focusFrame = null;
          setState(() { });
        },
      ),
    );

  }

  List<Widget> _frameBodyList(){
    List<Widget> showWidgetList = [];

    for (FrameImage _frameData in frameImageList) {
      if( _frameData.byteData == null ) continue;
      if( _frameData.sizeRate <= 0.0 ) continue;

      // print( 
      //   _frameData.name + " : " + _frameData.position.toString()
      //   + " | " + canvasToGlobalPos(_frameData.position).y.toString() + " : " + (canvasToGlobalPos(_frameData.position).y > MediaQuery.of(context).size.height).toString()
      //   + " | " + (canvasToGlobalPos(_frameData.position).y + _frameData.size.y * _frameData.sizeRate).toString() + " : " + (canvasToGlobalPos(_frameData.position).y + _frameData.size.y * _frameData.sizeRate < 0).toString() 
      // );

      // if( !isEnableFrame(_frameData) ) continue;

      showWidgetList.addAll(_frameWidgetList(_frameData));
    }

    if(showWidgetList.isEmpty) return [ Center( child: inputFileButton()) ] ;

    return showWidgetList;
  }

  // コマの表示（大きさ変えるための、角に四角配置

  Point<double> dragStartLeftTopPos = const Point(0,0);
  Point<double> dragStartRightBottomPos = const Point(0,0);
  List<Widget> _frameWidgetList(FrameImage _frameData){


    if( draggingFrame != null ) return [ _frameDraggingWidget(_frameData) ];

    void tempSavePos(){
      dragStartLeftTopPos     = _frameData.position;
      dragStartRightBottomPos = Point(
        _frameData.position.x + _frameData.size.x * _frameData.sizeRate,
        _frameData.position.y + _frameData.size.y * _frameData.sizeRate,
      );
    }

    double ballDiameter = 10.0;

    return [
      _frameDraggingWidget(_frameData),

      // 左上
      Positioned(
        left  : canvasToGlobalPos(_frameData.position).x - ballDiameter / 2,
        top   : canvasToGlobalPos(_frameData.position).y - ballDiameter / 2,
        child: CornerBallWidget(
          cursor      : SystemMouseCursors.resizeUpLeftDownRight,
          ballDiameter: ballDiameter,
          onDragStart : (){ tempSavePos(); },
          onDragEnd   : (){ _frameData.save(); },
          onDrag      : (dragPos) {
            Point<double> canvasDragPos = globalToCanvasPos(Point<double>(dragPos.dx, dragPos.dy));

            _frameData.sizeRate = math.max(
              (canvasDragPos.x - dragStartRightBottomPos.x).abs()/_frameData.size.x, 
              (canvasDragPos.y - dragStartRightBottomPos.y).abs()/_frameData.size.y, 
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
        left  : canvasToGlobalPos(_frameData.position).x + _frameData.size.x * _frameData.sizeRate - ballDiameter / 2,
        top   : canvasToGlobalPos(_frameData.position).y - ballDiameter / 2,
        child: CornerBallWidget(
          cursor      : SystemMouseCursors.resizeUpRightDownLeft,
          ballDiameter: ballDiameter,
          onDragStart : (){ tempSavePos(); },
          onDragEnd   : (){ _frameData.save(); },
          onDrag      : (dragPos) {
            Point<double> canvasDragPos = globalToCanvasPos(Point<double>(dragPos.dx, dragPos.dy));

            _frameData.sizeRate = math.max(
              (canvasDragPos.x - dragStartLeftTopPos.x).abs()/_frameData.size.x, 
              (canvasDragPos.y - dragStartRightBottomPos.y).abs()/_frameData.size.y, 
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
        left  : canvasToGlobalPos(_frameData.position).x - ballDiameter / 2,
        top   : canvasToGlobalPos(_frameData.position).y + _frameData.size.y * _frameData.sizeRate - ballDiameter / 2,
        child: CornerBallWidget(
          cursor      : SystemMouseCursors.resizeUpRightDownLeft,
          ballDiameter: ballDiameter,
          onDragStart : (){ tempSavePos(); },
          onDragEnd   : (){ _frameData.save(); },
          onDrag      : (dragPos) {
            Point<double> canvasDragPos = globalToCanvasPos(Point<double>(dragPos.dx, dragPos.dy));

            _frameData.sizeRate = math.max(
              (canvasDragPos.x - dragStartRightBottomPos.x).abs()/_frameData.size.x, 
              (canvasDragPos.y - dragStartLeftTopPos.y).abs()/_frameData.size.y, 
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
        left  : canvasToGlobalPos(_frameData.position).x + _frameData.size.x * _frameData.sizeRate - ballDiameter / 2,
        top   : canvasToGlobalPos(_frameData.position).y + _frameData.size.y * _frameData.sizeRate - ballDiameter / 2,
        child: CornerBallWidget(
          cursor      : SystemMouseCursors.resizeUpLeftDownRight,
          ballDiameter: ballDiameter,
          onDragStart : (){ tempSavePos(); },
          onDragEnd   : (){ _frameData.save(); },
          onDrag      : (dragPos) {

            Point<double> canvasDragPos = globalToCanvasPos(Point<double>(dragPos.dx, dragPos.dy));


            _frameData.sizeRate = math.max(
              (canvasDragPos.x - dragStartLeftTopPos.x).abs()/_frameData.size.x, 
              (canvasDragPos.y - dragStartLeftTopPos.y).abs()/_frameData.size.y, 
            );
            setState(() { });
          },
        ),
      ),

    ];
  }

  // コマの表示（ドラッグ
  FrameImage? draggingFrame;
  FrameImage? focusFrame;
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

    Widget draggableWidget = Draggable(
      child             : frameWidgetUnit(false),
      childWhenDragging : frameWidgetUnit(true),
      feedback          : frameWidgetUnit(true),
      onDragStarted: (){
        draggingFrame = _frameData;
        setState(() { });
      },
      onDraggableCanceled: (_, _offset){
        draggingFrame!.position = Point<double>(
          globalToCanvasPos(Point<double>(_offset.dx, _offset.dy)).x, 
          globalToCanvasPos(Point<double>(_offset.dx, _offset.dy)).y - kToolbarHeight
        );
        draggingFrame = null;
        setState(() { });
      },      
    );

    Widget dragging = MouseRegion(
      cursor  : SystemMouseCursors.click,
      child   : GestureDetector(
        child   : draggableWidget,
        onTapUp : (_){
          focusFrame = _frameData;
          setState(() { });
        },
      ),
    );

    return Positioned(
      left  : canvasToGlobalPos(_frameData.position).x,
      top   : canvasToGlobalPos(_frameData.position).y,
      child : dragging,
    );
  }

  Widget inputFileButton(){
    Widget button = ElevatedButton.icon(
      icon    : const Icon(Icons.file_open),
      label   : const Text('画像・ファイルの読み込み'),
      onPressed: () async { 
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple     : true,
          type              : FileType.custom,
          allowedExtensions : ['png', 'json'],
        );

        if(result == null) return; 

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
                sizeRate    : -1.0,
                position    : const Point<double>(0,0),
                size        : Point(_image.width.toDouble(), _image.height.toDouble())
              )
            );
          }

          setState(() { });

          continue;
        }

        // 設定読み込み
        for (PlatformFile _file in result.files.where((_file) => _file.extension != null && _file.extension == "json").toList()) {
          if(_file.bytes == null) continue;

          List<dynamic> jsonData = json.decode(utf8.decode(_file.bytes!)); 
          // List<List<Map<String, dynamic>>> jsonData = json.decode(utf8.decode(_file.bytes!)); 
          // print( jsonData );

          // TODO: こいつできたら消す
          int temp = 0;
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

              if( targetFrameIndex < 0 ) return;
              if( frameImageList[targetFrameIndex].sizeRate > 0 ) return;
    
              // TODO: canvas
              frameImageList[targetFrameIndex].sizeRate = 1.0; // 仮
              frameImageList[targetFrameIndex].position = Point(0, temp * 300);

              temp++;
              setState(() { });

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

    return Padding(
      padding: const EdgeInsets.only(top: 200),
      child : button,
    );
  }

  Point<double> canvasToGlobalPos(Point<double> _pos){
    Offset _offsetSize = Offset(
      (MediaQuery.of(context).size.width - canvasSize.width)/2,
      scrollController.position.pixels
    );

    return Point(
      _pos.x + _offsetSize.dx,
      _pos.y,
      // _pos.y - _offsetSize.dy,
    );
  }

  Point<double> globalToCanvasPos(Point<double> _pos){
    Offset _offsetSize = Offset(
      (MediaQuery.of(context).size.width - canvasSize.width)/2,
      scrollController.position.pixels
    );

    return Point(
      _pos.x - _offsetSize.dx,
      _pos.y + _offsetSize.dy,
    );
  }  

}