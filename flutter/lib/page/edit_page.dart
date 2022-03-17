// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:async';
import 'dart:typed_data';

import 'package:adaptive_scrollbar/adaptive_scrollbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
import 'package:tateyomi_gigarizer/dialog/text_input_dialog.dart';
import 'package:tateyomi_gigarizer/model/background_color_change.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';
import 'package:tateyomi_gigarizer/model/keyboard.dart';
import 'package:tateyomi_gigarizer/model/project.dart';
import 'package:tateyomi_gigarizer/page/parts/background_color_detail_box.dart';
import 'package:tateyomi_gigarizer/page/parts/canvas_detail_box.dart';
import 'package:tateyomi_gigarizer/page/parts/corner_ball.dart';
import 'package:tateyomi_gigarizer/dialog/shortcuts_info_dialog.dart';
import 'dart:ui' as ui;
import 'package:universal_html/html.dart' as html;
import 'dart:math' as math;
import 'dart:convert';

import 'parts/frame_detail_box.dart';

// TODO: asdf
//  frameの削除
//  削除されていた時の処理

// TODO: 重なってた時の処理

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
  bool showCanvasEdit = false;
  List<FrameImage> focusFrameDependList = [];

  final GlobalKey<FrameDetailWidgetState> _frameDetailKey = GlobalKey<FrameDetailWidgetState>();
  final GlobalKey<CanvasDetailWidgetState> _canvasDetailKey = GlobalKey<CanvasDetailWidgetState>();
  final GlobalKey<BackGroundColorDetailWidgetState> _backgroundColorDetailKey = GlobalKey<BackGroundColorDetailWidgetState>();
  

  final ScrollController verticalScrollController = ScrollController();
  final ScrollController horizonScrollController  = ScrollController();

  double stricyArea = 10;

  List<dynamic> historyLog  = [];
  List<dynamic> futureLog   = [];

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
    verticalScrollController.addListener(() { setState(() { }); });
    horizonScrollController.addListener(() { setState(() { }); });
  }

  @override
  void dispose(){
    verticalScrollController.dispose();
    horizonScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> showWidgetList = [_backGroundBody(), ..._canvasBody(), ..._backGroundWidgetList(), ..._frameBodyList(), ..._focusBackGroundWidgetList()];

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
        canvasSizeSettingBox(),
        focusBackGroundDetailSettingBox(),
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
        title   : Row(children: [
          Text( "編集ページ ： " + widget.project.name ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip : "名前の変更",
            onPressed: (){
              showDialog( 
                context: context, 
                builder: (BuildContext context) => TextInputDialog( widget.project.name )
              ).then((_text){
                if( _text == null ) return;
                String _fixText = _text as String;
                if( _fixText.isEmpty ) return;

                setState(() { });
                widget.project.name = _fixText;
                widget.project.save();
              });
            }
          ),
          
        ]),
        actions : !isImageLoaded() ? [] : [
            IconButton(
              icon    : const Icon(Icons.gradient),
              tooltip : "背景の追加",
              onPressed: (){
                BackGroundColorChange _tmpColor = BackGroundColorChange(
                  widget.dbInstance, widget.project, "", 
                  Colors.black, 
                  verticalScrollController.position.pixels + MediaQuery.of(context).size.height*windowZoomSize()/2 - 50, 
                  100, 
                );
                _tmpColor.save();

                setFocusBackGround(_tmpColor);
                backGroundColorChangeList.add( _tmpColor );

                setState(() { });
              }
            ),
            IconButton(
            icon    : const Icon(Icons.swap_horiz_outlined),
            tooltip : "左右反転",
            onPressed: (){

              for (FrameImage _frameImage in frameImageList) {
                _frameImage.position = math.Point(
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
              _canvasDetailKey.currentState?.updateTextField();

              setCanvasEdit(true);
              setState(() { });
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

  void setFocusFrame(FrameImage? targetFrameImage){
    focusFrame = targetFrameImage;
    if( focusFrame == null ) focusFrameDependList.clear();
    
    if( focusBackGroundColorChange != null ) focusBackGroundColorChange?.save();
    focusBackGroundColorChange = null;
    showCanvasEdit = false;
    setState(() { });
  }

  void setFocusBackGround(BackGroundColorChange? targetBackgroundColor){
    if( focusBackGroundColorChange != null ) focusBackGroundColorChange?.save();
    focusBackGroundColorChange = targetBackgroundColor;

    focusFrame = null;
    focusFrameDependList.clear();
    showCanvasEdit = false;
    setState(() { });
  }  

  void setCanvasEdit(bool status){
    showCanvasEdit = status;
    focusFrame = null;
    focusFrameDependList.clear();

    if( focusBackGroundColorChange != null ) focusBackGroundColorChange?.save();
    focusBackGroundColorChange = null;

    setState(() { });
  }


  FrameImage? draggingFrame;
  BackGroundColorChange? draggingBackGroundColorChange;
  math.Point<double> initDragPosition     = const math.Point(0,0);
  math.Point<double> initDragFramePosition = const math.Point(0,0);
  math.Point<double> currentDragFramePosition = const math.Point(0,0);
  Widget gestureWidget(Widget _body){
    math.Point<double> dragGlobalToCanvasPos(Offset _globalPos){
      return math.Point<double>(
        globalToCanvasPos(math.Point<double>(_globalPos.dx, _globalPos.dy)).x, 
        globalToCanvasPos(math.Point<double>(_globalPos.dx, _globalPos.dy)).y - kToolbarHeight
      );
    }

    math.Point<double> stickyPosition(FrameImage frameImage, math.Point<double> diffPosition){
      math.Point<double> newFramePos =  initDragPosition + diffPosition;

      if( newFramePos.x.abs() < stricyArea ) newFramePos = math.Point(0, newFramePos.y);
      if( newFramePos.y.abs() < stricyArea ) newFramePos = math.Point(newFramePos.x, 0);

      Size frameWidth = Size( frameImage.rotateSize.x * frameImage.sizeRate, frameImage.rotateSize.y * frameImage.sizeRate);
      if( (widget.project.canvasSize.width  -  (newFramePos.x + frameWidth.width) ).abs() < stricyArea ) newFramePos = math.Point(widget.project.canvasSize.width - frameWidth.width, newFramePos.y);
      if( (widget.project.canvasSize.height -  (newFramePos.y + frameWidth.height)).abs() < stricyArea ) newFramePos = math.Point(newFramePos.x, widget.project.canvasSize.height - frameWidth.height, );

      return newFramePos;
    }

    FrameImage? targetFrameImage(Offset _tapPos){
      math.Point<double> canvasTapPos = dragGlobalToCanvasPos(_tapPos);

      for (FrameImage _frameImage in frameImageList) {
        if( canvasTapPos.x < _frameImage.position.x ) continue;
        if( canvasTapPos.y < _frameImage.position.y ) continue;

        if( _frameImage.position.x + _frameImage.rotateSize.x * _frameImage.sizeRate < canvasTapPos.x ) continue;
        if( _frameImage.position.y + _frameImage.rotateSize.y * _frameImage.sizeRate < canvasTapPos.y ) continue;

        return _frameImage;
      }

      return null;
    }

    BackGroundColorChange? targetBackGroundColor(Offset _tapPos){
      math.Point<double> canvasTapPos = dragGlobalToCanvasPos(_tapPos);

      for (BackGroundColorChange _backGroundColor in backGroundColorChangeList) {
        if( canvasTapPos.y < _backGroundColor.pos ) continue;
        if( canvasTapPos.x < 0 ) continue;
        if( _backGroundColor.pos +_backGroundColor.size < canvasTapPos.y ) continue;
        if( widget.project.canvasSize.width < canvasTapPos.x ) continue;

        return _backGroundColor;
      }

      return null;
    }

    return GestureDetector(
      child     : _body,
      onTapUp   : (TapUpDetails _tapUp){
        setState(() { });

        FrameImage? targetFrame = targetFrameImage(_tapUp.globalPosition);
        void frameFunc(){
          if(targetFrame != null) focusBackGroundColorChange = null;

          if( focusFrame == targetFrame || targetFrame == null){
            setFocusFrame(null);
            focusFrameDependList.clear();
            return;
          }
          setFocusFrame(targetFrame);
          focusFrameDependList.clear();

          // ctrlを押しながらやると、従属して動く
          if(RawKeyboard.instance.keysPressed.where((_pressd) => _pressd.keyLabel == LogicalKeyboardKey.controlLeft.keyLabel).isNotEmpty){
            focusFrameDependList = frameImageList.where((_frame) => _frame.position.y > focusFrame!.position.y ).toList();
          }

          _frameDetailKey.currentState?.updateTextField();

          return;
        }
        frameFunc();

        if(targetFrame != null) return;

        void backgroundFunc(){
          BackGroundColorChange? targetBackGround = targetBackGroundColor(_tapUp.globalPosition);
          if( focusBackGroundColorChange == targetBackGround || targetBackGround == null){
            setFocusBackGround(null);
            return;
          }

          setFocusBackGround(targetBackGround);
        }

        backgroundFunc();
      },
      onPanStart: (DragStartDetails _dragStart){
        setState(() { });
        initDragFramePosition  = dragGlobalToCanvasPos(_dragStart.globalPosition);
        draggingBackGroundColorChange = null;
        draggingFrame = null;

        draggingFrame = targetFrameImage(_dragStart.globalPosition);
        if( draggingFrame != null ){
          initDragPosition = draggingFrame!.position;
          focusFrameDependList.clear();
          if(RawKeyboard.instance.keysPressed.where((_pressd) => _pressd.keyLabel == LogicalKeyboardKey.controlLeft.keyLabel).isNotEmpty){
            focusFrameDependList = frameImageList.where((_frame) => _frame.position.y > draggingFrame!.position.y ).toList();
          }

          List<FrameImage> forHistoryList = [];
          for( FrameImage _focusFrame in focusFrameDependList){ forHistoryList.add(_focusFrame.clone()); }
          forHistoryList.add( draggingFrame!.clone() );
          addHistory(forHistoryList);
          return;
        }

        draggingBackGroundColorChange = targetBackGroundColor(_dragStart.globalPosition);
        if( draggingBackGroundColorChange != null ){
          setFocusBackGround(draggingBackGroundColorChange);
          initDragPosition = math.Point(0, draggingBackGroundColorChange!.pos);

          addHistory(draggingBackGroundColorChange!.clone());
        }

      },
      onPanUpdate: (DragUpdateDetails _dragUpdate){
        setState(() { });

        currentDragFramePosition = dragGlobalToCanvasPos(_dragUpdate.globalPosition);

        void _draggingFrame(){
          if( draggingFrame == null ) return;
          draggingFrame!.position = stickyPosition( draggingFrame!, currentDragFramePosition - initDragFramePosition);
        }
        _draggingFrame();

        void _draggingBackGround(){
          if( draggingBackGroundColorChange == null ) return;
          draggingBackGroundColorChange!.pos =  initDragPosition.y + (currentDragFramePosition - initDragFramePosition).y;
        }
        _draggingBackGround();
      },
      onPanEnd: (DragEndDetails _dragEnd){
        setState(() { });

        void dragFrame(){
          if( draggingFrame == null ) return;

          math.Point<double> stickyDiffPos = stickyPosition( draggingFrame!, currentDragFramePosition - initDragFramePosition);
          
          draggingFrame!.position = stickyDiffPos;
          draggingFrame?.save();

          for (FrameImage _depandFrame in focusFrameDependList) {
            _depandFrame.position = math.Point(_depandFrame.position.x, _depandFrame.position.y + (draggingFrame!.position - initDragPosition).y);
            _depandFrame.save();
          }

          setFocusFrame(draggingFrame);
          _frameDetailKey.currentState?.updateTextField();

          draggingFrame = null;
        }

        dragFrame();

        void _draggingBackGround(){
          if( draggingBackGroundColorChange == null ) return;
          draggingBackGroundColorChange?.save();

          draggingBackGroundColorChange = null;
        }
        _draggingBackGround();
      },
    );

  }


  bool startPress = false;
  Widget shortCutsWidget(Widget _body){
    const String TYPE_SHORTCUT_UP     = "up";
    const String TYPE_SHORTCUT_LEFT   = "left";
    const String TYPE_SHORTCUT_DOWN   = "down";
    const String TYPE_SHORTCUT_RIGHT  = "right";
    const String TYPE_SHORTCUT_HISTORY_BACK = "historyBack";
    const String TYPE_SHORTCUT_HISTORY_FRONT = "historyFront";
    Map<Set<LogicalKeyboardKey>, String> _shortCutKeyMap = {
      {LogicalKeyboardKey.keyW}       : TYPE_SHORTCUT_UP,
      {LogicalKeyboardKey.keyA}       : TYPE_SHORTCUT_LEFT,
      {LogicalKeyboardKey.keyS}       : TYPE_SHORTCUT_DOWN,
      {LogicalKeyboardKey.keyD}       : TYPE_SHORTCUT_RIGHT,
      {LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyZ}       : TYPE_SHORTCUT_HISTORY_BACK,
      {LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.keyZ}       : TYPE_SHORTCUT_HISTORY_FRONT,
      {LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyY}       : TYPE_SHORTCUT_HISTORY_FRONT,
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
          (_frameDetailKey.currentState?.isFocus()  ?? false) || 
          (_canvasDetailKey.currentState?.isFocus() ?? false) || 
          (_backgroundColorDetailKey.currentState?.isFocus() ?? false)
        )  return;

        setState(() { });

        // TODO: 削除対応
        if( shortCutType == TYPE_SHORTCUT_HISTORY_BACK ){
          if( historyLog.isEmpty) return;

          dynamic historyData = historyLog.last;
          if( historyData is Project ){
            futureLog.add(widget.project.clone());
            widget.project.copy(historyData);
            widget.project.save();
          }
          if( historyData is FrameImage ){
            FrameImage currentFrame = frameImageList.singleWhere((_frame) => _frame.dbIndex == historyData.dbIndex);
            futureLog.add(currentFrame.clone());
            currentFrame.copy(historyData);
            currentFrame.save();
          }
          if( historyData is List<FrameImage> ){
            List<FrameImage> forFutureList = [];
            for (FrameImage _historyFrame in historyData) {
              FrameImage currentFrame = frameImageList.singleWhere((_frame) => _frame.dbIndex == _historyFrame.dbIndex);
              forFutureList.add(currentFrame.clone());
              currentFrame.copy(_historyFrame);
              currentFrame.save();
            }

            futureLog.add(forFutureList);
          }
          
          if( historyData is BackGroundColorChange ){
            BackGroundColorChange currentBackColor = backGroundColorChangeList.singleWhere((_frame) => _frame.dbIndex == historyData.dbIndex);
            futureLog.add(currentBackColor.clone());
            currentBackColor.copy(historyData);
            currentBackColor.save();
          }

          historyLog.removeLast();
        }

        if( shortCutType == TYPE_SHORTCUT_HISTORY_FRONT ){
          if( futureLog.isEmpty) return;

          dynamic futureData = futureLog.last;
          if( futureData is Project ){
            widget.project.copy(futureData);
            widget.project.save();
          }
          if( futureData is FrameImage ){
            FrameImage currentFrame = frameImageList.singleWhere((_frame) => _frame.dbIndex == futureData.dbIndex);
            currentFrame.copy(futureData);
            currentFrame.save();
          }
          if( futureData is List<FrameImage> ){
            for (FrameImage _historyFrame in futureData) {
              FrameImage currentFrame = frameImageList.singleWhere((_frame) => _frame.dbIndex == _historyFrame.dbIndex);
              currentFrame.copy(_historyFrame);
              currentFrame.save();
            }
          }

          if( futureData is BackGroundColorChange ){
            BackGroundColorChange currentBackColor = backGroundColorChangeList.singleWhere((_frame) => _frame.dbIndex == futureData.dbIndex);
            currentBackColor.copy(futureData);
            currentBackColor.save();
          }

          historyLog.add(futureData);
          futureLog.removeLast();
        }        

        if( focusFrame != null ){

          if( 
            shortCutType == TYPE_SHORTCUT_UP    ||
            shortCutType == TYPE_SHORTCUT_DOWN    ||
            shortCutType == TYPE_SHORTCUT_LEFT    ||
            shortCutType == TYPE_SHORTCUT_RIGHT    
          ){
            if( !startPress ) addHistory(focusFrame!.clone());
            startPress = true;
          }

          double moveSize = 0.1;
          if( shortCutType == TYPE_SHORTCUT_UP    ){
            focusFrame!.position = math.Point(focusFrame!.position.x, focusFrame!.position.y-moveSize);
            for (FrameImage _depandFrame in focusFrameDependList) {
              _depandFrame.position = math.Point(_depandFrame.position.x, _depandFrame.position.y-moveSize);
            }
          }
          if( shortCutType == TYPE_SHORTCUT_DOWN  ){
            focusFrame!.position = math.Point(focusFrame!.position.x, focusFrame!.position.y+moveSize);
            for (FrameImage _depandFrame in focusFrameDependList) {
              _depandFrame.position = math.Point(_depandFrame.position.x, _depandFrame.position.y+moveSize);
            }
          }

          if( shortCutType == TYPE_SHORTCUT_LEFT  ) focusFrame!.position = math.Point(focusFrame!.position.x-moveSize  , focusFrame!.position.y);
          if( shortCutType == TYPE_SHORTCUT_RIGHT ) focusFrame!.position = math.Point(focusFrame!.position.x+moveSize  , focusFrame!.position.y);
        }
      },
      onKeysUp: (){
        startPress = false;
        if( ModalRoute.of(context) == null ) return;
        if( !ModalRoute.of(context)!.isCurrent ) return;

        if(
          (_frameDetailKey.currentState?.isFocus() ?? false) || 
          (_canvasDetailKey.currentState?.isFocus() ?? false) || 
          (_backgroundColorDetailKey.currentState?.isFocus() ?? false)
        )  return;

        if( focusFrame != null ){
          focusFrame?.save();
          _frameDetailKey.currentState?.updateTextField();
        }
      },
      child: _body
    );
  }




  /* -----  設定周り ----- */

  Widget canvasSizeSettingBox(){
    if(!showCanvasEdit) return Container();

    return Positioned(
      top   : 20,
      left  : sideSpaceWidth() + widget.project.canvasSize.width - horizonScrollController.position.pixels + 20,
      child : CanvasDetailWidget(
        key             : _canvasDetailKey,
        project         : widget.project,
        frameImageList  : frameImageList,
        mainBuild       : (){ setState(() { });},
      ),
    );

  }

  Widget focusDetailSettingBox(){
    if(focusFrame == null ) return Container();

    return Positioned(
      top   : 20,
      left  : sideSpaceWidth() + widget.project.canvasSize.width - horizonScrollController.position.pixels + 20,
      child : FrameDetailWidget(
        key       : _frameDetailKey,
        project   : widget.project,
        focusFrame: focusFrame!,
        focusFrameDependList: focusFrameDependList,
        mainBuild: (){ setState(() { });},
      )
    );
  }


  Widget focusBackGroundDetailSettingBox(){
    if(focusBackGroundColorChange == null ) return Container();

    return Positioned(
      top   : 20,
      left  : sideSpaceWidth() + widget.project.canvasSize.width - horizonScrollController.position.pixels + 20,
      child: BackGroundColorDetailWidget(
        backGroundColorChange: focusBackGroundColorChange!,
        backGroundColorChangeList: backGroundColorChangeList,
        mainBuild: (){ setState(() { });},
        unfocusBackGround: (){
          focusBackGroundColorChange = null;
          setState(() { });
        }
      )
    );
  }  

  double windowZoomSize(){
    return html.window.devicePixelRatio/1.25;
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



  /* -----  キャンパス設定 ----- */

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

    math.Point<double> _dragPointPos = math.Point(widget.project.canvasSize.width/2, widget.project.canvasSize.height);

    double ballDiameter = 20.0;

    return [
      horizonScrollWidget,
      Positioned(
        left  : canvasToGlobalPos(_dragPointPos).x - ballDiameter / 2,
        top   : canvasToGlobalPos(_dragPointPos).y - ballDiameter / 2,
        child: CornerBallWidget(
          cursor      : SystemMouseCursors.resizeUpDown,
          ballDiameter: ballDiameter,
          onDragStart : (){ addHistory(widget.project.clone()); },
          onDragEnd   : (){
            _canvasDetailKey.currentState?.updateTextField();
            widget.project.save();
          },
          onDrag      : (dragPos) {
            math.Point<double> canvasDragPos = globalToCanvasPos(math.Point<double>(dragPos.dx, dragPos.dy));
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

  List<Widget> _focusBackGroundWidgetList(){
    if( focusBackGroundColorChange == null ) return [];

    double ballDiameter = 15.0;

    return [
      Positioned(
        left  : canvasToGlobalPos(math.Point(0,focusBackGroundColorChange!.pos)).x,
        top   : canvasToGlobalPos(math.Point(0,focusBackGroundColorChange!.pos)).y,
        child : Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all( color: Colors.blue.withAlpha(200), width: 4 )
          ),
          width   : widget.project.canvasSize.width,
          height  : focusBackGroundColorChange!.size,
        )
      ),
      Positioned(
        left  : canvasToGlobalPos(math.Point(widget.project.canvasSize.width/2, focusBackGroundColorChange!.pos)).x - ballDiameter / 2,
        top   : canvasToGlobalPos(math.Point(widget.project.canvasSize.width/2, focusBackGroundColorChange!.pos)).y - ballDiameter / 2,
        child: CornerBallWidget(
          cursor      : SystemMouseCursors.resizeUpDown,
          ballDiameter: ballDiameter,
          onDragStart : (){ addHistory(focusBackGroundColorChange!.clone()); },
          onDragEnd   : (){ focusBackGroundColorChange!.save(); },
          onDrag      : (dragPos) {
            setState(() { });
            double finishPos  = focusBackGroundColorChange!.pos + focusBackGroundColorChange!.size;
            math.Point<double> canvasDragPos = globalToCanvasPos(math.Point<double>(dragPos.dx, dragPos.dy));
            if( finishPos - canvasDragPos.y < 0 ) return;

            focusBackGroundColorChange!.size  = math.max(1, finishPos - canvasDragPos.y);
            focusBackGroundColorChange!.pos   = canvasDragPos.y;

            setState(() { });
          },
        ),
      ),
      Positioned(
        left  : canvasToGlobalPos(math.Point(widget.project.canvasSize.width/2, focusBackGroundColorChange!.pos)).x - ballDiameter / 2,
        top   : canvasToGlobalPos(math.Point(widget.project.canvasSize.width/2, focusBackGroundColorChange!.pos + focusBackGroundColorChange!.size)).y - ballDiameter / 2,
        child: CornerBallWidget(
          cursor      : SystemMouseCursors.resizeUpDown,
          ballDiameter: ballDiameter,
          onDragStart : (){ addHistory(focusBackGroundColorChange!.clone()); },
          onDragEnd   : (){ focusBackGroundColorChange!.save(); },
          onDrag      : (dragPos) {
            focusBackGroundColorChange!.size = math.max(1, globalToCanvasPos(math.Point<double>(dragPos.dx, dragPos.dy)).y - focusBackGroundColorChange!.pos);
            setState(() { });
          },
        ),
      ),

    ];
  }



  /* -----  コマ周り ----- */

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

  math.Point<double> dragStartLeftTopPos = const math.Point(0,0);
  math.Point<double> dragStartRightBottomPos = const math.Point(0,0);
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
      dragStartRightBottomPos = math.Point(
        _frameData.position.x + _frameData.rotateSize.x * _frameData.sizeRate,
        _frameData.position.y + _frameData.rotateSize.y * _frameData.sizeRate,
      );

      if(RawKeyboard.instance.keysPressed.where((_pressd) => _pressd.keyLabel == LogicalKeyboardKey.controlLeft.keyLabel).isNotEmpty){
        focusFrameDependList = frameImageList.where((_frame) => _frame.position.y > _frameData.position.y ).toList();
      }

      List<FrameImage> forHistoryList = [];
      for( FrameImage _focusFrame in focusFrameDependList){ forHistoryList.add(_focusFrame.clone()); }
      forHistoryList.add( _frameData.clone() );
      addHistory(forHistoryList);
    }

    void saveAfterDrag(){
      _frameData.save();
      _frameDetailKey.currentState?.updateTextField();

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
            math.Point<double> canvasDragPos = globalToCanvasPos(math.Point<double>(dragPos.dx, dragPos.dy));

            // sticy対応で仮計算する
            double tempSizeRate = math.max(
              (canvasDragPos.x - dragStartRightBottomPos.x).abs()/_frameData.rotateSize.x, 
              (canvasDragPos.y - dragStartRightBottomPos.y).abs()/_frameData.rotateSize.y, 
            );
            math.Point<double> newLeftTopPos = math.Point(
              dragStartRightBottomPos.x - _frameData.rotateSize.x * tempSizeRate,
              dragStartRightBottomPos.y - _frameData.rotateSize.y * tempSizeRate,
            );
            if( newLeftTopPos.x.abs() < stricyArea) newLeftTopPos = math.Point(0, newLeftTopPos.y);
            if( newLeftTopPos.y.abs() < stricyArea) newLeftTopPos = math.Point(newLeftTopPos.x, 0);

            _frameData.sizeRate = math.max(
              (newLeftTopPos.x - dragStartRightBottomPos.x).abs()/_frameData.rotateSize.x, 
              (newLeftTopPos.y - dragStartRightBottomPos.y).abs()/_frameData.rotateSize.y, 
            );
            _frameData.position = math.Point(
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
            math.Point<double> canvasDragPos = globalToCanvasPos(math.Point<double>(dragPos.dx, dragPos.dy));

            // sticy対応で仮計算する
            double tempSizeRate = math.max(
              (canvasDragPos.x - dragStartLeftTopPos.x).abs()/_frameData.rotateSize.x, 
              (canvasDragPos.y - dragStartRightBottomPos.y).abs()/_frameData.rotateSize.y, 
            );
            math.Point<double> newRightTopPos = math.Point(
              dragStartLeftTopPos.x     + _frameData.rotateSize.x * tempSizeRate,
              dragStartRightBottomPos.y - _frameData.rotateSize.y * tempSizeRate,
            );

            if( (widget.project.canvasSize.width - newRightTopPos.x).abs() < stricyArea) newRightTopPos = math.Point(widget.project.canvasSize.width, newRightTopPos.y);
            if( newRightTopPos.y.abs() < stricyArea) newRightTopPos = math.Point(newRightTopPos.x, 0);

            _frameData.sizeRate = math.max(
              (newRightTopPos.x - dragStartLeftTopPos.x).abs()/_frameData.rotateSize.x, 
              (newRightTopPos.y - dragStartRightBottomPos.y).abs()/_frameData.rotateSize.y, 
            );
            _frameData.position = math.Point(
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
            math.Point<double> canvasDragPos = globalToCanvasPos(math.Point<double>(dragPos.dx, dragPos.dy));

            // sticy対応で仮計算する
            double tempSizeRate = math.max(
              (canvasDragPos.x - dragStartRightBottomPos.x).abs()/_frameData.rotateSize.x, 
              (canvasDragPos.y - dragStartLeftTopPos.y).abs()/_frameData.rotateSize.y, 
            );
            math.Point<double> newLeftBottomPoint = math.Point(
              dragStartRightBottomPos.x - _frameData.rotateSize.x * tempSizeRate,
              dragStartLeftTopPos.y     + _frameData.rotateSize.y * tempSizeRate,
            );

            if( newLeftBottomPoint.x.abs() < stricyArea) newLeftBottomPoint = math.Point(0, newLeftBottomPoint.y);
            if( (widget.project.canvasSize.height - newLeftBottomPoint.y).abs() < stricyArea) newLeftBottomPoint = math.Point(newLeftBottomPoint.x, widget.project.canvasSize.height);

            // 反映
            math.Point<double> prePos = _frameData.position;
            double preSizeRate = _frameData.sizeRate;

            _frameData.sizeRate = math.max(
              (newLeftBottomPoint.x - dragStartRightBottomPos.x).abs()/_frameData.rotateSize.x, 
              (newLeftBottomPoint.y - dragStartLeftTopPos.y).abs()/_frameData.rotateSize.y, 
            );
            _frameData.position = math.Point(
              dragStartRightBottomPos.x - _frameData.rotateSize.x * _frameData.sizeRate,
              _frameData.position.y,
            );

            double prePosY = prePos.y + _frameData.rotateSize.y * preSizeRate;
            double newPosY = _frameData.position.y + _frameData.rotateSize.y * _frameData.sizeRate;
            double diffY = prePosY - newPosY;

            for (FrameImage _depandFrame in focusFrameDependList) {
              _depandFrame.position = math.Point(_depandFrame.position.x, _depandFrame.position.y-diffY);
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
            math.Point<double> canvasDragPos = globalToCanvasPos(math.Point<double>(dragPos.dx, dragPos.dy));

            // sticy対応で仮計算する
            double tempSizeRate = math.max(
              (canvasDragPos.x - dragStartLeftTopPos.x).abs()/_frameData.rotateSize.x, 
              (canvasDragPos.y - dragStartLeftTopPos.y).abs()/_frameData.rotateSize.y, 
            );
            math.Point<double> newRightBottomPoint = math.Point(
              dragStartLeftTopPos.x + _frameData.rotateSize.x * tempSizeRate,
              dragStartLeftTopPos.y + _frameData.rotateSize.y * tempSizeRate,
            );

            if( (widget.project.canvasSize.width  - newRightBottomPoint.x).abs() < stricyArea) newRightBottomPoint = math.Point(widget.project.canvasSize.width, newRightBottomPoint.y);
            if( (widget.project.canvasSize.height - newRightBottomPoint.y).abs() < stricyArea) newRightBottomPoint = math.Point(newRightBottomPoint.x, widget.project.canvasSize.height);

            // 反映
            math.Point<double> prePos = _frameData.position;
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
              _depandFrame.position = math.Point(_depandFrame.position.x, _depandFrame.position.y-diffY);
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

            // {SpeakBlockList: [], Cornermath.Points: [{X: 0, Y: 0}, {X: 502, Y: 0}, {X: 505, Y: 259}, {X: 0, Y: 259}], FrameNumber: 0, StepData: {X: 0, Y: 0, StepNum: 0}}
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
            math.Point<double> calcPos(){
              // ignore: prefer_const_constructors
              if( currentHeight == 0 ) return math.Point(0,0);

              // ignore: prefer_const_constructors
              return math.Point(0, currentHeight + 100);
            }
            targetFrame.position = calcPos();

            // 枠を超えていた場合は、rateで枠内に収まるようにする
            if( targetFrame.rotateSize.x > defaultCanvasWidth ) targetFrame.sizeRate = targetFrame.rotateSize.x/defaultCanvasWidth;

            targetFrame.save();

            currentHeight = targetFrame.position.y + targetFrame.rotateSize.y * targetFrame.sizeRate;
          });
        });

        widget.project.canvasSize = Size(defaultCanvasWidth, currentHeight + 100);
        _canvasDetailKey.currentState?.updateTextField();

        widget.project.save();
        setState(() { });

        //  ないなら、ファイルを作って保存処理＋自然配置
        continue;
      }
    });
  }  

  math.Point<double> canvasToGlobalPos(math.Point<double> _pos){
    Offset _offsetSize = Offset(
      sideSpaceWidth() - (horizonScrollController.hasClients ? horizonScrollController.position.pixels : 0),
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
      sideSpaceWidth() - (horizonScrollController.hasClients ? horizonScrollController.position.pixels : 0),
      (verticalScrollController.hasClients ? verticalScrollController.position.pixels : 0)
    );

    return math.Point(
      _pos.x - _offsetSize.dx,
      _pos.y + _offsetSize.dy,
    );
  }  

  void addHistory(dynamic action){
    print(" add history ");
    historyLog.add(action);
    futureLog.clear();
  }

}