// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';
import 'package:tateyomi_gigarizer/model/keyboard.dart';
import 'package:tateyomi_gigarizer/page/corner_ball.dart';
import 'package:tateyomi_gigarizer/download/canvas_to_image.dart';
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
  final TextEditingController framePosXController = TextEditingController();
  final TextEditingController framePosYController = TextEditingController();
  final TextEditingController frameSizeRateController = TextEditingController();
  final FocusNode framePosXFocusNode = FocusNode();
  final FocusNode framePosYFocusNode = FocusNode();
  final FocusNode frameSizeRateFocusNode = FocusNode();

  Size canvasSize = Size.zero;

  @override
  void initState(){
    super.initState();

    // TODO: こいつも外部からの読み込みにする
    SchedulerBinding.instance?.addPostFrameCallback((_){
      canvasSize = Size(
        MediaQuery.of(context).size.width/2, 
        MediaQuery.of(context).size.height * 5,
      );
      setState(() { });
    });

    scrollController.addListener(() {
      setState(() { });
    });

    framePosXController.addListener((){
      if(posStringValidate(framePosXController.text) != null ) return;

      focusFrame!.position = Point<double>(double.parse(framePosXController.text), focusFrame!.position.y);
      setState(() { });
    });    

    framePosYController.addListener((){
      if(posStringValidate(framePosYController.text) != null ) return;

      focusFrame!.position = Point<double>(focusFrame!.position.x, double.parse(framePosYController.text));
      setState(() { });
    });    

    frameSizeRateController.addListener((){
      if(rateStringValidate(frameSizeRateController.text) != null ) return;

      double _rate = double.parse(frameSizeRateController.text);
      _rate = math.max(_rate, 0.01);

      focusFrame!.sizeRate = _rate;
      setState(() { });
    });

  }

  @override
  void dispose(){
    scrollController.dispose();
    framePosXController.dispose();
    framePosYController.dispose();
    frameSizeRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: 左右に範囲外描写つけた方がよさそう
    List<Widget> showWidgetList = [_backGroundBody(), ..._frameBodyList()];

    Widget outsideGraySpace(){
      return Container(
        width: (MediaQuery.of(context).size.width - canvasSize.width)/2,
        height: MediaQuery.of(context).size.height,
        color: Colors.grey.withAlpha(200),
      );
    }

    Widget _body = Stack(
      children: [
        SingleChildScrollView(
          controller  : scrollController,
          child       : Stack( children: showWidgetList ),
        ),
        Align( alignment : Alignment.centerLeft, child : outsideGraySpace(),),
        Align( alignment : Alignment.centerRight, child : outsideGraySpace(),),
        focusDetailSettingBox()
      ],
    );
    

    const String TYPE_SHORTCUT_UP     = "up";
    const String TYPE_SHORTCUT_LEFT   = "left";
    const String TYPE_SHORTCUT_DOWN   = "down";
    const String TYPE_SHORTCUT_RIGHT  = "right";
    Map<Set<LogicalKeyboardKey>, String> _shortCutKeyMap = {
      {LogicalKeyboardKey.keyW}       : TYPE_SHORTCUT_UP,
      {LogicalKeyboardKey.keyA}       : TYPE_SHORTCUT_LEFT,
      {LogicalKeyboardKey.keyS}       : TYPE_SHORTCUT_DOWN,
      {LogicalKeyboardKey.keyD}       : TYPE_SHORTCUT_RIGHT,
    };

    _body = KeyBoardShortcuts(
      keysToPressList: _shortCutKeyMap.keys.toList(),
      onKeysPressed: (int _shortCutIndex){
        if (!mounted)       return;
        if( ModalRoute.of(context) == null ) return;
        if( !ModalRoute.of(context)!.isCurrent ) return;

        String shortCutType = _shortCutKeyMap.values.toList()[_shortCutIndex];

        if(framePosXFocusNode.hasFocus || framePosYFocusNode.hasFocus || frameSizeRateFocusNode.hasFocus )  return;
        if( focusFrame != null ){

          double moveSize = 0.1;
          if( shortCutType == TYPE_SHORTCUT_UP    ) focusFrame!.position = Point(focusFrame!.position.x           , focusFrame!.position.y-moveSize);
          if( shortCutType == TYPE_SHORTCUT_LEFT  ) focusFrame!.position = Point(focusFrame!.position.x-moveSize  , focusFrame!.position.y);
          if( shortCutType == TYPE_SHORTCUT_DOWN  ) focusFrame!.position = Point(focusFrame!.position.x           , focusFrame!.position.y+moveSize);
          if( shortCutType == TYPE_SHORTCUT_RIGHT ) focusFrame!.position = Point(focusFrame!.position.x+moveSize  , focusFrame!.position.y);

          framePosXController.value = framePosXController.value.copyWith( text: focusFrame!.position.x.toString() );
          framePosYController.value = framePosYController.value.copyWith( text: focusFrame!.position.y.toString() );
          frameSizeRateController.value = frameSizeRateController.value.copyWith( text: focusFrame!.sizeRate.toString() );
          setState(() { });
        }

      },
      child: _body
    );    

    return Scaffold(
      appBar: AppBar(
        title   : const Text( "編集ページ" ),
        actions : [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: (){
              if( frameImageList.isEmpty ) return;

              CanvasToImage(frameImageList, canvasSize).download("sample");
            },
          )
        ]
      ),

      body : _body,
    );
  }


  Widget focusDetailSettingBox(){
    if(focusFrame == null ) return Container();

    return Positioned(
      top   : 20,
      left  : MediaQuery.of(context).size.width/2 + canvasSize.width/2 + 20,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all( color: Colors.black, )
        ),
        child: Column(
          children: [
            Padding(
              padding : const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child   : TextFormField(
                autovalidateMode: AutovalidateMode.always,
                controller  : framePosXController,
                focusNode   : framePosXFocusNode,
                decoration      : const InputDecoration( labelText: 'X位置', ),
                inputFormatters : [FilteringTextInputFormatter.allow(RegExp('[0123456789.-]'))],
                validator    : (String? value){
                  if( value == null ) return null;
                  return posStringValidate(value);
                },
              )
            ),
            Padding(
              padding : const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child   : TextFormField(
                autovalidateMode: AutovalidateMode.always,
                controller  : framePosYController,
                focusNode   : framePosYFocusNode,
                decoration: const InputDecoration( labelText: 'Y位置', ),
                keyboardType: TextInputType.number,
                inputFormatters : [FilteringTextInputFormatter.allow(RegExp('[0123456789.-]'))],
                validator    : (String? value){
                  if( value == null ) return null;
                  return posStringValidate(value);
                },
              ),
            ),
            Padding(
              padding : const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child   : TextFormField(
                autovalidateMode: AutovalidateMode.always,
                controller  : frameSizeRateController,
                focusNode   : frameSizeRateFocusNode,
                decoration  : const InputDecoration( labelText: '大きさ倍率', ),
                keyboardType: TextInputType.number,
                inputFormatters : [FilteringTextInputFormatter.allow(RegExp('[0123456789.]'))],
                validator    : (String? value){
                  if( value == null ) return null;
                  return rateStringValidate(value);
                },
              ),
            )
          ],

          // 
        )
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

    List<Widget> _frameWidgetList = [
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

            if( focusFrame == _frameData){
              framePosXController.value = framePosXController.value.copyWith( text: focusFrame!.position.x.toString() );
              framePosYController.value = framePosYController.value.copyWith( text: focusFrame!.position.y.toString() );
              frameSizeRateController.value = frameSizeRateController.value.copyWith( text: focusFrame!.sizeRate.toString() );
            }

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

            if( focusFrame == _frameData){
              framePosXController.value = framePosXController.value.copyWith( text: focusFrame!.position.x.toString() );
              framePosYController.value = framePosYController.value.copyWith( text: focusFrame!.position.y.toString() );
              frameSizeRateController.value = frameSizeRateController.value.copyWith( text: focusFrame!.sizeRate.toString() );
            }

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

            if( focusFrame == _frameData){
              framePosXController.value = framePosXController.value.copyWith( text: focusFrame!.position.x.toString() );
              framePosYController.value = framePosYController.value.copyWith( text: focusFrame!.position.y.toString() );
              frameSizeRateController.value = frameSizeRateController.value.copyWith( text: focusFrame!.sizeRate.toString() );
            }

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

            if( focusFrame == _frameData){
              framePosXController.value = framePosXController.value.copyWith( text: focusFrame!.position.x.toString() );
              framePosYController.value = framePosYController.value.copyWith( text: focusFrame!.position.y.toString() );
              frameSizeRateController.value = frameSizeRateController.value.copyWith( text: focusFrame!.sizeRate.toString() );
            }

            setState(() { });
          },
        ),
      ),
    ];

    if( focusFrame != _frameData) return _frameWidgetList;

    _frameWidgetList.insert(0,
      Positioned(
        left  : canvasToGlobalPos(_frameData.position).x-2,
        top   : canvasToGlobalPos(_frameData.position).y-2,
        child : Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all( color: Colors.blue.withAlpha(200), width: 4 )
          ),
          width: _frameData.size.x * _frameData.sizeRate+2,
          height: _frameData.size.y * _frameData.sizeRate+4,
        )
      )
    );

    return _frameWidgetList;
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

        if( focusFrame == draggingFrame){
          framePosXController.value = framePosXController.value.copyWith( text: focusFrame!.position.x.toString() );
          framePosYController.value = framePosYController.value.copyWith( text: focusFrame!.position.y.toString() );
          frameSizeRateController.value = frameSizeRateController.value.copyWith( text: focusFrame!.sizeRate.toString() );
        }

        draggingFrame = null;
        setState(() { });
      },      
    );

    Widget dragging = MouseRegion(
      cursor  : SystemMouseCursors.click,
      child   : GestureDetector(
        child   : draggableWidget,
        onTapUp : (_){
          setState(() { });

          if( focusFrame == _frameData){
            focusFrame = null;
            return;
          }
          focusFrame = _frameData;

          framePosXController.value = framePosXController.value.copyWith( text: focusFrame!.position.x.toString() );
          framePosYController.value = framePosYController.value.copyWith( text: focusFrame!.position.y.toString() );
          frameSizeRateController.value = frameSizeRateController.value.copyWith( text: focusFrame!.sizeRate.toString() );

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