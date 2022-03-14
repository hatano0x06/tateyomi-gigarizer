// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:async';
import 'dart:typed_data';

import 'package:adaptive_scrollbar/adaptive_scrollbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
import 'package:tateyomi_gigarizer/dialog/color_picker.dart';
import 'package:tateyomi_gigarizer/model/background_color_change.dart';
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
  List<BackGroundColorChange> backGroundColorChangeList = [];

  FrameImage? focusFrame;
  BackGroundColorChange? focusBackGroundColorChange;
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

  bool showCanvasEdit = false;

  double stricyArea = 10;

  // TODO: 背景
  //  背景の追加
  //  背景の変更
  //  背景の大きさの変更（ドラッグ
  //  背景の削除
  //  DB(クラウド)
  //  ダウンロード


  @override
  void initState(){
    super.initState();
    widget.dbInstance.reBuildCanvasBody = (){
      setState(() { });
    };

    setEditerEvent();
    getFrameList();
  }

  void setEditerEvent(){
    canvasSizeXController.value = canvasSizeXController.value.copyWith( text: widget.project.canvasSize.width.toString() );
    canvasSizeYController.value = canvasSizeYController.value.copyWith( text: widget.project.canvasSize.height.toString() );

    verticalScrollController.addListener(() { setState(() { }); });
    horizonScrollController.addListener(() { setState(() { }); });

    framePosXController.addListener((){
      if(posStringValidate(framePosXController.text) != null ) return;

      focusFrame!.position = Point<double>(double.parse(framePosXController.text), focusFrame!.position.y);
      focusFrame?.save();
      setState(() { });
    });    

    framePosYController.addListener((){
      if(posStringValidate(framePosYController.text) != null ) return;

      double prePosY = focusFrame!.position.y;
      double newPosY = double.parse(framePosYController.text);

      focusFrame!.position = Point<double>(focusFrame!.position.x, newPosY);
      focusFrame?.save();

      double diffY = prePosY - newPosY;
      for (FrameImage _depandFrame in focusFrameDependList) {
        _depandFrame.position = Point(_depandFrame.position.x, _depandFrame.position.y-diffY);
        _depandFrame.save();
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
      focusFrame?.save();

      double diffY = preBottom - newBottom;
      for (FrameImage _depandFrame in focusFrameDependList) {
        _depandFrame.position = Point(_depandFrame.position.x, _depandFrame.position.y-diffY);
        _depandFrame.save();
      }

      setState(() { });
    });


    canvasSizeXController.addListener((){
      if(posStringValidate(canvasSizeXController.text) != null ) return;

      double preCanvasWidth = widget.project.canvasSize.width;
      double newCanvasWidth = double.parse(canvasSizeXController.text);

      if(newCanvasWidth < 100) return;

      double changeRate = newCanvasWidth/preCanvasWidth;

      for (FrameImage _frameImage in frameImageList) {
        _frameImage.position = Point(_frameImage.position.x * changeRate, _frameImage.position.y * changeRate);
        _frameImage.sizeRate = _frameImage.sizeRate * changeRate;
        _frameImage.save();
      }

      widget.project.canvasSize = Size(newCanvasWidth, widget.project.canvasSize.height);
      widget.project.save();
      setState(() { });
    });    

    canvasSizeYController.addListener((){
      if(posStringValidate(canvasSizeYController.text) != null ) return;

      widget.project.canvasSize = Size(widget.project.canvasSize.width, double.parse(canvasSizeYController.text));
      widget.project.save();
      setState(() { });
    });    


    downloadController.value = downloadController.value.copyWith( text: widget.project.downloadName );
    downloadController.addListener(() {
      widget.project.downloadName = downloadController.text;
      widget.project.save();

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
    List<Widget> showWidgetList = [_backGroundBody(), ..._canvasBody(), ..._backGroundWidgetList(), ..._frameBodyList()];

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
          left  : -horizonScrollController.position.pixels + widget.project.canvasSize.width + sideSpaceWidth(),
          child : outsideGraySpace(),
        ) : Container(),
        focusDetailSettingBox(),
        canvasSizeSettingBox()
      ],
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

    _body = shortCutsWidget(_body);
    _body = gestureWidget(_body); 

    return Scaffold(
      appBar: AppBar(
        title   : Text( "編集ページ ： " + widget.project.name ),
        actions : !isImageLoaded() ? [] : [
            IconButton(
              icon    : const Icon(Icons.gradient),
              tooltip : "背景の追加",
              onPressed: (){
                showDialog(
                  context: context, 
                  builder: (BuildContext context) => const ColorPickerDialog( )
                ).then((_color){
                  if( _color == null ) return;

                  Color setColor = _color as Color;

                  BackGroundColorChange _tmpColor = BackGroundColorChange(
                    widget.dbInstance, "", 
                    setColor, 
                    // TODO: asdf
                    verticalScrollController.position.pixels + MediaQuery.of(context).size.height*windowZoomSize()/2 - 150, 
                    300, 
                  );
                  _tmpColor.save();
                  focusBackGroundColorChange = _tmpColor;

                  backGroundColorChangeList.add( _tmpColor );

                  setState(() { });
                });

                
              }
            ),
            IconButton(
            icon    : const Icon(Icons.swap_horiz_outlined),
            tooltip : "左右反転",
            onPressed: (){

              for (FrameImage _frameImage in frameImageList) {
                _frameImage.position = Point(
                  (widget.project.canvasSize.width - (_frameImage.position.x + _frameImage.rotateSize.x * _frameImage.sizeRate)), 
                  _frameImage.position.y
                );
                _frameImage.save();
              }
              
              setState(() { });
            },
          ),
          IconButton(
            icon    : const Icon(Icons.photo_size_select_large),
            tooltip : "キャンパスのサイズ変更",
            onPressed: (){
              FocusScope.of(context).unfocus();
              canvasSizeXController.value = canvasSizeXController.value.copyWith( text: widget.project.canvasSize.width.toString() );
              canvasSizeYController.value = canvasSizeYController.value.copyWith( text: widget.project.canvasSize.height.toString() );

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

              CanvasToImage(frameImageList, widget.project.canvasSize).download(downloadController.text);
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

  FrameImage? draggingFrame;
  Point<double> initFramePosition     = const Point(0,0);
  Point<double> initDragFramePosition = const Point(0,0);
  Point<double> currentDragFramePosition = const Point(0,0);
  Widget gestureWidget(Widget _body){
    Point<double> dragGlobalToCanvasPos(Offset _globalPos){
      return Point<double>(
        globalToCanvasPos(Point<double>(_globalPos.dx, _globalPos.dy)).x, 
        globalToCanvasPos(Point<double>(_globalPos.dx, _globalPos.dy)).y - kToolbarHeight
      );
    }

    Point<double> stickyPosition(FrameImage frameImage, Point<double> diffPosition){
      Point<double> newFramePos =  initFramePosition + diffPosition;

      if( newFramePos.x.abs() < stricyArea ) newFramePos = Point(0, newFramePos.y);
      if( newFramePos.y.abs() < stricyArea ) newFramePos = Point(newFramePos.x, 0);

      Size frameWidth = Size( frameImage.rotateSize.x * frameImage.sizeRate, frameImage.rotateSize.y * frameImage.sizeRate);
      if( (widget.project.canvasSize.width  -  (newFramePos.x + frameWidth.width) ).abs() < stricyArea ) newFramePos = Point(widget.project.canvasSize.width - frameWidth.width, newFramePos.y);
      if( (widget.project.canvasSize.height -  (newFramePos.y + frameWidth.height)).abs() < stricyArea ) newFramePos = Point(newFramePos.x, widget.project.canvasSize.height - frameWidth.height, );

      return newFramePos;
    }

    FrameImage? targetFrameImage(Offset _tapPos){
      Point<double> canvasTapPos = dragGlobalToCanvasPos(_tapPos);

      for (FrameImage _frameImage in frameImageList) {
        if( canvasTapPos.x < _frameImage.position.x ) continue;
        if( canvasTapPos.y < _frameImage.position.y ) continue;

        if( _frameImage.position.x + _frameImage.rotateSize.x * _frameImage.sizeRate < canvasTapPos.x ) continue;
        if( _frameImage.position.y + _frameImage.rotateSize.y * _frameImage.sizeRate < canvasTapPos.y ) continue;

        return _frameImage;
      }

      return null;
    }

    return GestureDetector(
      child     : _body,
      onTapUp   : (TapUpDetails _tapUp){
        setState(() { });

        FrameImage? targetFrame = targetFrameImage(_tapUp.globalPosition);
        if( focusFrame == targetFrame || targetFrame == null){
          focusFrame = null;
          focusFrameDependList.clear();
          return;
        }
        focusFrame = targetFrame;
        showCanvasEdit = false;

        focusFrameDependList.clear();

        // ctrlを押しながらやると、従属して動く
        if(RawKeyboard.instance.keysPressed.where((_pressd) => _pressd.keyLabel == LogicalKeyboardKey.controlLeft.keyLabel).isNotEmpty){
          focusFrameDependList = frameImageList.where((_frame) => _frame.position.y > focusFrame!.position.y ).toList();
        }

        framePosXController.value = framePosXController.value.copyWith( text: focusFrame!.position.x.toString() );
        framePosYController.value = framePosYController.value.copyWith( text: focusFrame!.position.y.toString() );
        frameSizeRateController.value = frameSizeRateController.value.copyWith( text: focusFrame!.sizeRate.toString() );        
      },
      onPanStart: (DragStartDetails _dragStart){
        // diffPos = Offset.zero; 
        // showDiffPos = Offset.zero;
        draggingFrame = targetFrameImage(_dragStart.globalPosition);
        if( draggingFrame == null ) return;

        initFramePosition = draggingFrame!.position;
        initDragFramePosition  = dragGlobalToCanvasPos(_dragStart.globalPosition);

        focusFrameDependList.clear();
        if(RawKeyboard.instance.keysPressed.where((_pressd) => _pressd.keyLabel == LogicalKeyboardKey.controlLeft.keyLabel).isNotEmpty){
          focusFrameDependList = frameImageList.where((_frame) => _frame.position.y > draggingFrame!.position.y ).toList();
        }

        setState(() { });
      },
      onPanUpdate: (DragUpdateDetails _dragUpdate){
        if( draggingFrame == null ) return;

        // print( dragGlobalToCanvasPos(_dragUpdate.globalPosition) );
        currentDragFramePosition = dragGlobalToCanvasPos(_dragUpdate.globalPosition);

        draggingFrame!.position = stickyPosition( draggingFrame!, currentDragFramePosition - initDragFramePosition);

        setState(() { });

        // print( "pan update : " + _dragUpdate.globalPosition.toString());
      },
      onPanEnd: (DragEndDetails _dragEnd){
        if( draggingFrame == null ) return;

        Point<double> stickyDiffPos = stickyPosition( draggingFrame!, currentDragFramePosition - initDragFramePosition);
        
        draggingFrame!.position = stickyDiffPos;
        draggingFrame?.save();

        for (FrameImage _depandFrame in focusFrameDependList) {
          _depandFrame.position = Point(_depandFrame.position.x, _depandFrame.position.y + (draggingFrame!.position - initFramePosition).y);
          _depandFrame.save();
        }

        focusFrame = draggingFrame;
        framePosXController.value = framePosXController.value.copyWith( text: focusFrame!.position.x.toString() );
        framePosYController.value = framePosYController.value.copyWith( text: focusFrame!.position.y.toString() );
        frameSizeRateController.value = frameSizeRateController.value.copyWith( text: focusFrame!.sizeRate.toString() );

        draggingFrame = null;
        setState(() { });

        // print( "pan end ");
      },
    );

  }


  Widget shortCutsWidget(Widget _body){
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
    return KeyBoardShortcuts(
      keysToPressList: _shortCutKeyMap.keys.toList(),
      onKeysPressed: (int _shortCutIndex){
        if (!mounted)       return;
        if( ModalRoute.of(context) == null ) return;
        if( !ModalRoute.of(context)!.isCurrent ) return;

        String shortCutType = _shortCutKeyMap.values.toList()[_shortCutIndex];

        if(
          framePosXFocusNode.hasFocus || 
          framePosYFocusNode.hasFocus || 
          frameSizeRateFocusNode.hasFocus || 
          downloadFocusNode.hasFocus || 
          canvasSizeXFocusNode.hasFocus || 
          canvasSizeYFocusNode.hasFocus
        )  return;

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
          setState(() { });
        }
      },
      onKeysUp: (){
        if(
          framePosXFocusNode.hasFocus || 
          framePosYFocusNode.hasFocus || 
          frameSizeRateFocusNode.hasFocus || 
          downloadFocusNode.hasFocus || 
          canvasSizeXFocusNode.hasFocus || 
          canvasSizeYFocusNode.hasFocus
        )  return;

        if( focusFrame != null ){
          focusFrame?.save();
          framePosXController.value = framePosXController.value.copyWith( text: focusFrame!.position.x.toString() );
          framePosYController.value = framePosYController.value.copyWith( text: focusFrame!.position.y.toString() );
          frameSizeRateController.value = frameSizeRateController.value.copyWith( text: focusFrame!.sizeRate.toString() );
        }
      },
      child: _body
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
      left  : sideSpaceWidth() + widget.project.canvasSize.width - horizonScrollController.position.pixels + 20,
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
      left  : sideSpaceWidth() + widget.project.canvasSize.width - horizonScrollController.position.pixels + 20,
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
                child : Text("右端からの距離 : " + (widget.project.canvasSize.width - (focusFrame!.position.x + focusFrame!.size.x * focusFrame!.sizeRate)).toString() ),
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
    if( widget.project.canvasSize == Size.zero ) return false;
    return frameImageList.where((_frameImage) => _frameImage.byteData != null).isNotEmpty;
  }

  double sideSpaceWidth(){
    if( windowZoomSize() >= 1.0 ){
      Size realWindowSize = Size(
        MediaQuery.of(context).size.width*windowZoomSize(),
        MediaQuery.of(context).size.height*windowZoomSize(),
      );


      return math.max( (realWindowSize.width - widget.project.canvasSize.width)/2, 0);
    }

    return math.max( (MediaQuery.of(context).size.width - widget.project.canvasSize.width)/2, 0);
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
            height: widget.project.canvasSize.height,
          ),
          Container(
            width : widget.project.canvasSize.width,
            height: widget.project.canvasSize.height,
            color: Colors.white,
          ),
          Container(
            color: Colors.grey,
            width : sideSpaceWidth(),
            height: widget.project.canvasSize.height,
          ),
        ],
      ),
    );

    Point<double> _dragPointPos = Point(widget.project.canvasSize.width/2, widget.project.canvasSize.height);

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
            canvasSizeXController.value = canvasSizeXController.value.copyWith( text: widget.project.canvasSize.width.toString() );
            canvasSizeYController.value = canvasSizeYController.value.copyWith( text: widget.project.canvasSize.height.toString() );

            widget.project.save();
          },
          onDrag      : (dragPos) {
            Point<double> canvasDragPos = globalToCanvasPos(Point<double>(dragPos.dx, dragPos.dy));
            widget.project.canvasSize = Size(widget.project.canvasSize.width, canvasDragPos.y);
            setState(() { });
          },
        ),
      ),
    ];
  }

  Widget _backGroundBody(){
    if( !isImageLoaded() ) return Container();

    List<double> bottomList = [widget.project.canvasSize.height];
    for (FrameImage _frameImage in frameImageList) {
      bottomList.add( _frameImage.position.y + _frameImage.rotateSize.y * _frameImage.sizeRate );
    }

    return Container(
      width : MediaQuery.of(context).size.width,
      height: bottomList.reduce(math.max) + MediaQuery.of(context).size.height*3/4,
      color: Colors.transparent,
    );
  }  

  // TODO: asdf
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
            left  : canvasToGlobalPos(const Point(0,0)).x,
            top   : canvasToGlobalPos(const Point(0,0)).y,
            child : Container(
              color : Colors.white,
              height: backGroundColorChangeList.first.pos + offsetSize,
              width : widget.project.canvasSize.width,
            )
          )
        );
      }

      // 一番後ろグラデーション以降の色埋め
      showWidgetList.add(
        Positioned(
          left  : canvasToGlobalPos(Point(0, backGroundColorChangeList.last.pos + backGroundColorChangeList.last.size)).x,
          top   : canvasToGlobalPos(Point(0, backGroundColorChangeList.last.pos + backGroundColorChangeList.last.size - offsetSize)).y,
          child : Container(
            color : backGroundColorChangeList.last.targetColor,
            height: widget.project.canvasSize.height - (backGroundColorChangeList.last.pos + backGroundColorChangeList.last.size) + offsetSize,
            width : widget.project.canvasSize.width,
          )
        )
      );
    }

    // グラデーション間の穴埋め
    for (BackGroundColorChange _background in backGroundColorChangeList) {
      int backGroundIndex = backGroundColorChangeList.indexOf(_background);
      if( backGroundIndex == 0 ) continue;
      
      BackGroundColorChange preBackGround = backGroundColorChangeList[backGroundIndex-1];

      showWidgetList.add(
        Positioned(
          left  : canvasToGlobalPos(Point(0, preBackGround.pos + preBackGround.size)).x,
          top   : canvasToGlobalPos(Point(0, preBackGround.pos + preBackGround.size - offsetSize)).y,
          child : Container(
            color : backGroundColorChangeList[backGroundIndex-1].targetColor,
            height: _background.pos - (preBackGround.pos + preBackGround.size) + offsetSize*2,
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
          left  : canvasToGlobalPos(Point(0,_background.pos)).x,
          top   : canvasToGlobalPos(Point(0,_background.pos)).y,
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

  List<Widget> _frameBodyList(){
    List<Widget> showWidgetList = [];

    for (FrameImage _frameData in frameImageList) {
      if( _frameData.byteData == null ) continue;
      if( _frameData.sizeRate <= 0.0 ) continue;

      showWidgetList.addAll(_frameWidgetList(_frameData));
    }

    if(showWidgetList.isEmpty) return [];

    return showWidgetList;
  }

  // コマの表示（大きさ変えるための、角に四角配置

  Point<double> dragStartLeftTopPos = const Point(0,0);
  Point<double> dragStartRightBottomPos = const Point(0,0);
  List<Widget> _frameWidgetList(FrameImage _frameData){
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


    if( draggingFrame != null ){
      if( draggingFrame == _frameData ) return [ _frameColorWidget(Colors.blue), _frameDraggingWidget(_frameData) ];
      return [ _frameDraggingWidget(_frameData) ];
    }

    void tempSavePos(){
      dragStartLeftTopPos     = _frameData.position;
      dragStartRightBottomPos = Point(
        _frameData.position.x + _frameData.rotateSize.x * _frameData.sizeRate,
        _frameData.position.y + _frameData.rotateSize.y * _frameData.sizeRate,
      );

      if(RawKeyboard.instance.keysPressed.where((_pressd) => _pressd.keyLabel == LogicalKeyboardKey.controlLeft.keyLabel).isNotEmpty){
        focusFrameDependList = frameImageList.where((_frame) => _frame.position.y > _frameData.position.y ).toList();
      }
    }

    void saveAfterDrag(){
      _frameData.save();
      if( focusFrame != null){
        framePosXController.value = framePosXController.value.copyWith( text: focusFrame!.position.x.toString() );
        framePosYController.value = framePosYController.value.copyWith( text: focusFrame!.position.y.toString() );
        frameSizeRateController.value = frameSizeRateController.value.copyWith( text: focusFrame!.sizeRate.toString() );
      }

      for (FrameImage _depandFrame in focusFrameDependList) { _depandFrame.save(); }
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
          onDragEnd   : (){ saveAfterDrag(); },
          onDrag      : (dragPos) {
            Point<double> canvasDragPos = globalToCanvasPos(Point<double>(dragPos.dx, dragPos.dy));

            // sticy対応で仮計算する
            double tempSizeRate = math.max(
              (canvasDragPos.x - dragStartRightBottomPos.x).abs()/_frameData.rotateSize.x, 
              (canvasDragPos.y - dragStartRightBottomPos.y).abs()/_frameData.rotateSize.y, 
            );
            Point<double> newLeftTopPos = Point(
              dragStartRightBottomPos.x - _frameData.rotateSize.x * tempSizeRate,
              dragStartRightBottomPos.y - _frameData.rotateSize.y * tempSizeRate,
            );
            if( newLeftTopPos.x.abs() < stricyArea) newLeftTopPos = Point(0, newLeftTopPos.y);
            if( newLeftTopPos.y.abs() < stricyArea) newLeftTopPos = Point(newLeftTopPos.x, 0);

            _frameData.sizeRate = math.max(
              (newLeftTopPos.x - dragStartRightBottomPos.x).abs()/_frameData.rotateSize.x, 
              (newLeftTopPos.y - dragStartRightBottomPos.y).abs()/_frameData.rotateSize.y, 
            );
            _frameData.position = Point(
              dragStartRightBottomPos.x - _frameData.rotateSize.x * _frameData.sizeRate,
              dragStartRightBottomPos.y - _frameData.rotateSize.y * _frameData.sizeRate,
            );

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
          onDragEnd   : (){ saveAfterDrag(); },
          onDrag      : (dragPos) {
            Point<double> canvasDragPos = globalToCanvasPos(Point<double>(dragPos.dx, dragPos.dy));

            // sticy対応で仮計算する
            double tempSizeRate = math.max(
              (canvasDragPos.x - dragStartLeftTopPos.x).abs()/_frameData.rotateSize.x, 
              (canvasDragPos.y - dragStartRightBottomPos.y).abs()/_frameData.rotateSize.y, 
            );
            Point<double> newRightTopPos = Point(
              dragStartLeftTopPos.x     + _frameData.rotateSize.x * tempSizeRate,
              dragStartRightBottomPos.y - _frameData.rotateSize.y * tempSizeRate,
            );

            if( (widget.project.canvasSize.width - newRightTopPos.x).abs() < stricyArea) newRightTopPos = Point(widget.project.canvasSize.width, newRightTopPos.y);
            if( newRightTopPos.y.abs() < stricyArea) newRightTopPos = Point(newRightTopPos.x, 0);

            _frameData.sizeRate = math.max(
              (newRightTopPos.x - dragStartLeftTopPos.x).abs()/_frameData.rotateSize.x, 
              (newRightTopPos.y - dragStartRightBottomPos.y).abs()/_frameData.rotateSize.y, 
            );
            _frameData.position = Point(
              _frameData.position.x,
              dragStartRightBottomPos.y - _frameData.rotateSize.y * _frameData.sizeRate,
            );

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
          onDragEnd   : (){ saveAfterDrag(); },
          onDrag      : (dragPos) {
            Point<double> canvasDragPos = globalToCanvasPos(Point<double>(dragPos.dx, dragPos.dy));

            // sticy対応で仮計算する
            double tempSizeRate = math.max(
              (canvasDragPos.x - dragStartRightBottomPos.x).abs()/_frameData.rotateSize.x, 
              (canvasDragPos.y - dragStartLeftTopPos.y).abs()/_frameData.rotateSize.y, 
            );
            Point<double> newLeftBottomPoint = Point(
              dragStartRightBottomPos.x - _frameData.rotateSize.x * tempSizeRate,
              dragStartLeftTopPos.y     + _frameData.rotateSize.y * tempSizeRate,
            );

            if( newLeftBottomPoint.x.abs() < stricyArea) newLeftBottomPoint = Point(0, newLeftBottomPoint.y);
            if( (widget.project.canvasSize.height - newLeftBottomPoint.y).abs() < stricyArea) newLeftBottomPoint = Point(newLeftBottomPoint.x, widget.project.canvasSize.height);

            // 反映
            Point<double> prePos = _frameData.position;
            double preSizeRate = _frameData.sizeRate;

            _frameData.sizeRate = math.max(
              (newLeftBottomPoint.x - dragStartRightBottomPos.x).abs()/_frameData.rotateSize.x, 
              (newLeftBottomPoint.y - dragStartLeftTopPos.y).abs()/_frameData.rotateSize.y, 
            );
            _frameData.position = Point(
              dragStartRightBottomPos.x - _frameData.rotateSize.x * _frameData.sizeRate,
              _frameData.position.y,
            );

            double prePosY = prePos.y + _frameData.rotateSize.y * preSizeRate;
            double newPosY = _frameData.position.y + _frameData.rotateSize.y * _frameData.sizeRate;
            double diffY = prePosY - newPosY;

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
          onDragEnd   : (){ saveAfterDrag(); },
          onDrag      : (dragPos) {
            Point<double> canvasDragPos = globalToCanvasPos(Point<double>(dragPos.dx, dragPos.dy));

            // sticy対応で仮計算する
            double tempSizeRate = math.max(
              (canvasDragPos.x - dragStartLeftTopPos.x).abs()/_frameData.rotateSize.x, 
              (canvasDragPos.y - dragStartLeftTopPos.y).abs()/_frameData.rotateSize.y, 
            );
            Point<double> newRightBottomPoint = Point(
              dragStartLeftTopPos.x + _frameData.rotateSize.x * tempSizeRate,
              dragStartLeftTopPos.y + _frameData.rotateSize.y * tempSizeRate,
            );

            if( (widget.project.canvasSize.width  - newRightBottomPoint.x).abs() < stricyArea) newRightBottomPoint = Point(widget.project.canvasSize.width, newRightBottomPoint.y);
            if( (widget.project.canvasSize.height - newRightBottomPoint.y).abs() < stricyArea) newRightBottomPoint = Point(newRightBottomPoint.x, widget.project.canvasSize.height);

            // 反映
            Point<double> prePos = _frameData.position;
            double preSizeRate = _frameData.sizeRate;

            _frameData.sizeRate = math.max(
              (newRightBottomPoint.x - dragStartLeftTopPos.x).abs()/_frameData.rotateSize.x, 
              (newRightBottomPoint.y - dragStartLeftTopPos.y).abs()/_frameData.rotateSize.y, 
            );

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


    // focusしているときは、青い四角い枠をつける
    if( focusFrame == _frameData) _frameWidgetList.insert(0, _frameColorWidget(Colors.blue) );

    // 従属しているときは、赤い四角い枠をつける
    if( focusFrameDependList.contains(_frameData)) _frameWidgetList.insert(0, _frameColorWidget(Colors.grey) );

    return _frameWidgetList;
  }

  // コマの表示
  Widget _frameDraggingWidget(FrameImage _frameData){
    Widget dragging = MouseRegion(
      cursor  : SystemMouseCursors.click,
      child   : RotatedBox(
        quarterTurns: _frameData.angle,
        child : Opacity(
          opacity: _frameData == draggingFrame ? 0.5 : 1.0,
          child: Image.memory(
            _frameData.byteData!, 
            width: _frameData.size.x * _frameData.sizeRate, 
            // height: _frameData.size.y,
            fit: BoxFit.fitWidth, 
            filterQuality: FilterQuality.high,
          )
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
        allowedExtensions : frameImageList.isEmpty ? ['png', 'json'] : ['png' ],
      );

      if(result == null) return;
      
      // TODO: asdf
      backGroundColorChangeList.addAll([
        BackGroundColorChange(widget.dbInstance, "asdfasdf", Colors.black, 200, 200, ),
        // BackGroundColorChange(widget.dbInstance, "asdfasdf", Colors.blue, 1200, 400, ),
      ]);

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
          frameImage.size = Point(_image.width.toDouble(), _image.height.toDouble());
        } catch(e){
          FrameImage newImage = FrameImage(
            dbInstance  : widget.dbInstance,
            project     : widget.project,
            dbIndex     : "",
            byteData    : _file.bytes, 
            name        : _file.name,
            angle       : 0,
            sizeRate    : 1.0,
            position    : const Point<double>(0,0),
            size        : Point(_image.width.toDouble(), _image.height.toDouble())
          );
          newImage.save();

          frameImageList.add( newImage );
        }
      });
      
      setState(() { });

      // 設定読み込み
      for (PlatformFile _file in result.files.where((_file) => _file.extension != null && _file.extension == "json").toList()) {
        if(_file.bytes == null) continue;

        // map作成
        Map<int, Map<int, Map<String, int>>> frameStepMap = {};

        List<dynamic> jsonData = json.decode(utf8.decode(_file.bytes!)); 
        // List<List<Map<String, dynamic>>> jsonData = json.decode(utf8.decode(_file.bytes!)); 
        // print( jsonData );
        jsonData.asMap().forEach((_pageIndex, _pageValueJson) {
          if( !frameStepMap.containsKey(_pageIndex) ) frameStepMap[_pageIndex] = {};

          List<dynamic> _pageJson  = _pageValueJson as List<dynamic>;

          // print( "frameNum in Page : $_pageIndex" );
          _pageJson.asMap().forEach((_frameIndex, _frameValuejson) {
            Map<String, dynamic> _framejson  = _frameValuejson as Map<String, dynamic>;
            int frameNum = _framejson["FrameNumber"];
            if( !frameStepMap[_pageIndex]!.containsKey(frameNum) ) frameStepMap[_pageIndex]![frameNum] = {};

            // {SpeakBlockList: [], CornerPoints: [{X: 0, Y: 0}, {X: 502, Y: 0}, {X: 505, Y: 259}, {X: 0, Y: 259}], FrameNumber: 0, StepData: {X: 0, Y: 0, StepNum: 0}}
            // print(_framejson);

            frameStepMap[_pageIndex]![frameNum] = {
              "x" :_framejson["StepData"]["X"],
              "y" :_framejson["StepData"]["Y"],
              "step" :_framejson["StepData"]["StepNum"],
            };

            setState(() { });

          });
        });

        /*
        {
          0: {
            0: {x: 0, y: 0, step: 0}, 
            1: {x: 0, y: 0, step: 1}, 
            2: {x: 0, y: 0, step: 2}, 
            3: {x: 1, y: 0, step: 2}, 
            4: {x: 2, y: 0, step: 2}
          }, 
          1: {
            0: {x: 0, y: 0, step: 0}, 
            1: {x: 0, y: 0, step: 1}, 
            2: {x: 1, y: 0, step: 1}, 
            3: {x: 0, y: 0, step: 2}, 
            4: {x: 1, y: 0, step: 2}, 
            5: {x: 2, y: 0, step: 2}
          }
        }
        */

        // comico設定　https://tips.clip-studio.com/ja-jp/articles/2781#:~:text=%E8%A7%A3%E5%83%8F%E5%BA%A6%E3%81%AF%E5%8D%B0%E5%88%B7%E3%81%AE%E9%9A%9B,%E3%81%99%E3%82%8B%E3%81%93%E3%81%A8%E3%81%8C%E5%A4%9A%E3%81%84%E3%81%A7%E3%81%99%E3%80%82
        const double defaultCanvasWidth = 690;

        double currentHeight = 0;
        frameStepMap.forEach((_pageIndex, _frameMap) {
          _frameMap.forEach((_frameIndex, _frameStepData) {
            String _imageTitle(){
              int pageNumCutLength = frameStepMap.length >= 100 ? -3:-2;
              String fullPageNum = '00000' + (_pageIndex+1).toString();
              String cutPageNum  = fullPageNum.substring(fullPageNum.length+pageNumCutLength);

              int frameNumCutLength = _frameMap.length >= 100 ? -3:-2;
              String fullFrameNum = '00000' + (_frameIndex+1).toString();
              String cutFrameNum  = fullFrameNum.substring(fullFrameNum.length+frameNumCutLength);

              return cutPageNum + "p_" + cutFrameNum + ".png";
            }

            // すでにwebに設定済みのデータがある（読み込み済み）なら、なにもせずに終了
            int targetFrameIndex = frameImageList.indexWhere((_frameImage) => _frameImage.name == _imageTitle());
            if( targetFrameIndex < 0 ) return;

            FrameImage targetFrame = frameImageList[targetFrameIndex];

            // TODO: 配置に関してはこいつを良い感じにする
            Point<double> calcPos(){
              // ignore: prefer_const_constructors
              if( currentHeight == 0 ) return Point(0,0);

              // ignore: prefer_const_constructors
              return Point(0, currentHeight + 100);
            }
            targetFrame.position = calcPos();

            // 枠を超えていた場合は、rateで枠内に収まるようにする
            if( targetFrame.rotateSize.x > defaultCanvasWidth ) targetFrame.sizeRate = targetFrame.rotateSize.x/defaultCanvasWidth;

            targetFrame.save();

            currentHeight = targetFrame.position.y + targetFrame.rotateSize.y * targetFrame.sizeRate;
          });
        });

        widget.project.canvasSize = Size(defaultCanvasWidth, currentHeight + 100);
        canvasSizeXController.value = canvasSizeXController.value.copyWith( text: widget.project.canvasSize.width.toString() );
        canvasSizeYController.value = canvasSizeYController.value.copyWith( text: widget.project.canvasSize.height.toString() );

        widget.project.save();
        setState(() { });

        //  ないなら、ファイルを作って保存処理＋自然配置
        continue;
      }
    });
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