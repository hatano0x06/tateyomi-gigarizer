
// ignore_for_file: dead_code

// コマデータ
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/model/background_color_change.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';
import 'package:tateyomi_gigarizer/model/project.dart';

class DbImpl{
  static String _loginId = "";

  String get loginId{ return _loginId; }
  set loginId(_text){ _loginId = _text; }

  void Function()? reBuildCanvasBody;
  void reBuildCanvas(){
    if( reBuildCanvasBody == null) return;

    reBuildCanvasBody!();
  }

  Future<List<Project>> getProjectList() async {
    return [
      Project(
        this, "aaa", "test1", const Size(1000, 5000), DateTime.now().millisecondsSinceEpoch, DateTime.now().millisecondsSinceEpoch
      ),
    ];
  }
  Future<String> insertProject(Project _insertProj) async {
    _insertProj.dbIndex = DateTime.now().millisecondsSinceEpoch.toString() + "_proj";
    return _insertProj.dbIndex;
  }
  Future<void> updateProject(Project _updateProj) async { }



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
        dbIndex     : "bbbb",
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
  String insertFrame(FrameImage _insertFrame) {
    if( _insertFrame.dbIndex.isNotEmpty ) return _insertFrame.dbIndex;
    _insertFrame.dbIndex = DateTime.now().millisecondsSinceEpoch.toString() + "_frame_" + _insertFrame.name;
    return _insertFrame.dbIndex;
  }

  Future<void> updateFrame(FrameImage _updateFrame) async { }
  Future<void> deleteFrame(FrameImage _deleteFrame) async { }


  Future<List<BackGroundColorChange>> getBackGroundColorList(Project proj) async {
    return [
      BackGroundColorChange(this, proj, "back1", Colors.black, 200, 200, ),
      // BackGroundColorChange(this, proj, "back2", Colors.blue , 500, 100, ),
    ];
  }
  Future<String> insertBackGroundColor(BackGroundColorChange _insertBackGround) async {
    if( _insertBackGround.dbIndex.isNotEmpty ) return _insertBackGround.dbIndex;

    _insertBackGround.dbIndex = DateTime.now().millisecondsSinceEpoch.toString() + "_proj";
    return _insertBackGround.dbIndex;
  }
  Future<void> updateBackGroundColor(BackGroundColorChange _updateBackGround) async { }
  Future<void> deleteBackGroundColor(BackGroundColorChange _deleteBackGround) async { }

  bool get isTest{ return true; }
}