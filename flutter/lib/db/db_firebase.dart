// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
// コマデータ
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/model/background_color_change.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';
import 'package:tateyomi_gigarizer/model/project.dart';

class DbFireStore implements DbImpl {  
  static String _loginId = "";

  @override
  String get loginId{ return _loginId; }

  @override
  set loginId(_text){ _loginId = _text; }

  @override
  void Function()? reBuildCanvasBody;

  @override
  void reBuildCanvas(){
    if( reBuildCanvasBody == null) return;

    reBuildCanvasBody!();
  }

  double checkDouble(dynamic value, double defaultValue) {
    if(value == null) return defaultValue;
    if(value is double) return value;
    if(value is int) return value.toDouble();
    if(value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static const String _userCollection = 'user';
  DocumentReference baseDocRef(){ return FirebaseFirestore.instance.collection(_userCollection).doc(_loginId); }
  CollectionReference baseProjRef(){ return baseDocRef().collection(_projectCollection); }

  String _getUniqueId(String preIndex){
    return preIndex + "_" + DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  static const String _projectCollection = "project";

  List<String> snapShotList = [];

  final Map<String, List<Project>> _cachedProjectList = {};
  @override
  Future<List<Project>> getProjectList() async {
    if(!_cachedProjectList.containsKey( baseProjRef().path )) _cachedProjectList[baseProjRef().path] = [];

    if(_cachedProjectList[baseProjRef().path]!.isNotEmpty) return _cachedProjectList[baseProjRef().path]!;

    Project createProjectModel(DocumentSnapshot _snapDoc, ){
      Map<String, dynamic> snapData = (_snapDoc.data() as Map<String, dynamic>);

      Project addProj = Project(
        this, 
        _snapDoc.id,
        snapData["name"] ?? "",
        Size(
          checkDouble(snapData["canvas_width"]  , 690.0),
          checkDouble(snapData["canvas_height"] , 10000.0),
        ),
        snapData["last_open_time"]  ?? DateTime.now().millisecondsSinceEpoch,
        snapData["create_time"]     ?? DateTime.now().millisecondsSinceEpoch,
      );
      return addProj;
    }

    QuerySnapshot projDocSnapShot = await baseProjRef().get();

    for (QueryDocumentSnapshot<Object?> projDoc in projDocSnapShot.docs) {
      Project _addProject = createProjectModel(projDoc);

      int projIndex = _cachedProjectList[baseProjRef().path]!.indexWhere((_cacheProj) => _cacheProj.dbIndex == _addProject.dbIndex );
      if( projIndex >= 0 ) continue;

      _cachedProjectList[baseProjRef().path]!.add(_addProject);
    }

    if(snapShotList.contains(baseProjRef().path)) return _cachedProjectList[baseProjRef().path]!;
    snapShotList.add(baseProjRef().path);

    baseProjRef().snapshots().listen((data){
      // if(_cachedProjectList[_loginId]!.isNotEmpty) return _cachedProjectList[_loginId]!;

      bool isUpdate = false;
      for (DocumentChange<Object?> _doc in data.docChanges) {
        Project _changeProject = createProjectModel(_doc.doc);

        // // 削除
        // if(_doc.type == DocumentChangeType.removed){
          
        //   return;
        // }

        // 追加
        if(_doc.type == DocumentChangeType.added){
          if( !_cachedProjectList.containsKey(baseProjRef().path) ) _cachedProjectList[baseProjRef().path] = [];

          List<Project> storedProject = _cachedProjectList[baseProjRef().path]!.where( (_cacheProj){ return ( _cacheProj.dbIndex.isEmpty || _cacheProj.dbIndex == _changeProject.dbIndex ); } ).toList();
          if(storedProject.isNotEmpty) continue;   // すでにある場合は、なにもしない

          _cachedProjectList[baseProjRef().path]!.add(_changeProject);

          isUpdate = true;
          continue;
        }        

        // 更新
        List<Project> storedProject = _cachedProjectList[baseProjRef().path]?.where( (_cacheProj){ return ( _cacheProj.dbIndex == _changeProject.dbIndex ); } ).toList() ?? [];
        if( storedProject.isEmpty ) continue;

        Project storedChangedProject = storedProject.first;

        bool isChanged(dynamic a, dynamic b){
          if( a != b) isUpdate = true;
          return a != b;
        }

        if( isChanged(storedChangedProject.name, _changeProject.name ) ) storedChangedProject.name  = _changeProject.name;
        if( isChanged(storedChangedProject.canvasSize.width , _changeProject.canvasSize.width   ) ) storedChangedProject.canvasSize  = _changeProject.canvasSize;
        if( isChanged(storedChangedProject.canvasSize.height, _changeProject.canvasSize.height  ) ) storedChangedProject.canvasSize  = _changeProject.canvasSize;
        if( isChanged(storedChangedProject.lastOpenTime , _changeProject.lastOpenTime ) ) storedChangedProject.lastOpenTime  = _changeProject.lastOpenTime;
        if( isChanged(storedChangedProject.createTime   , _changeProject.createTime   ) ) storedChangedProject.createTime  = _changeProject.createTime;
      }

      if(isUpdate) reBuildCanvas();

      return;
    },);

    return _cachedProjectList[baseProjRef().path]!;
  }

  @override
  Future<String> insertProject(Project _insertProj) async {
    _insertProj.dbIndex = _getUniqueId("project");
    baseProjRef().doc(_insertProj.dbIndex).set( _insertProj.toDbJson() );
    return _insertProj.dbIndex;
  }

  @override
  Future<void> updateProject(Project _updateProj) async {
    if( _updateProj.dbIndex.isEmpty ) return;

    baseProjRef().doc(_updateProj.dbIndex).update( _updateProj.toDbJson() );
  }
  
  static const String _frameCollection = 'frame';
  CollectionReference baseFrameRef(Project _proj){ return baseProjRef().doc(_proj.dbIndex).collection(_frameCollection); }

  final Map<String, List<FrameImage>> _cachedFrameList = {};

  @override
  Future<List<FrameImage>> getFrameList(Project _proj) async {
    if(!_cachedFrameList.containsKey( _proj.dbIndex )) _cachedFrameList[_proj.dbIndex] = [];

    if(_cachedFrameList[_proj.dbIndex]!.isNotEmpty) return _cachedFrameList[_proj.dbIndex]!;

    FrameImage createFrameModel(DocumentSnapshot _snapDoc, Project? __proj){
      Map<String, dynamic> snapData = (_snapDoc.data() as Map<String, dynamic>);

      Project getProject(){
        if( __proj != null ) return __proj;
        if( snapData["project_id"] == null ) return _proj;
      
        if( snapData["project_id"] != null ){
          List<Project> tmpList = _cachedProjectList[baseProjRef().path]!.where((_projList) => _projList.dbIndex == snapData["project_id"]).toList();
          if( tmpList.isNotEmpty ) return tmpList.first;
        }

        return _proj;
      }
 
      FrameImage addFrameImage = FrameImage(
        dbInstance  : this,
        project     : getProject(),
        dbIndex     : _snapDoc.id,
        name        : snapData["name"] ?? "",
        sizeRate    : checkDouble(snapData["size_rate"], 1.0),
        position    : Point<double>( checkDouble(snapData["position_x"], 0), checkDouble(snapData["position_y"], 0), ),
        angle       : snapData["angle"] ?? 0,
        size        : const Point<double>(0,0),
      );
      return addFrameImage;
    }

    QuerySnapshot frameDocSnapShot = await baseFrameRef(_proj).get();

    for (QueryDocumentSnapshot<Object?> frameDoc in frameDocSnapShot.docs) {
      FrameImage  _addFrame = createFrameModel(frameDoc, _proj);

      int frameIndex = _cachedFrameList[_proj.dbIndex]!.indexWhere((_cacheFrame) => _cacheFrame.dbIndex == _addFrame.dbIndex );
      if( frameIndex >= 0 ) continue;

      _cachedFrameList[_proj.dbIndex]!.add(_addFrame);
    }

    if(snapShotList.contains(baseFrameRef(_proj).path)) return _cachedFrameList[_proj.dbIndex]!;
    snapShotList.add(baseFrameRef(_proj).path);

    baseFrameRef(_proj).snapshots().listen((data){
      // if(_cachedProjectList[_loginId]!.isNotEmpty) return _cachedProjectList[_loginId]!;
      bool isUpdate = false;
      for (DocumentChange<Object?> _doc in data.docChanges) {

        FrameImage _changeFrame = createFrameModel(_doc.doc, null);

        // 削除
        if(_doc.type == DocumentChangeType.removed){
          if( _cachedFrameList[_changeFrame.project.dbIndex]!.indexWhere( (_cacheFrame){ return ( _cacheFrame.dbIndex == _changeFrame.dbIndex ); } ) < 0 ) return;

          _cachedFrameList[_changeFrame.project.dbIndex]!.removeWhere( (_cacheFrame){ return ( _cacheFrame.dbIndex == _changeFrame.dbIndex ); } );
          isUpdate = true;

          continue;
        }

        // 追加
        if(_doc.type == DocumentChangeType.added){
          if( !_cachedFrameList.containsKey(_changeFrame.project.dbIndex) ) _cachedFrameList[_changeFrame.project.dbIndex] = [];

          List<FrameImage> storedFrame = _cachedFrameList[_changeFrame.project.dbIndex]!.where( (_cacheFrame){ return ( _cacheFrame.dbIndex.isEmpty || _cacheFrame.dbIndex == _changeFrame.dbIndex ); } ).toList();
          if(storedFrame.isNotEmpty) continue;   // すでにある場合は、なにもしない

          _cachedFrameList[_proj]!.add(_changeFrame);
          isUpdate = true;
          continue;
        }        

        // 更新
        List<FrameImage> storedFrame = _cachedFrameList[_changeFrame.project.dbIndex]?.where( (_cacheFrame){ return ( _cacheFrame.dbIndex == _changeFrame.dbIndex ); } ).toList() ?? [];
        if( storedFrame.isEmpty ) continue;

        FrameImage storedChangedFrame = storedFrame.first;

        bool isChanged(dynamic a, dynamic b){
          if( a != b) isUpdate = true;
          return a != b;
        }

      // required this.name, 
      // required this.sizeRate, 
      // required this.position, 
      // required this.angle, 

        if( isChanged(storedChangedFrame.name, _changeFrame.name ) ) storedChangedFrame.name  = _changeFrame.name;
        if( isChanged(storedChangedFrame.sizeRate, _changeFrame.sizeRate ) ) storedChangedFrame.sizeRate  = _changeFrame.sizeRate;
        if( isChanged(storedChangedFrame.position.x, _changeFrame.position.x ) ) storedChangedFrame.position  = _changeFrame.position;
        if( isChanged(storedChangedFrame.position.y, _changeFrame.position.y ) ) storedChangedFrame.position  = _changeFrame.position;
        if( isChanged(storedChangedFrame.angle, _changeFrame.angle ) ) storedChangedFrame.angle  = _changeFrame.angle;
      }
      if(isUpdate) reBuildCanvas();

      return;
    },);

    return _cachedFrameList[_proj.dbIndex]!;
  }

  @override
  String insertFrame(FrameImage _insertFrame) {
   if( _insertFrame.dbIndex.isEmpty )  _insertFrame.dbIndex = _getUniqueId("frame_" + _insertFrame.name);
    baseFrameRef(_insertFrame.project).doc(_insertFrame.dbIndex).set( _insertFrame.toDbJson() );
    return _insertFrame.dbIndex;
  }

  @override
  Future<void> updateFrame(FrameImage _updateFrame) async {
    if( _updateFrame.dbIndex.isEmpty ) return;

    baseFrameRef(_updateFrame.project).doc(_updateFrame.dbIndex).update( _updateFrame.toDbJson() );
  }

  @override
  Future<void> deleteFrame(FrameImage _deleteFrame) async {
    if( _deleteFrame.dbIndex.isEmpty ) return;
    baseFrameRef(_deleteFrame.project).doc(_deleteFrame.dbIndex).delete();
  }

  static const String _backgroundColorCollection = "backgroundcolor";
  CollectionReference baseBackGroundColorRef(Project _proj){ return baseProjRef().doc(_proj.dbIndex).collection(_backgroundColorCollection); }
  final Map<String, List<BackGroundColorChange>> _cachedBackgroundColorList = {};

  @override
  Future<List<BackGroundColorChange>> getBackGroundColorList(Project _proj) async {
    if(!_cachedBackgroundColorList.containsKey(_proj.dbIndex )) _cachedBackgroundColorList[_proj.dbIndex] = [];

    if(_cachedBackgroundColorList[_proj.dbIndex]!.isNotEmpty) return _cachedBackgroundColorList[_proj.dbIndex]!;

    BackGroundColorChange createBackgroundColor(DocumentSnapshot _snapDoc, Project? __proj){
      Map<String, dynamic> snapData = (_snapDoc.data() as Map<String, dynamic>);

      Project getProject(){
        if( __proj != null ) return __proj;
        if( snapData["project_id"] == null ) return _proj;
      
        if( snapData["project_id"] != null ){
          List<Project> tmpList = _cachedProjectList[baseProjRef().path]!.where((_projList) => _projList.dbIndex == snapData["project_id"]).toList();
          if( tmpList.isNotEmpty ) return tmpList.first;
        }

        return _proj;
      }

 
      return BackGroundColorChange(
        this, getProject(), _snapDoc.id, 
        snapData["color"] != null ? Color( snapData["color"] ) : Colors.black,
        checkDouble(snapData["pos"]   , 0.0),
        checkDouble(snapData["size"]  , 300.0)
      );
    }

    QuerySnapshot frameDocSnapShot = await baseBackGroundColorRef(_proj).get();

    for (QueryDocumentSnapshot<Object?> frameDoc in frameDocSnapShot.docs) {
      BackGroundColorChange  _addBackgroundColor = createBackgroundColor(frameDoc, _proj);

      int backgroundIndex = _cachedBackgroundColorList[_proj.dbIndex]!.indexWhere((_cachedBackgroundColor) => _cachedBackgroundColor.dbIndex == _addBackgroundColor.dbIndex );
      if( backgroundIndex >= 0 ) continue;

      _cachedBackgroundColorList[_proj.dbIndex]!.add(_addBackgroundColor);
    }

    if(snapShotList.contains(baseBackGroundColorRef(_proj).path)) return _cachedBackgroundColorList[_proj.dbIndex]!;
    snapShotList.add(baseBackGroundColorRef(_proj).path);

    baseBackGroundColorRef(_proj).snapshots().listen((data){
      // if(_cachedProjectList[_loginId]!.isNotEmpty) return _cachedProjectList[_loginId]!;

      bool isUpdate = false;
      for (DocumentChange<Object?> _doc in data.docChanges) {
        BackGroundColorChange  _changeBackgroundColor = createBackgroundColor(_doc.doc, null);

        // 削除
        if(_doc.type == DocumentChangeType.removed){
          if( _cachedBackgroundColorList[_changeBackgroundColor.project.dbIndex]!.indexWhere( (_cachedBackgroundColor){ return ( _cachedBackgroundColor.dbIndex == _changeBackgroundColor.dbIndex ); } ) < 0 ) return;

          _cachedBackgroundColorList[_changeBackgroundColor.project.dbIndex]!.removeWhere( (_cachedBackgroundColor){ return ( _cachedBackgroundColor.dbIndex == _changeBackgroundColor.dbIndex ); } );
          isUpdate = true;

          continue;
        }

        // 追加
        if(_doc.type == DocumentChangeType.added){
          if( !_cachedBackgroundColorList.containsKey(_changeBackgroundColor.project.dbIndex) ) _cachedBackgroundColorList[_changeBackgroundColor.project.dbIndex] = [];

          List<BackGroundColorChange> storedBackGround = _cachedBackgroundColorList[_changeBackgroundColor.project.dbIndex]!.where( (_cachedBackgroundColor){ return ( _cachedBackgroundColor.dbIndex.isEmpty || _cachedBackgroundColor.dbIndex == _changeBackgroundColor.dbIndex ); } ).toList();
          if(storedBackGround.isNotEmpty) continue;   // すでにある場合は、なにもしない

          _cachedBackgroundColorList[_changeBackgroundColor.project.dbIndex]!.add(_changeBackgroundColor);

          isUpdate = true;
          continue;
        }        

        // 更新
        List<BackGroundColorChange> storedBackGround = _cachedBackgroundColorList[_changeBackgroundColor.project.dbIndex]?.where( (_cachedBackgroundColor){ return ( _cachedBackgroundColor.dbIndex == _changeBackgroundColor.dbIndex ); } ).toList() ?? [];
        if( storedBackGround.isEmpty ) continue;

        BackGroundColorChange storedChangedBackGround = storedBackGround.first;

        bool isChanged(dynamic a, dynamic b){
          if( a != b) isUpdate = true;
          return a != b;
        }

        if( isChanged(storedChangedBackGround.pos         , _changeBackgroundColor.pos ) ) storedChangedBackGround.pos  = _changeBackgroundColor.pos;
        if( isChanged(storedChangedBackGround.size        , _changeBackgroundColor.size ) ) storedChangedBackGround.size  = _changeBackgroundColor.size;
        if( isChanged(storedChangedBackGround.targetColor , _changeBackgroundColor.targetColor ) ) storedChangedBackGround.targetColor  = _changeBackgroundColor.targetColor;
      }

      if(isUpdate) reBuildCanvas();

      return;
    },);

    return _cachedBackgroundColorList[_proj.dbIndex]!;
  }
  @override
  Future<String> insertBackGroundColor(BackGroundColorChange _insertBackGround) async {
   if( _insertBackGround.dbIndex.isEmpty ) _insertBackGround.dbIndex = _getUniqueId("backgroundcolor");
    baseBackGroundColorRef(_insertBackGround.project).doc(_insertBackGround.dbIndex).set( _insertBackGround.toDbJson() );
    return _insertBackGround.dbIndex;
  }
  @override
  Future<void> updateBackGroundColor(BackGroundColorChange _updateBackGround) async {
    if( _updateBackGround.dbIndex.isEmpty ) return;
    baseBackGroundColorRef(_updateBackGround.project).doc(_updateBackGround.dbIndex).update( _updateBackGround.toDbJson() );
  }
  @override
  Future<void> deleteBackGroundColor(BackGroundColorChange _deleteBackGround) async {
    if( _deleteBackGround.dbIndex.isEmpty ) return;
    baseBackGroundColorRef(_deleteBackGround.project).doc(_deleteBackGround.dbIndex).delete();
  }

  static const String _downloadCollection = "download";
  DocumentReference baseDownloadRef(){ return FirebaseFirestore.instance.collection(_downloadCollection).doc("kYHCYZB0Vtpzs2J7QL6o"); }
  final Map<double, String> _cachedDownloadMap = {};

  @override
  Future<Map<double, String>> getDownloadCanvasSizeList() async {
    if( _cachedDownloadMap.isNotEmpty ) return _cachedDownloadMap;

    DocumentSnapshot frameDocSnapShot = await baseDownloadRef().get();
    for (Map _widthMap in ((frameDocSnapShot.data() as Map)["widthMap"] as List)) {
      _cachedDownloadMap[(_widthMap["width"] as int).toDouble()] = _widthMap["service"];
    }

    if(snapShotList.contains(baseDownloadRef().path)) return _cachedDownloadMap;
    snapShotList.add(baseDownloadRef().path);

    baseDownloadRef().snapshots().listen((data){
      for (Map _widthMap in ((data.data() as Map)["widthMap"] as List)) {
        _cachedDownloadMap[(_widthMap["width"] as int).toDouble()] = _widthMap["service"];
      }
    },);

    return _cachedDownloadMap;    
  }

  @override
  bool get isTest{ return false; }
}