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
  Future<List<Project>> getProjectList() async {
    return [
      Project(
        this, "aaa", "test1", "test1", const Size(200, 200), DateTime.now().millisecondsSinceEpoch, DateTime.now().millisecondsSinceEpoch
      ),
      Project(
        this, "bbb", "test2", "test1", const Size(300, 300), DateTime.now().millisecondsSinceEpoch, DateTime.now().millisecondsSinceEpoch
      ),
      Project(
        this, "asdf", "test1", "test1", const Size(200, 200), DateTime.now().millisecondsSinceEpoch, DateTime.now().millisecondsSinceEpoch
      ),

    ];
  }

  @override
  Future<String> insertProject(Project _insertProj) async {
    _insertProj.dbIndex = DateTime.now().millisecondsSinceEpoch.toString() + "_proj";
    return _insertProj.dbIndex;
  }

  @override
  Future<void> updateProject(Project _updateProj) async { }


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