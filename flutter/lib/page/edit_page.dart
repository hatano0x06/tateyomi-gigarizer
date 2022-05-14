// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:typed_data';

import 'package:adaptive_scrollbar/adaptive_scrollbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
import 'package:tateyomi_gigarizer/dialog/text_input_dialog.dart';

// ignore: unused_import
import 'package:tateyomi_gigarizer/download/canvas_to_image.dart';

// ignore: unused_import
import 'package:tateyomi_gigarizer/download/sample_show_download.dart';

import 'package:tateyomi_gigarizer/model/background_color_change.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';
import 'package:tateyomi_gigarizer/model/history_data.dart';
import 'package:tateyomi_gigarizer/model/keyboard.dart';
import 'package:tateyomi_gigarizer/model/project.dart';
import 'package:tateyomi_gigarizer/page/parts/background_color_detail_box.dart';
import 'package:tateyomi_gigarizer/page/parts/canvas_detail_box.dart';
import 'package:tateyomi_gigarizer/page/parts/corner_ball.dart';
import 'package:tateyomi_gigarizer/dialog/shortcuts_info_dialog.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:math' as math;

import 'init_frame_position.dart';
import 'parts/frame_detail_box.dart';

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

  List<HistoryData> historyLog  = [];
  List<HistoryData> futureLog   = [];

  Map<String, Uint8List> frameImageBytes = {};
  Map<String, math.Point<double>> frameImageSize = {};

  @override
  void initState(){
    super.initState();

    widget.dbInstance.reBuildCanvasBody = (){
      
      // 削除されていた場合は、フォーカスの解除
      if( focusFrame != null ){
        if( frameImageList.indexWhere((_framelist) => _framelist.dbIndex == focusFrame!.dbIndex) < 0 ) focusFrame = null;
      }

      if( focusBackGroundColorChange != null ){
        if( backGroundColorChangeList.indexWhere((_backlist) => _backlist.dbIndex == focusBackGroundColorChange!.dbIndex) < 0 ) focusBackGroundColorChange = null;
      }      

      for (FrameImage _frame in frameImageList) {
        if( _frame.size.x == 0 && _frame.size.y == 0 && frameImageSize.containsKey(_frame.dbIndex) ) _frame.size = frameImageSize[_frame.dbIndex]!;
      }

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

                if( _tmpColor.pos + _tmpColor.size > widget.project.canvasSize.height ) _tmpColor.pos = widget.project.canvasSize.height - 50;
                _tmpColor.save();

                setFocusBackGround(_tmpColor);
                backGroundColorChangeList.add( _tmpColor );

                addHistory(typeAdd, _tmpColor.clone());

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
            icon    : const Icon(Icons.download),
            onPressed: () async {
              Fluttertoast.showToast(
                msg: "データ作成中",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.TOP,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.grey[300],
                textColor: Colors.black,
                fontSize: 16.0
              );

              // TODO: asdf
              List<double> widthList = (await widget.dbInstance.getDownloadCanvasSizeList()).keys.toList();
              CanvasToImage(widget.project, frameImageList, backGroundColorChangeList, frameImageBytes, widthList).download();

              // Widget samplePage = DownloadViewerBoard(
              //   project: widget.project,
              //   frameImageList: frameImageList,
              //   backgroundColorList: backGroundColorChangeList,
              //   frameImageBytes: frameImageBytes,
              // );
              // Navigator.push( context, PageRouteBuilder( pageBuilder: (context, animation1, animation2) => samplePage ), );
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

      for (FrameImage _frameImage in frameImageList.toList().reversed.toList()) {
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
          _backgroundColorDetailKey.currentState?.clearFirst();
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
          addHistory(typeEdit, forHistoryList);
          return;
        }

        draggingBackGroundColorChange = targetBackGroundColor(_dragStart.globalPosition);
        if( draggingBackGroundColorChange != null ){
          _backgroundColorDetailKey.currentState?.clearFirst();
          setFocusBackGround(draggingBackGroundColorChange);
          initDragPosition = math.Point(0, draggingBackGroundColorChange!.pos);

          addHistory(typeEdit, draggingBackGroundColorChange!.clone());
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
          
          // キャンパスよりも下回るのはダメ
          double newPos = initDragPosition.y + (currentDragFramePosition - initDragFramePosition).y;
          if( newPos + draggingBackGroundColorChange!.size >= widget.project.canvasSize.height ) return;
          if( newPos + draggingBackGroundColorChange!.size <= 0 ) return;

          draggingBackGroundColorChange!.pos = newPos;
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

        _backgroundColorDetailKey.currentState?.clearFirst();

        setState(() { });
        if( shortCutType == TYPE_SHORTCUT_HISTORY_BACK ){
          if( historyLog.isEmpty) return;

          HistoryData historyData = historyLog.last;

          dynamic targetModel = historyData.data;

          if( targetModel is Project ){
            futureLog.add( HistoryData(typeEdit, widget.project.clone()) );
            widget.project.copy(targetModel);
            widget.project.save();
          }
          if( targetModel is FrameImage ){
            // 削除を遡るということなので、追加する
            if( historyData.type == typeDelete){
              frameImageList.add(targetModel);
              targetModel.insertSave();
              futureLog.add( historyData );
            }
            if( historyData.type == typeEdit){
              FrameImage currentFrame = frameImageList.singleWhere((_frame) => _frame.dbIndex == targetModel.dbIndex);
              futureLog.add( HistoryData(typeEdit, currentFrame.clone()) );
              currentFrame.copy(targetModel);
              currentFrame.save();
            }
          }
          if( targetModel is List<FrameImage> ){
            List<FrameImage> forFutureList = [];
            for (FrameImage _historyFrame in targetModel) {
              FrameImage currentFrame = frameImageList.singleWhere((_frame) => _frame.dbIndex == _historyFrame.dbIndex);
              forFutureList.add(currentFrame.clone());
              currentFrame.copy(_historyFrame);
              currentFrame.save();
            }

            futureLog.add( HistoryData(typeEdit, forFutureList) );
          }
          
          if( targetModel is BackGroundColorChange ){
            // 追加を遡るということなので、削除する
            if( historyData.type == typeAdd){
              backGroundColorChangeList.removeWhere((_frame) => _frame.dbIndex == targetModel.dbIndex);
              if( (focusBackGroundColorChange?.dbIndex ?? "") == targetModel.dbIndex) focusBackGroundColorChange = null;
              futureLog.add( historyData );
              targetModel.delete();
            }
            // 削除を遡るということなので、追加する
            if( historyData.type == typeDelete){
              backGroundColorChangeList.add(targetModel);
              targetModel.insertSave();
              futureLog.add( historyData );
            }

            if( historyData.type == typeEdit){
              BackGroundColorChange currentBackColor = backGroundColorChangeList.singleWhere((_frame) => _frame.dbIndex == targetModel.dbIndex);
              futureLog.add( HistoryData(typeEdit, currentBackColor.clone()) );
              currentBackColor.copy(targetModel);
              currentBackColor.save();
            }
          }

          historyLog.removeLast();
        }

        if( shortCutType == TYPE_SHORTCUT_HISTORY_FRONT ){
          if( futureLog.isEmpty) return;

          HistoryData futureData = futureLog.last;
          dynamic targetModel = futureData.data;

          if( targetModel is Project ){
            historyLog.add( HistoryData(typeEdit, widget.project.clone()) );
            widget.project.copy(targetModel);
            widget.project.save();
          }
          if( targetModel is FrameImage ){
            if( futureData.type == typeDelete){
              frameImageList.removeWhere((_frame) => _frame.dbIndex == targetModel.dbIndex);
              targetModel.delete();

              historyLog.add( futureData );
            }
            if( futureData.type == typeEdit){
              FrameImage currentFrame = frameImageList.singleWhere((_frame) => _frame.dbIndex == targetModel.dbIndex);
              historyLog.add( HistoryData(typeEdit, currentFrame.clone()) );
              currentFrame.copy(targetModel);
              currentFrame.save();
            }
          }
          if( targetModel is List<FrameImage> ){
            List<FrameImage> forHistoryList = [];
            for (FrameImage _historyFrame in targetModel) {
              FrameImage currentFrame = frameImageList.singleWhere((_frame) => _frame.dbIndex == _historyFrame.dbIndex);
              forHistoryList.add(currentFrame.clone());
              currentFrame.copy(_historyFrame);
              currentFrame.save();
            }
            historyLog.add( HistoryData(typeEdit, forHistoryList) );
          }

          if( targetModel is BackGroundColorChange ){
            if( futureData.type == typeAdd){
              backGroundColorChangeList.add(targetModel);
              targetModel.insertSave();
              historyLog.add( futureData );
            }
            if( futureData.type == typeDelete){
              backGroundColorChangeList.removeWhere((_frame) => _frame.dbIndex == targetModel.dbIndex);
              targetModel.delete();
              historyLog.add( futureData );
            }            
            if( futureData.type == typeEdit){
              BackGroundColorChange currentBackColor = backGroundColorChangeList.singleWhere((_frame) => _frame.dbIndex == targetModel.dbIndex);
              historyLog.add( HistoryData(typeEdit, currentBackColor.clone()) );
              currentBackColor.copy(targetModel);
              currentBackColor.save();
            }
          }

          futureLog.removeLast();
        }        

        if( focusFrame != null ){

          if( 
            shortCutType == TYPE_SHORTCUT_UP    ||
            shortCutType == TYPE_SHORTCUT_DOWN    ||
            shortCutType == TYPE_SHORTCUT_LEFT    ||
            shortCutType == TYPE_SHORTCUT_RIGHT    
          ){
            if( !startPress ) addHistory(typeEdit, focusFrame!.clone());
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
        update          : (){
          addHistory(typeEdit, widget.project.clone());
        }
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
        delete: (){
          addHistory(typeDelete, focusFrame!.clone());

          frameImageList.remove(focusFrame!);
          focusFrame!.delete();
          setFocusFrame(null);
        },
        update: (List<FrameImage> updateFrameList){
          addHistory(typeEdit, updateFrameList);
        },
      )
    );
  }


  Widget focusBackGroundDetailSettingBox(){
    if(focusBackGroundColorChange == null ) return Container();

    return Positioned(
      top   : 20,
      left  : sideSpaceWidth() + widget.project.canvasSize.width - horizonScrollController.position.pixels + 20,
      child: BackGroundColorDetailWidget(
        key : _backgroundColorDetailKey,
        backGroundColorChange: focusBackGroundColorChange!,
        mainBuild: (){ setState(() { });},
        update: (BackGroundColorChange _backColor){
          addHistory(typeEdit, _backColor.clone());
        },
        delete: (){
          backGroundColorChangeList.remove(focusBackGroundColorChange!);
          focusBackGroundColorChange!.delete();

          addHistory(typeDelete, focusBackGroundColorChange!.clone());

          focusBackGroundColorChange = null;
          setState(() { });
        },
      )
    );
  }  

  double windowZoomSize(){
    return html.window.devicePixelRatio/1.25;
  }

  bool isImageLoaded(){
    if( widget.project.canvasSize == Size.zero ) return false;

    return frameImageBytes.isNotEmpty;
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
          onDragStart : (){ addHistory(typeEdit, widget.project.clone()); },
          onDragEnd   : (){
            setCanvasEdit(true);
            _canvasDetailKey.currentState?.updateTextField();
            widget.project.save();
          },
          onDrag      : (dragPos) {
            math.Point<double> canvasDragPos = globalToCanvasPos(math.Point<double>(dragPos.dx, dragPos.dy));
            if( canvasDragPos.y <= 0 ) return;
            
            // 背景色より上にくることはないはずなので、制限をかける
            if( backGroundColorChangeList.isNotEmpty ){
              if( canvasDragPos.y <= backGroundColorChangeList.last.pos + backGroundColorChangeList.last.size ) return;
            }
            
            widget.project.canvasSize = Size(widget.project.canvasSize.width, canvasDragPos.y.round().toDouble());
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
          onDragStart : (){ addHistory(typeEdit, focusBackGroundColorChange!.clone()); _backgroundColorDetailKey.currentState?.clearFirst(); },
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
          onDragStart : (){ addHistory(typeEdit, focusBackGroundColorChange!.clone()); _backgroundColorDetailKey.currentState?.clearFirst(); },
          onDragEnd   : (){ focusBackGroundColorChange!.save(); },
          onDrag      : (dragPos) {

            double newSize = globalToCanvasPos(math.Point<double>(dragPos.dx, dragPos.dy)).y - focusBackGroundColorChange!.pos;
            if( focusBackGroundColorChange!.pos + newSize >= widget.project.canvasSize.height ) return;
            if( focusBackGroundColorChange!.pos + newSize <= 0 ) return;
            focusBackGroundColorChange!.size = math.max(1, newSize);
            setState(() { });
          },
        ),
      ),

    ];
  }



  /* -----  コマ周り ----- */

  List<Widget> _frameBodyList(){

    frameImageList.sort((FrameImage a, FrameImage b){ return a.position.y.compareTo(b.position.y); });

    List<Widget> showWidgetList = [];

    for (FrameImage _frameData in frameImageList) {
      if( !frameImageBytes.containsKey(_frameData.dbIndex)) continue;
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
      addHistory(typeEdit, forHistoryList);
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
            frameImageBytes[_frameData.dbIndex]!,
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
      await initLoadImage(
        result.files, frameImageList, frameImageBytes, frameImageSize, widget.project, 
        (){ 
          setState(() { }); 
        }, 
        (){ 
          initFramePos(result.files, frameImageList, widget.project, (){ setState(() { }); },); 
        }
      );
      setState(() { });
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

  void addHistory(String type, dynamic model, ){

    const int historySize = 100;
    historyLog.add(HistoryData(type, model));

    if( historyLog.length > historySize ) historyLog.removeAt(0);
    futureLog.clear();
  }

}