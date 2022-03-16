import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
import 'package:tateyomi_gigarizer/model/common.dart';
import 'package:tateyomi_gigarizer/model/project.dart';

class BackGroundColorChange{
  late DbImpl dbInstance;
  late Project project;
  late String dbIndex;
  late Color targetColor;
  late double pos;
  late double size;

  BackGroundColorChange(
      // 保存周りに必要な奴
    this.dbInstance,
    this.project, 
    this.dbIndex,

    // 保存変数
    this.targetColor,
    this.pos,
    this.size,
  );

  Map<String, dynamic> toDbJson(){
    return {
      'project_id' : project.dbIndex,
      'color' : targetColor.value,
      'pos'   : pos,
      'size'  : size,
    };
  }

  void save(){
    if(!isDeskTop()) return;
    if( dbIndex.isEmpty ){
      _insertSave();
      return;
    }
    _updateSave();
  }

  Future<void> _insertSave() async {
    dbInstance.insertBackGroundColor(this);
  }
  Future<void> _updateSave() async {
    dbInstance.updateBackGroundColor(this);
  }
  void delete(){
    if(!isDeskTop()) return;
    dbInstance.deleteBackGroundColor(this);
  }

}