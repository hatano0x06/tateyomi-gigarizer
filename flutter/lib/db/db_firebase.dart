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
          int projIndex = _cachedProjectList[baseProjRef().path]!.indexWhere((_cacheProj) => _cacheProj.dbIndex == _changeProject.dbIndex );
          if( projIndex >= 0 ) return;

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

      // TODO : asdf
      if(isUpdate) print(" update widget ");
      // if(isUpdate) reBuildMemolist(isUpdateImage);

      return;
    },);

    return _cachedProjectList[baseProjRef().path]!;
  }

  @override
  Future<String> insertProject(Project _insertProj) async {
    _insertProj.dbIndex = _getUniqueId(_insertProj.name);
    baseProjRef().doc(_insertProj.dbIndex).set( _insertProj.toDbJson() );
    return _insertProj.dbIndex;
  }

  @override
  Future<void> updateProject(Project _updateProj) async {
    if( _updateProj.dbIndex.isEmpty ) return;

    baseProjRef().doc(_updateProj.dbIndex).update( _updateProj.toDbJson() );
  }

  @override
  Future<List<FrameImage>> getFrameList(Project _proj) async {
    return [
      FrameImage(
        dbIndex     : "aaaa",
        project     : _proj,
        dbInstance  : this,
        name        : "01p_01.png",
        angle       : 0,
        sizeRate    : 1.0,
        position    : const Point<double>(0,0),
        size        : const Point(200,200),
        byteData    : null, 
      ),
      FrameImage(
        dbIndex     : "aaaa",
        project     : _proj,
        dbInstance  : this,
        name        : "01p_02.png",
        angle       : 1,
        sizeRate    : 1.0,
        position    : const Point<double>(100,100),
        size        : const Point(200,200),
        byteData    : null, 
      ),

    ];
  }

  @override
  Future<String> insertFrame(FrameImage _insertFrame) async {
    _insertFrame.dbIndex = DateTime.now().millisecondsSinceEpoch.toString() + "_frame";
    return _insertFrame.dbIndex;
  }

  @override
  Future<void> updateFrame(FrameImage _updateFrame) async { }
}