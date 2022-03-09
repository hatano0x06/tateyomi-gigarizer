import 'package:flutter/material.dart';

class Project{
  late String dbIndex;
  late String name;
  late Size canvasSize;
  late int lastOpenTime;
  late int createTime;

  Project(
    this.dbIndex,
    this.name,
    this.canvasSize,
    this.lastOpenTime,
    this.createTime,
  );

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