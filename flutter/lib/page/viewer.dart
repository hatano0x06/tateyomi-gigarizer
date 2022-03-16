// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
// ignore: unused_import
import 'package:tateyomi_gigarizer/download/canvas_to_image.dart';
// ignore: unused_import
import 'package:tateyomi_gigarizer/download/sample_show_download.dart';
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
    List<Widget> showWidgetList = [_canvasBody(),..._backGroundWidgetList(), ..._frameBodyList()];

    return SingleChildScrollView(
      controller  : verticalScrollController,
      child       : GestureDetector(
        child: Stack( children: showWidgetList ),
        onLongPressEnd: (LongPressEndDetails _tapDown) async {
          if( _tapDown.globalPosition.dy > MediaQuery.of(context).size.height/3) return;
          CanvasToImage(widget.project, frameImageList, backGroundColorChangeList).download();

          // Navigator.push( 
          //   context, 
          //   MaterialPageRoute( builder: (context) => DownloadViewerBoard(
          //     project: widget.project,
          //     frameImageList: frameImageList,
          //     backgroundColorList: backGroundColorChangeList,
          //   ))
          // );
        },
      )
      
      
    );
    // scrollbar
  }

  bool isImageLoaded(){
    if( widget.project.canvasSize == Size.zero ) return false;
    return frameImageList.where((_frameImage) => _frameImage.byteData != null).isNotEmpty;
  }

  double rate(){
    return MediaQuery.of(context).size.width/widget.project.canvasSize.width;
  }


  /* -----  キャンパス設定 ----- */

  Widget _canvasBody(){
    return Column(
      children: [
        Container(
          width : MediaQuery.of(context).size.width,
          height: widget.project.canvasSize.height * rate(),
          color: Colors.white,
        ),
        Container(
          width : MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.white,
          child: Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).size.height/2 - 50),
            child: Column(children: [
              const Center( child: Text("面白かったら、ハート押してね", style: TextStyle(fontSize: 12, color: Colors.grey),), ),
              const SizedBox(height: 5,),
              const Center( child: Icon(Icons.favorite_border, size: 70,), ),
              const SizedBox(height: 10,),
              Padding(
                padding : const EdgeInsets.symmetric(horizontal: 10),
                child   : Row(
                  children: [
                    Expanded(child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.yellow),
                      ),
                      child   : const Text('次の話を読む', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),),
                      onPressed: (){ print("asdfasdf"); },
                    ),),
                  ]
                )
              )
            ]),
          ),
        ),

      ]
    );
  }

  /* -----  背景 ----- */

  List<Widget> _backGroundWidgetList(){

    const int offsetSize = 1;
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
              height: math.max(0, backGroundColorChangeList.first.pos * rate() + offsetSize),
              width : MediaQuery.of(context).size.width,
            )
          )
        );
      }

      // 一番後ろグラデーション以降の色埋め
      if( widget.project.canvasSize.height - (backGroundColorChangeList.last.pos + backGroundColorChangeList.last.size) >= 0 ){
        showWidgetList.add(
          Positioned(
            left  : canvasToGlobalPos(math.Point(0, backGroundColorChangeList.last.pos + backGroundColorChangeList.last.size)).x,
            top   : canvasToGlobalPos(math.Point(0, (backGroundColorChangeList.last.pos + backGroundColorChangeList.last.size)* rate() - offsetSize)).y,
            child : Container(
              color : backGroundColorChangeList.last.targetColor,
              height: (widget.project.canvasSize.height - (backGroundColorChangeList.last.pos + backGroundColorChangeList.last.size))* rate() + offsetSize,
              width : MediaQuery.of(context).size.width,
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
          left  : canvasToGlobalPos(math.Point(0, (preBackGround.pos + preBackGround.size)* rate())).x,
          top   : canvasToGlobalPos(math.Point(0, (preBackGround.pos + preBackGround.size)* rate() - offsetSize)).y,
          child : Container(
            color : backGroundColorChangeList[backGroundIndex-1].targetColor,
            height: math.max(0, ((_background.pos - (preBackGround.pos + preBackGround.size)) * rate() + offsetSize*2)),
            width : MediaQuery.of(context).size.width,
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
          left  : canvasToGlobalPos(math.Point(0,_background.pos)).x * rate(),
          top   : canvasToGlobalPos(math.Point(0,_background.pos)).y * rate(),
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
            height: _background.size * rate(),
            width : MediaQuery.of(context).size.width,
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
    Widget dragging = RotatedBox(
      quarterTurns: _frameData.angle,
      child : Image.memory(
        _frameData.byteData!, 
        width: _frameData.size.x * _frameData.sizeRate * rate(), 
        // height: _frameData.size.y,
        fit: BoxFit.fitWidth, 
        filterQuality: FilterQuality.high,
      )
    );

    return Positioned(
      left  : canvasToGlobalPos(_frameData.position).x * rate(),
      top   : canvasToGlobalPos(_frameData.position).y * rate(),
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
      await Future.forEach(result.files, (PlatformFile _file) async {
        if( _file.path == null ) return;
        if( !(await File(_file.path!).exists()) ) return;

        Uint8List imageBytes = File(_file.path!).readAsBytesSync();
        if( imageBytes.isEmpty ) return;

        Future<ui.Image> _loadImage(Uint8List _charThumbImg) async {
          final Completer<ui.Image> completer = Completer();

          ui.decodeImageFromList(_charThumbImg, (ui.Image convertedImg) {
            return completer.complete(convertedImg);
          });
          return completer.future;
        }
                    
        ui.Image _image = await _loadImage(imageBytes);

        try{
          FrameImage frameImage = frameImageList.singleWhere((_frameImage) => _frameImage.name == _file.name);
          frameImage.byteData = imageBytes;
          frameImage.size = math.Point(_image.width.toDouble(), _image.height.toDouble());
        // ignore: empty_catches
        } catch(e){ }
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