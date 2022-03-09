
// コマデータ
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';
import 'package:tateyomi_gigarizer/model/project.dart';

class DbImpl{
  String loginId = "";

  Future<List<Project>> getProjectList() async {
    return [
      Project(
        this, "aaa", "test1", "test1", const Size(200, 200), DateTime.now().millisecondsSinceEpoch, DateTime.now().millisecondsSinceEpoch
      ),
      Project(
        this, "bbb", "test2", "test1", const Size(300, 300), DateTime.now().millisecondsSinceEpoch, DateTime.now().millisecondsSinceEpoch
      ),
      Project(
        this, "aaa", "test1", "test1", const Size(200, 200), DateTime.now().millisecondsSinceEpoch, DateTime.now().millisecondsSinceEpoch
      ),

    ];
  }
  Future<String> insertProject(Project _insertProj) async {
    _insertProj.dbIndex = DateTime.now().millisecondsSinceEpoch.toString() + "_proj";
    return _insertProj.dbIndex;
  }
  Future<void> updateProject(Project _updateProj) async { }



  Future<List<FrameImage>> getFrameList(Project _proj) async {
    return [];
    
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
  Future<String> insertFrame(FrameImage _insertFrame) async {
    _insertFrame.dbIndex = DateTime.now().millisecondsSinceEpoch.toString() + "_frame";
    return _insertFrame.dbIndex;
  }

  Future<void> updateFrame(FrameImage _updateFrame) async { }
}