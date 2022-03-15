// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
import 'package:tateyomi_gigarizer/model/background_color_change.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';
import 'package:tateyomi_gigarizer/model/project.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class ViewerPage extends StatefulWidget {
  final DbImpl dbInstance;
  final Project project;

  const ViewerPage({
    Key? key,
    required this.dbInstance, 
    required this.project, 
  }):super(key:key);
  
  @override
  ViewerPageState createState() => ViewerPageState();
}

class ViewerPageState extends State<ViewerPage> {
  List<FrameImage> frameImageList = [];
  List<BackGroundColorChange> backGroundColorChangeList = [];
  final ScrollController verticalScrollController = ScrollController();

  double stricyArea = 10;

  @override
  void initState(){
    super.initState();
    widget.dbInstance.reBuildCanvasBody = (){
      setState(() { });
    };

    verticalScrollController.addListener(() { setState(() { }); });
    getFrameList();
  }
  @override
  void dispose(){
    verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> showWidgetList = [_canvasBody(), ..._backGroundWidgetList(), ..._frameBodyList(),];

    return SingleChildScrollView(
      controller  : verticalScrollController,
      child       : Stack( children: showWidgetList ),
    );
    // scrollbar
  }

  bool isImageLoaded(){
    if( widget.project.canvasSize == Size.zero ) return false;
    return frameImageList.where((_frameImage) => _frameImage.byteData != null).isNotEmpty;
  }


  /* -----  キャンパス設定 ----- */

  Widget _canvasBody(){
    if( !isImageLoaded() ) {
      return Container(
        width : MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.white,
      );
    }

    return Center(
      child: Container(
        width : widget.project.canvasSize.width,
        height: widget.project.canvasSize.height,
        color: Colors.white,
      )
    );
  }

  /* -----  背景 ----- */

  List<Widget> _backGroundWidgetList(){

    const int offsetSize = 10;
    List<Widget> showWidgetList = [];
    
    backGroundColorChangeList.sort((BackGroundColorChange a, BackGroundColorChange b){ return a.pos.compareTo(b.pos); });

    // 一番最初
    if( backGroundColorChangeList.isNotEmpty ) {

      // 先頭のグラデーションまでの色埋め
      if( backGroundColorChangeList.first.pos >= 0 ){
        showWidgetList.add(
          Positioned(
            left  : canvasToGlobalPos(const math.Point(0,0)).x,
            top   : canvasToGlobalPos(const math.Point(0,0)).y,
            child : Container(
              color : Colors.white,
              height: math.max(0, backGroundColorChangeList.first.pos + offsetSize),
              width : widget.project.canvasSize.width,
            )
          )
        );
      }

      // 一番後ろグラデーション以降の色埋め
      if( widget.project.canvasSize.height - (backGroundColorChangeList.last.pos + backGroundColorChangeList.last.size) >= 0 ){
        showWidgetList.add(
          Positioned(
            left  : canvasToGlobalPos(math.Point(0, backGroundColorChangeList.last.pos + backGroundColorChangeList.last.size)).x,
            top   : canvasToGlobalPos(math.Point(0, backGroundColorChangeList.last.pos + backGroundColorChangeList.last.size - offsetSize)).y,
            child : Container(
              color : backGroundColorChangeList.last.targetColor,
              height: widget.project.canvasSize.height - (backGroundColorChangeList.last.pos + backGroundColorChangeList.last.size) + offsetSize,
              width : widget.project.canvasSize.width,
            )
          )
        );
      }
    }

    // グラデーション間の穴埋め
    for (BackGroundColorChange _background in backGroundColorChangeList) {
      int backGroundIndex = backGroundColorChangeList.indexOf(_background);
      if( backGroundIndex == 0 ) continue;
      
      BackGroundColorChange preBackGround = backGroundColorChangeList[backGroundIndex-1];

      showWidgetList.add(
        Positioned(
          left  : canvasToGlobalPos(math.Point(0, preBackGround.pos + preBackGround.size)).x,
          top   : canvasToGlobalPos(math.Point(0, preBackGround.pos + preBackGround.size - offsetSize)).y,
          child : Container(
            color : backGroundColorChangeList[backGroundIndex-1].targetColor,
            height: math.max(0, (_background.pos - (preBackGround.pos + preBackGround.size) + offsetSize*2)),
            width : widget.project.canvasSize.width,
          )
        )
      );
    }

    // グラデーション
    for (BackGroundColorChange _background in backGroundColorChangeList) {

      int backGroundIndex = backGroundColorChangeList.indexOf(_background);
      Color preColor = (backGroundIndex == 0 ? Colors.white : backGroundColorChangeList[backGroundIndex-1].targetColor);

      showWidgetList.add(
        Positioned(
          left  : canvasToGlobalPos(math.Point(0,_background.pos)).x,
          top   : canvasToGlobalPos(math.Point(0,_background.pos)).y,
          child : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin : FractionalOffset.topCenter,
                end   : FractionalOffset.bottomCenter,
                colors: [ preColor, _background.targetColor ],
                stops: const [
                  0.0,
                  1.0,
                ],
              ),
            ),
            height: _background.size,
            width : widget.project.canvasSize.width,
          )
        )
      );
    }

    return showWidgetList;
  }


  /* -----  コマ周り ----- */

  List<Widget> _frameBodyList(){
    List<Widget> showWidgetList = [];

    for (FrameImage _frameData in frameImageList) {
      if( _frameData.byteData == null ) continue;
      if( _frameData.sizeRate <= 0.0 ) continue;

      showWidgetList.add(_frameDraggingWidget(_frameData));
    }

    if(showWidgetList.isEmpty) return [];

    return showWidgetList;
  }

  // コマの表示
  Widget _frameDraggingWidget(FrameImage _frameData){
    Widget dragging = MouseRegion(
      cursor  : SystemMouseCursors.click,
      child   : RotatedBox(
        quarterTurns: _frameData.angle,
        child : Image.memory(
          _frameData.byteData!, 
          width: _frameData.size.x * _frameData.sizeRate, 
          // height: _frameData.size.y,
          fit: BoxFit.fitWidth, 
          filterQuality: FilterQuality.high,
        )
      ),
    );

    return Positioned(
      left  : canvasToGlobalPos(_frameData.position).x,
      top   : canvasToGlobalPos(_frameData.position).y,
      child : dragging,
    );
  }

  void getFrameList(){
    widget.dbInstance.getFrameList(widget.project).then((_frameList) async {
      frameImageList = _frameList;
      setState(() { });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple     : true,
        type              : FileType.custom,
        allowedExtensions : ['png' ],
      );

      if(result == null) return;
      
      backGroundColorChangeList = await widget.dbInstance.getBackGroundColorList(widget.project);

      // 画像読み込み
      await Future.forEach(result.files.where((_file) => _file.extension != null && _file.extension == "png").toList(), (PlatformFile _file) async {
        if(_file.bytes == null) return;

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
          frameImage.size = math.Point(_image.width.toDouble(), _image.height.toDouble());
        } catch(e){
          FrameImage newImage = FrameImage(
            dbInstance  : widget.dbInstance,
            project     : widget.project,
            dbIndex     : "",
            byteData    : _file.bytes, 
            name        : _file.name,
            angle       : 0,
            sizeRate    : 1.0,
            position    : const math.Point<double>(0,0),
            size        : math.Point(_image.width.toDouble(), _image.height.toDouble())
          );
          newImage.save();

          frameImageList.add( newImage );
        }
      });
      
      setState(() { });
    });
  }  

  math.Point<double> canvasToGlobalPos(math.Point<double> _pos){
    Offset _offsetSize = Offset(
      0,
      (verticalScrollController.hasClients ? verticalScrollController.position.pixels : 0)
    );

    return math.Point(
      _pos.x + _offsetSize.dx,
      _pos.y,
      // _pos.y - _offsetSize.dy,
    );
  }

  math.Point<double> globalToCanvasPos(math.Point<double> _pos){
    Offset _offsetSize = Offset(
      0,
      (verticalScrollController.hasClients ? verticalScrollController.position.pixels : 0)
    );

    return math.Point(
      _pos.x - _offsetSize.dx,
      _pos.y + _offsetSize.dy,
    );
  }  

}