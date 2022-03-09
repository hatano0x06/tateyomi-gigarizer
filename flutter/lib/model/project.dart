import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';

class Project{
  late DbImpl dbInstance;
  late String dbIndex;
  late String name;
  late String downloadName;
  late Size canvasSize;
  late int lastOpenTime;
  late int createTime;

  Project(
      // 保存周りに必要な奴
    this.dbInstance,
    this.dbIndex,

    // 保存変数
    this.name,
    this.downloadName,
    this.canvasSize,
    this.lastOpenTime,
    this.createTime,
  );

  Map<String, dynamic> toDbJson(){
    return {
      'name'            : name,
      'download_name'   : downloadName,
      'canvas_width'    : canvasSize.width,
      'canvas_height'   : canvasSize.height,
      'last_open_time'  : lastOpenTime,
      'create_time'     : createTime,
    };
  }
  void save(){
    if( dbIndex.isEmpty ){
      _insertSave();
      return;
    }
    _updateSave();
  }

  Future<void> _insertSave() async {
  }

  Future<void> _updateSave() async {
  }

}