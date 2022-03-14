import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';

class Project{
  late DbImpl dbInstance;
  late String dbIndex;
  late Color targetColor;
  late int posY;

  Project(
      // 保存周りに必要な奴
    this.dbInstance,
    this.dbIndex,

    // 保存変数
    this.targetColor,
    this.posY,
  );

  Map<String, dynamic> toDbJson(){
    return {
      // 'name'            : name,
      // 'download_name'   : downloadName,
      // 'canvas_width'    : canvasSize.width,
      // 'canvas_height'   : canvasSize.height,
      // 'last_open_time'  : lastOpenTime,
      // 'create_time'     : createTime,
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
    // dbInstance.insertProject(this);
  }

  Future<void> _updateSave() async {
    // dbInstance.updateProject(this);
  }

}