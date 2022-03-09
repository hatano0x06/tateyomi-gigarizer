// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
// コマデータ
import 'dart:math';

import 'package:flutter/material.dart';
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
        snapData["download_name"] ?? "",
        Size(
          snapData["canvas_width"]  ?? 690,
          snapData["canvas_height"] ?? 10000,
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
          List<Project> storedProject = _cachedProjectList[baseProjRef().path]!.where( (_cacheProj){ return ( _cacheProj.dbIndex.isEmpty || _cacheProj.dbIndex == _changeProject.dbIndex ); } ).toList();
          if(storedProject.isNotEmpty) return;   // すでにある場合は、なにもしない

          _cachedProjectList[baseProjRef().path]!.add(_changeProject);

          isUpdate = true;
          return;
        }        

        // 更新
        List<Project> storedProject = _cachedProjectList[baseProjRef().path]!.where( (_cacheProj){ return ( _cacheProj.dbIndex == _changeProject.dbIndex ); } ).toList();
        if( storedProject.isEmpty ) return;

        Project storedChangedProject = storedProject.first;

        bool isChanged(dynamic a, dynamic b){
          if( a != b) isUpdate = true;
          return a != b;
        }

        if( isChanged(storedChangedProject.name, _changeProject.name ) ) storedChangedProject.name  = _changeProject.name;
        if( isChanged(storedChangedProject.downloadName, _changeProject.downloadName ) ) storedChangedProject.downloadName  = _changeProject.downloadName;
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

  final Map<Project, List<FrameImage>> _cachedFrameList = {};

  @override
  Future<List<FrameImage>> getFrameList(Project _proj) async {
    if(!_cachedFrameList.containsKey( _proj )) _cachedFrameList[_proj] = [];

    if(_cachedFrameList[_proj]!.isNotEmpty) return _cachedFrameList[_proj]!;

    FrameImage createFrameModel(DocumentSnapshot _snapDoc, ){
      Map<String, dynamic> snapData = (_snapDoc.data() as Map<String, dynamic>);

      FrameImage addFrameImage = FrameImage(
        dbInstance  : this,
        project     : _proj,
        dbIndex     : _snapDoc.id,
        name        : snapData["name"] ?? "",
        sizeRate    : snapData["size_rate"]  ?? 1.0,
        position    : Point<double>( snapData["position_x"] ?? 0, snapData["position_y"] ?? 0, ),
        angle       : snapData["angle"] ?? 0,
        byteData    : null,
        size        : const Point<double>(0,0),
      );
      return addFrameImage;
    }

    QuerySnapshot frameDocSnapShot = await baseFrameRef(_proj).get();

    for (QueryDocumentSnapshot<Object?> frameDoc in frameDocSnapShot.docs) {
      FrameImage  _addFrame = createFrameModel(frameDoc);

      int frameIndex = _cachedFrameList[_proj]!.indexWhere((_cacheFrame) => _cacheFrame.dbIndex == _addFrame.dbIndex );
      if( frameIndex >= 0 ) continue;

      _cachedFrameList[_proj]!.add(_addFrame);
    }

    if(snapShotList.contains(baseFrameRef(_proj).path)) return _cachedFrameList[_proj]!;
    snapShotList.add(baseFrameRef(_proj).path);

    baseFrameRef(_proj).snapshots().listen((data){
      // if(_cachedProjectList[_loginId]!.isNotEmpty) return _cachedProjectList[_loginId]!;

      bool isUpdate = false;
      for (DocumentChange<Object?> _doc in data.docChanges) {
        FrameImage _changeFrame = createFrameModel(_doc.doc);

        // // 削除
        // if(_doc.type == DocumentChangeType.removed){
          
        //   return;
        // }

        // 追加
        if(_doc.type == DocumentChangeType.added){
          List<FrameImage> storedFrame = _cachedFrameList[_proj]!.where( (_cacheFrame){ return ( _cacheFrame.dbIndex.isEmpty || _cacheFrame.dbIndex == _changeFrame.dbIndex ); } ).toList();
          if(storedFrame.isNotEmpty) return;   // すでにある場合は、なにもしない

          _cachedFrameList[_proj]!.add(_changeFrame);

          isUpdate = true;
          return;
        }        

        // 更新
        List<FrameImage> storedFrame = _cachedFrameList[_proj]!.where( (_cacheFrame){ return ( _cacheFrame.dbIndex == _changeFrame.dbIndex ); } ).toList();
        if( storedFrame.isEmpty ) return;

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

    return _cachedFrameList[_proj]!;
  }

  @override
  Future<String> insertFrame(FrameImage _insertFrame) async {
    _insertFrame.dbIndex = _getUniqueId("frame_" + _insertFrame.name);
    baseFrameRef(_insertFrame.project).doc(_insertFrame.dbIndex).set( _insertFrame.toDbJson() );
    return _insertFrame.dbIndex;
  }

  @override
  Future<void> updateFrame(FrameImage _updateFrame) async {
    if( _updateFrame.dbIndex.isEmpty ) return;

    baseFrameRef(_updateFrame.project).doc(_updateFrame.dbIndex).update( _updateFrame.toDbJson() );
  }
}