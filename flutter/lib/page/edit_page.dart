// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:async';
import 'dart:typed_data';

import 'package:adaptive_scrollbar/adaptive_scrollbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';
import 'package:tateyomi_gigarizer/model/keyboard.dart';
import 'package:tateyomi_gigarizer/model/project.dart';
import 'package:tateyomi_gigarizer/page/corner_ball.dart';
import 'package:tateyomi_gigarizer/download/canvas_to_image.dart';
import 'package:tateyomi_gigarizer/dialog/shortcuts_info_dialog.dart';
import 'package:universal_html/html.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:convert';

class EditPage extends StatefulWidget {
  final DbImpl dbInstance;
  final Project project;

  const EditPage({
    Key? key,
    required this.dbInstance, 
    required this.project, 
  }):super(key:key);
  
  @override
  EditPageState createState() => EditPageState();
}

class EditPageState extends State<EditPage> {
  List<FrameImage> frameImageList = [];

  FrameImage? focusFrame;
  List<FrameImage> focusFrameDependList = [];

  final ScrollController verticalScrollController = ScrollController();
  final ScrollController horizonScrollController  = ScrollController();

  final TextEditingController framePosXController = TextEditingController();
  final TextEditingController framePosYController = TextEditingController();
  final TextEditingController frameSizeRateController = TextEditingController();
  final FocusNode framePosXFocusNode = FocusNode();
  final FocusNode framePosYFocusNode = FocusNode();
  final FocusNode frameSizeRateFocusNode = FocusNode();

  final TextEditingController canvasSizeXController = TextEditingController();
  final TextEditingController canvasSizeYController = TextEditingController();
  final FocusNode canvasSizeXFocusNode = FocusNode();
  final FocusNode canvasSizeYFocusNode = FocusNode();

  final TextEditingController downloadController = TextEditingController();
  final FocusNode downloadFocusNode = FocusNode();

  Size canvasSize = Size.zero;

  bool showCanvasEdit = false;

  @override
  void initState(){
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_){

    // TODO: こいつも外部からの読み込みにする
      // comico設定　https://tips.clip-studio.com/ja-jp/articles/2781#:~:text=%E8%A7%A3%E5%83%8F%E5%BA%A6%E3%81%AF%E5%8D%B0%E5%88%B7%E3%81%AE%E9%9A%9B,%E3%81%99%E3%82%8B%E3%81%93%E3%81%A8%E3%81%8C%E5%A4%9A%E3%81%84%E3%81%A7%E3%81%99%E3%80%82
      canvasSize = const Size(
        690, 2000
        // 690, 20000
      );
      canvasSizeXController.value = canvasSizeXController.value.copyWith( text: canvasSize.width.toString() );
      canvasSizeYController.value = canvasSizeYController.value.copyWith( text: canvasSize.height.toString() );

      setState(() { });
    });

    verticalScrollController.addListener(() {
      setState(() { });
    });
    horizonScrollController.addListener(() {
      setState(() { });
    });

    framePosXController.addListener((){
      if(posStringValidate(framePosXController.text) != null ) return;

      focusFrame!.position = Point<double>(double.parse(framePosXController.text), focusFrame!.position.y);
      setState(() { });
    });    

    framePosYController.addListener((){
      if(posStringValidate(framePosYController.text) != null ) return;

      double prePosY = focusFrame!.position.y;
      double newPosY = double.parse(framePosYController.text);

      focusFrame!.position = Point<double>(focusFrame!.position.x, newPosY);

      double diffY = prePosY - newPosY;
      for (FrameImage _depandFrame in focusFrameDependList) {
        _depandFrame.position = Point(_depandFrame.position.x, _depandFrame.position.y-diffY);
      }

      setState(() { });
    });    

    frameSizeRateController.addListener((){
      if(rateStringValidate(frameSizeRateController.text) != null ) return;

      double _rate = double.parse(frameSizeRateController.text);
      _rate = math.max(_rate, 0.01);

      double preBottom = focusFrame!.rotateSize.y * focusFrame!.sizeRate;
      double newBottom = focusFrame!.rotateSize.y * _rate;

      focusFrame!.sizeRate = _rate;

      double diffY = preBottom - newBottom;
      for (FrameImage _depandFrame in focusFrameDependList) {
        _depandFrame.position = Point(_depandFrame.position.x, _depandFrame.position.y-diffY);
      }

      setState(() { });
    });


    canvasSizeXController.addListener((){
      if(posStringValidate(canvasSizeXController.text) != null ) return;

      double preCanvasWidth = canvasSize.width;
      double newCanvasWidth = double.parse(canvasSizeXController.text);

      if(newCanvasWidth < 100) return;

      double changeRate = newCanvasWidth/preCanvasWidth;

      for (FrameImage _frameImage in frameImageList) {
        _frameImage.position = Point(_frameImage.position.x * changeRate, _frameImage.position.y * changeRate);
        _frameImage.sizeRate = _frameImage.sizeRate * changeRate;
      }

      canvasSize = Size(newCanvasWidth, canvasSize.height);
      setState(() { });
    });    

    canvasSizeYController.addListener((){
      if(posStringValidate(canvasSizeYController.text) != null ) return;

      canvasSize = Size(canvasSize.width, double.parse(canvasSizeYController.text));
      setState(() { });
    });    


    downloadController.value = downloadController.value.copyWith( text: widget.project.downloadName );
    downloadController.addListener(() {
      setState(() { });
    });

  }

  @override
  void dispose(){
    verticalScrollController.dispose();
    horizonScrollController.dispose();
    
    framePosXController.dispose();
    framePosYController.dispose();
    frameSizeRateController.dispose();

    framePosXFocusNode.dispose();
    framePosYFocusNode.dispose();
    frameSizeRateFocusNode.dispose();

    canvasSizeXController.dispose();
    canvasSizeYController.dispose();
    canvasSizeXFocusNode.dispose();
    canvasSizeYFocusNode.dispose();

    downloadController.dispose();
    downloadFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> showWidgetList = [_backGroundBody(), ..._canvasBody(), ..._frameBodyList()];

    Widget outsideGraySpace(){
      return Container(
        width: sideSpaceWidth(),
        height: MediaQuery.of(context).size.height,
        color: Colors.grey.withAlpha(200),
      );
    }

    Widget _body = Stack(
      children: [
        SingleChildScrollView(
          controller  : verticalScrollController,
          child       : Stack( children: showWidgetList ),
        ),
        horizonScrollController.hasClients ? Positioned(
          left  : -horizonScrollController.position.pixels,
          child : outsideGraySpace(),
        ) : Container(),
        horizonScrollController.hasClients ? Positioned(
          left  : -horizonScrollController.position.pixels + canvasSize.width + sideSpaceWidth(),
          child : outsideGraySpace(),
        ) : Container(),
        focusDetailSettingBox(),
        canvasSizeSettingBox()
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

    // shortCuts
    _body = KeyBoardShortcuts(
      keysToPressList: _shortCutKeyMap.keys.toList(),
      onKeysPressed: (int _shortCutIndex){
        if (!mounted)       return;
        if( ModalRoute.of(context) == null ) return;
        if( !ModalRoute.of(context)!.isCurrent ) return;

        String shortCutType = _shortCutKeyMap.values.toList()[_shortCutIndex];

        if(framePosXFocusNode.hasFocus || framePosYFocusNode.hasFocus || frameSizeRateFocusNode.hasFocus || downloadFocusNode.hasFocus )  return;
        if( focusFrame != null ){

          double moveSize = 0.1;
          if( shortCutType == TYPE_SHORTCUT_UP    ){
            focusFrame!.position = Point(focusFrame!.position.x, focusFrame!.position.y-moveSize);
            for (FrameImage _depandFrame in focusFrameDependList) {
              _depandFrame.position = Point(_depandFrame.position.x, _depandFrame.position.y-moveSize);
            }
          }
          if( shortCutType == TYPE_SHORTCUT_DOWN  ){
            focusFrame!.position = Point(focusFrame!.position.x, focusFrame!.position.y+moveSize);
            for (FrameImage _depandFrame in focusFrameDependList) {
              _depandFrame.position = Point(_depandFrame.position.x, _depandFrame.position.y+moveSize);
            }
          }

          if( shortCutType == TYPE_SHORTCUT_LEFT  ) focusFrame!.position = Point(focusFrame!.position.x-moveSize  , focusFrame!.position.y);
          if( shortCutType == TYPE_SHORTCUT_RIGHT ) focusFrame!.position = Point(focusFrame!.position.x+moveSize  , focusFrame!.position.y);


          framePosXController.value = framePosXController.value.copyWith( text: focusFrame!.position.x.toString() );
          framePosYController.value = framePosYController.value.copyWith( text: focusFrame!.position.y.toString() );
          frameSizeRateController.value = frameSizeRateController.value.copyWith( text: focusFrame!.sizeRate.toString() );
          setState(() { });
        }

      },
      child: _body
    );    

    // scrollbar
    double scrollbarSize = 15.0;
    _body = AdaptiveScrollbar(
      controller: verticalScrollController,
      width: scrollbarSize,
      child: AdaptiveScrollbar(
        controller: horizonScrollController,
        width: scrollbarSize,
        position: ScrollbarPosition.bottom,
        underSpacing: EdgeInsets.only(bottom: scrollbarSize),
        child: _body
      )
    );

    // gfesture focus
    _body = GestureDetector(
      child     : _body,
      onTapUp   : (_){
        focusFrame = null;
        focusFrameDependList.clear();
        
        setState(() { });
      },
    );

    return Scaffold(
      appBar: AppBar(
        title   : Text( "編集ページ ： " + widget.project.name ),
        actions : !isImageLoaded() ? [] : [
            IconButton(
            icon    : const Icon(Icons.swap_horiz_outlined),
            tooltip : "左右反転",
            onPressed: (){

              for (FrameImage _frameImage in frameImageList) {
                _frameImage.position = Point(
                  (canvasSize.width - (_frameImage.position.x + _frameImage.rotateSize.x * _frameImage.sizeRate)), 
                  _frameImage.position.y
                );
              }
              
              setState(() { });
            },
          ),
          IconButton(
            icon    : const Icon(Icons.photo_size_select_large),
            tooltip : "キャンパスのサイズ変更",
            onPressed: (){
              FocusScope.of(context).unfocus();
              focusFrame = null;
              showCanvasEdit = true;
              setState(() { });
            },
          ),
          Padding(
            padding : const EdgeInsets.symmetric(vertical: 5),
            child   : Container(
              padding     : const EdgeInsets.symmetric(horizontal: 20),
              width: 300,
              height: 30,
              decoration  : BoxDecoration(
                borderRadius  : BorderRadius.circular(30.0),
                border        : Border.all( color: Colors.white.withAlpha(200) ),
                color         : Colors.white.withAlpha(120),
              ),
              child: Padding(
                padding : const EdgeInsets.only(bottom:8),
                child   : TextFormField(
                  controller: downloadController,
                  focusNode : downloadFocusNode,
                  decoration      : const InputDecoration( hintText: "ダウンロード名", ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip : "ダウンロード",
            onPressed: (){
              if( frameImageList.isEmpty ) return;

              CanvasToImage(frameImageList, canvasSize).download(downloadController.text);
            },
          ),
          IconButton(
            icon    : const Icon(Icons.help_outline),
            onPressed: (){
              FocusScope.of(context).unfocus();
              showDialog( context: context, builder: (BuildContext context) => const ShortCutInfoDialog( ) );
            },
          ),
          const SizedBox(width: 10,),
        ]
      ),

      body : _body,
    );
  }



  Widget canvasSizeSettingBox(){
    if(focusFrame != null ) return Container();
    if(!showCanvasEdit) return Container();

    Widget textFormWidget(TextEditingController editController, FocusNode focusNode, String labeltext, List<TextInputFormatter> formatList, String? Function(String?)? validatorFunc){
      return TextFormField(
        autovalidateMode: AutovalidateMode.always,
        controller  : editController,
        focusNode   : focusNode,
        decoration      : InputDecoration( labelText: labeltext, ),
        inputFormatters : formatList,
        validator    : validatorFunc,
      );
    }

    return Positioned(
      top   : 20,
      left  : sideSpaceWidth() + canvasSize.width - horizonScrollController.position.pixels + 20,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all( color: Colors.black, )
        ),
        child: Padding(
          padding : const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child   : Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child :  Text("キャンパスサイズの編集", style: TextStyle( fontWeight: FontWeight.bold), ),
              ),
              textFormWidget(canvasSizeXController, canvasSizeXFocusNode, "幅", [FilteringTextInputFormatter.allow(RegExp('[0123456789.]'))], 
                (String? value){
                  if( value == null ) return null;
                  return rateStringValidate(value);
                }
              ),
              textFormWidget(canvasSizeYController, canvasSizeYFocusNode, "縦", [FilteringTextInputFormatter.allow(RegExp('[0123456789.]'))], 
                (String? value){
                  if( value == null ) return null;
                  return rateStringValidate(value);
                }
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget focusDetailSettingBox(){
    if(focusFrame == null ) return Container();

    Widget textFormWidget(TextEditingController editController, FocusNode focusNode, String labeltext, List<TextInputFormatter> formatList, String? Function(String?)? validatorFunc){
      return TextFormField(
        autovalidateMode: AutovalidateMode.always,
        controller  : editController,
        focusNode   : focusNode,
        decoration      : InputDecoration( labelText: labeltext, ),
        inputFormatters : formatList,
        validator    : validatorFunc,
      );
    }

    return Positioned(
      top   : 20,
      left  : sideSpaceWidth() + canvasSize.width - horizonScrollController.position.pixels + 20,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all( color: Colors.black, )
        ),
        child: Padding(
          padding : const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child   : Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child :  Text("コマの編集", style: TextStyle( fontWeight: FontWeight.bold), ),
              ),
              textFormWidget(framePosXController, framePosXFocusNode, "X位置", [FilteringTextInputFormatter.allow(RegExp('[0123456789.-]'))], 
                (String? value){
                  if( value == null ) return null;
                  return posStringValidate(value);
                }
              ),
              textFormWidget(framePosYController, framePosYFocusNode, "Y位置", [FilteringTextInputFormatter.allow(RegExp('[0123456789.-]'))], 
                (String? value){
                  if( value == null ) return null;
                  return posStringValidate(value);
                }
              ),
              textFormWidget(frameSizeRateController, frameSizeRateFocusNode, "大きさ倍率", [FilteringTextInputFormatter.allow(RegExp('[0123456789.]'))], 
                (String? value){
                  if( value == null ) return null;
                  return rateStringValidate(value);
                }
              ),
              Container(
                padding   : const EdgeInsets.symmetric(vertical: 10),
                alignment : Alignment.centerLeft,
                child : Text("右端からの距離 : " + (canvasSize.width - (focusFrame!.position.x + focusFrame!.size.x * focusFrame!.sizeRate)).toString() ),
              ),
              Align(
                alignment : Alignment.centerLeft,
                child     : IconButton(
                  icon: const Icon(Icons.rotate_right_outlined),
                  onPressed: (){
                    focusFrame!.angle += 1;
                    focusFrame!.angle = focusFrame!.angle%4;
                    setState(() { });
                  }, 
                )
              )
            ],
          ),
        ),
      ),
    );
  }

  double windowZoomSize(){
    return window.devicePixelRatio/1.25;
  }

  bool isImageLoaded(){
    return frameImageList.where((_frameImage) => _frameImage.byteData != null).isNotEmpty;
  }

  double sideSpaceWidth(){
    if( windowZoomSize() >= 1.0 ){
      Size realWindowSize = Size(
        MediaQuery.of(context).size.width*windowZoomSize(),
        MediaQuery.of(context).size.height*windowZoomSize(),
      );


      return math.max( (realWindowSize.width - canvasSize.width)/2, 0);
    }

    return math.max( (MediaQuery.of(context).size.width - canvasSize.width)/2, 0);
  }  

  List<Widget> _canvasBody(){
    if( !isImageLoaded() ) {
      return [
        Container(
          width : MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height - kToolbarHeight,
          color: Colors.white,
        )
      ];
    }

    Widget horizonScrollWidget = SingleChildScrollView(
      controller      : horizonScrollController,
      scrollDirection : Axis.horizontal,
      child: Row(
        children: [
          Container(
            color: Colors.grey,
            width : sideSpaceWidth(),
            height: canvasSize.height,
          ),
          Container(
            width : canvasSize.width,
            height: canvasSize.height,
            color: Colors.white,
          ),
          Container(
            color: Colors.grey,
            width : sideSpaceWidth(),
            height: canvasSize.height,
          ),
        ],
      ),
    );

    Point<double> _dragPointPos = Point(canvasSize.width/2, canvasSize.height);

    double ballDiameter = 20.0;

    return [
      horizonScrollWidget,
      Positioned(
        left  : canvasToGlobalPos(_dragPointPos).x - ballDiameter / 2,
        top   : canvasToGlobalPos(_dragPointPos).y - ballDiameter / 2,
        child: CornerBallWidget(
          cursor      : SystemMouseCursors.resizeUpDown,
          ballDiameter: ballDiameter,
          onDragStart : (){ },
          onDragEnd   : (){
            // TODO: 保存処理
          },
          onDrag      : (dragPos) {
            Point<double> canvasDragPos = globalToCanvasPos(Point<double>(dragPos.dx, dragPos.dy));
            canvasSize = Size(canvasSize.width, canvasDragPos.y);
            setState(() { });
          },
        ),
      ),
    ];
  }

  Widget _backGroundBody(){
    if( !isImageLoaded() ) return Container();

    List<double> bottomList = [canvasSize.height];
    for (FrameImage _frameImage in frameImageList) {
      bottomList.add( _frameImage.position.y + _frameImage.rotateSize.y * _frameImage.sizeRate );
    }

    return Container(
      width : MediaQuery.of(context).size.width,
      height: bottomList.reduce(math.max) + MediaQuery.of(context).size.height*3/4,
      color: Colors.transparent,
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
        _frameData.position.x + _frameData.rotateSize.x * _frameData.sizeRate,
        _frameData.position.y + _frameData.rotateSize.y * _frameData.sizeRate,
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
        left  : canvasToGlobalPos(_frameData.position).x + _frameData.rotateSize.x * _frameData.sizeRate - ballDiameter / 2,
        top   : canvasToGlobalPos(_frameData.position).y - ballDiameter / 2,
        child: CornerBallWidget(
          cursor      : SystemMouseCursors.resizeUpRightDownLeft,
          ballDiameter: ballDiameter,
          onDragStart : (){ tempSavePos(); },
          onDragEnd   : (){ _frameData.save(); },
          onDrag      : (dragPos) {
            Point<double> canvasDragPos = globalToCanvasPos(Point<double>(dragPos.dx, dragPos.dy));

            _frameData.sizeRate = math.max(
              (canvasDragPos.x - dragStartLeftTopPos.x).abs()/_frameData.rotateSize.x, 
              (canvasDragPos.y - dragStartRightBottomPos.y).abs()/_frameData.rotateSize.y, 
            );
            _frameData.position = Point(
              _frameData.position.x,
              dragStartRightBottomPos.y - _frameData.rotateSize.y * _frameData.sizeRate,
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
        top   : canvasToGlobalPos(_frameData.position).y + _frameData.rotateSize.y * _frameData.sizeRate - ballDiameter / 2,
        child: CornerBallWidget(
          cursor      : SystemMouseCursors.resizeUpRightDownLeft,
          ballDiameter: ballDiameter,
          onDragStart : (){ tempSavePos(); },
          onDragEnd   : (){ _frameData.save(); },
          onDrag      : (dragPos) {
            Point<double> canvasDragPos = globalToCanvasPos(Point<double>(dragPos.dx, dragPos.dy));

            Point<double> prePos = _frameData.position;
            double preSizeRate = _frameData.sizeRate;

            _frameData.sizeRate = math.max(
              (canvasDragPos.x - dragStartRightBottomPos.x).abs()/_frameData.rotateSize.x, 
              (canvasDragPos.y - dragStartLeftTopPos.y).abs()/_frameData.rotateSize.y, 
            );
            _frameData.position = Point(
              dragStartRightBottomPos.x - _frameData.rotateSize.x * _frameData.sizeRate,
              _frameData.position.y,
            );

            if( focusFrame == _frameData){
              framePosXController.value = framePosXController.value.copyWith( text: focusFrame!.position.x.toString() );
              framePosYController.value = framePosYController.value.copyWith( text: focusFrame!.position.y.toString() );
              frameSizeRateController.value = frameSizeRateController.value.copyWith( text: focusFrame!.sizeRate.toString() );
            }

            double prePosY = prePos.y + _frameData.rotateSize.y * preSizeRate;
            double newPosY = _frameData.position.y + _frameData.rotateSize.y * _frameData.sizeRate;

            double diffY = prePosY - newPosY;

            if(RawKeyboard.instance.keysPressed.where((_pressd) => _pressd.keyLabel == LogicalKeyboardKey.controlLeft.keyLabel).isNotEmpty){
              focusFrameDependList = frameImageList.where((_frame) => _frame.position.y > _frameData.position.y ).toList();
            }
            for (FrameImage _depandFrame in focusFrameDependList) {
              _depandFrame.position = Point(_depandFrame.position.x, _depandFrame.position.y-diffY);
            }

            setState(() { });
          },
        ),
      ),

      // 右下
      Positioned(
        left  : canvasToGlobalPos(_frameData.position).x + _frameData.rotateSize.x * _frameData.sizeRate - ballDiameter / 2,
        top   : canvasToGlobalPos(_frameData.position).y + _frameData.rotateSize.y * _frameData.sizeRate - ballDiameter / 2,
        child: CornerBallWidget(
          cursor      : SystemMouseCursors.resizeUpLeftDownRight,
          ballDiameter: ballDiameter,
          onDragStart : (){ tempSavePos(); },
          onDragEnd   : (){ _frameData.save(); },
          onDrag      : (dragPos) {
            Point<double> canvasDragPos = globalToCanvasPos(Point<double>(dragPos.dx, dragPos.dy));

            Point<double> prePos = _frameData.position;
            double preSizeRate = _frameData.sizeRate;

            _frameData.sizeRate = math.max(
              (canvasDragPos.x - dragStartLeftTopPos.x).abs()/_frameData.rotateSize.x, 
              (canvasDragPos.y - dragStartLeftTopPos.y).abs()/_frameData.rotateSize.y, 
            );

            if( focusFrame == _frameData){
              framePosXController.value = framePosXController.value.copyWith( text: focusFrame!.position.x.toString() );
              framePosYController.value = framePosYController.value.copyWith( text: focusFrame!.position.y.toString() );
              frameSizeRateController.value = frameSizeRateController.value.copyWith( text: focusFrame!.sizeRate.toString() );
            }

            double prePosY = prePos.y + _frameData.rotateSize.y * preSizeRate;
            double newPosY = _frameData.position.y + _frameData.rotateSize.y * _frameData.sizeRate;

            double diffY = prePosY - newPosY;
            if(RawKeyboard.instance.keysPressed.where((_pressd) => _pressd.keyLabel == LogicalKeyboardKey.controlLeft.keyLabel).isNotEmpty){
              focusFrameDependList = frameImageList.where((_frame) => _frame.position.y > _frameData.position.y ).toList();
            }
            for (FrameImage _depandFrame in focusFrameDependList) {
              _depandFrame.position = Point(_depandFrame.position.x, _depandFrame.position.y-diffY);
            }

            setState(() { });
          },
        ),
      ),
    ];

    Widget _frameColorWidget(Color _color){
      return Positioned(
        left  : canvasToGlobalPos(_frameData.position).x-2,
        top   : canvasToGlobalPos(_frameData.position).y-2,
        child : Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all( color: _color.withAlpha(200), width: 4 )
          ),
          width   : _frameData.rotateSize.x * _frameData.sizeRate+4,
          height  : _frameData.rotateSize.y * _frameData.sizeRate+4,
        )
      );
    }

    // focusしているときは、青い四角い枠をつける
    if( focusFrame == _frameData) _frameWidgetList.insert(0, _frameColorWidget(Colors.blue) );

    // 従属しているときは、赤い四角い枠をつける
    if( focusFrameDependList.contains(_frameData)) _frameWidgetList.insert(0, _frameColorWidget(Colors.grey) );

    return _frameWidgetList;
  }

  // コマの表示（ドラッグ
  FrameImage? draggingFrame;
  Widget _frameDraggingWidget(FrameImage _frameData){
    frameWidgetUnit(bool _isDragging){
      return RotatedBox(
        quarterTurns: _frameData.angle,
        child : Opacity(
          opacity: _isDragging ? 0.5 : 1.0,
          child: Image.memory(
            _frameData.byteData!, 
            width: _frameData.size.x * _frameData.sizeRate, 
            // height: _frameData.size.y,
            fit: BoxFit.fitWidth, 
            filterQuality: FilterQuality.high,
          )
        )
      );
    }

    Widget draggableWidget = Draggable(
      child             : frameWidgetUnit(false),
      childWhenDragging : frameWidgetUnit(true),
      feedback          : frameWidgetUnit(true),
      onDragStarted: (){
        draggingFrame = _frameData;
        if(RawKeyboard.instance.keysPressed.where((_pressd) => _pressd.keyLabel == LogicalKeyboardKey.controlLeft.keyLabel).isNotEmpty){
          focusFrameDependList = frameImageList.where((_frame) => _frame.position.y > draggingFrame!.position.y ).toList();
        }

        setState(() { });
      },
      onDraggableCanceled: (_, _offset){

        Point<double> prePos = _frameData.position;
        double preSizeRate = _frameData.sizeRate;

        draggingFrame!.position = Point<double>(
          globalToCanvasPos(Point<double>(_offset.dx, _offset.dy)).x, 
          globalToCanvasPos(Point<double>(_offset.dx, _offset.dy)).y - kToolbarHeight
        );

        if( focusFrame == draggingFrame){
          framePosXController.value = framePosXController.value.copyWith( text: focusFrame!.position.x.toString() );
          framePosYController.value = framePosYController.value.copyWith( text: focusFrame!.position.y.toString() );
          frameSizeRateController.value = frameSizeRateController.value.copyWith( text: focusFrame!.sizeRate.toString() );
        }

        double prePosY = prePos.y + _frameData.rotateSize.y * preSizeRate;
        double newPosY = _frameData.position.y + _frameData.rotateSize.y * _frameData.sizeRate;

        double diffY = prePosY - newPosY;
        for (FrameImage _depandFrame in focusFrameDependList) {
          _depandFrame.position = Point(_depandFrame.position.x, _depandFrame.position.y-diffY);
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
            focusFrameDependList.clear();
            return;
          }
          focusFrame = _frameData;
          showCanvasEdit = false;

          // ctrlを押しながらやると、従属して動く
          if(RawKeyboard.instance.keysPressed.where((_pressd) => _pressd.keyLabel == LogicalKeyboardKey.controlLeft.keyLabel).isNotEmpty){
            focusFrameDependList = frameImageList.where((_frame) => _frame.position.y > focusFrame!.position.y ).toList();
          }

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
            // TODO: asdf
            // frameImageList.add(
            //   FrameImage(
            //     dbInstance  : widget.dbInstance,
            //     byteData    : _file.bytes, 
            //     name        : _file.name,
            //     angle       : 0,
            //     sizeRate    : -1.0,
            //     position    : const Point<double>(0,0),
            //     size        : Point(_image.width.toDouble(), _image.height.toDouble())
            //   )
            // );
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
      sideSpaceWidth() - (horizonScrollController.hasClients ? horizonScrollController.position.pixels : 0),
      (verticalScrollController.hasClients ? verticalScrollController.position.pixels : 0)
    );

    return Point(
      _pos.x + _offsetSize.dx,
      _pos.y,
      // _pos.y - _offsetSize.dy,
    );
  }

  Point<double> globalToCanvasPos(Point<double> _pos){
    Offset _offsetSize = Offset(
      sideSpaceWidth() - (horizonScrollController.hasClients ? horizonScrollController.position.pixels : 0),
      (verticalScrollController.hasClients ? verticalScrollController.position.pixels : 0)
    );

    return Point(
      _pos.x - _offsetSize.dx,
      _pos.y + _offsetSize.dy,
    );
  }  

}