// コマデータ

import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

import 'package:tateyomi_gigarizer/db/db_impl.dart';
import 'package:tateyomi_gigarizer/model/common.dart';
import 'package:tateyomi_gigarizer/model/project.dart';

class FrameImage{
  late Project project;
  late DbImpl dbInstance;

  late String dbIndex;
  late String name;

  late double sizeRate;
  late Point<double> position;
  late int angle;

  late Point<double> size;   // こいつは保存しない

  FrameImage(
    {
      // 保存周りに必要な奴
      required this.dbInstance, 
      required this.project, 
      required this.dbIndex, 

      // 保存変数
      required this.name, 
      required this.sizeRate, 
      required this.position, 
      required this.angle, 

      // ファイルから後でわかるやつ
      required this.size, 
    }
  );

  Map<String, dynamic> toDbJson(){
    return {
      'project_id' : project.dbIndex,
      'name'        : name,
      'angle'       : angle,
      'position_x'    : position.x,
      'position_y'    : position.y,
      'size_rate'    : sizeRate,
    };
  }

  Map<String, dynamic> toDownloadJson(Map<String, Uint8List> frameImageBytes){
    return {
      'angle'       : angle,
      'position'    : { "x" : position.x, "y" : position.y },
      'size'        : { "width" : size.x * sizeRate, "height" : size.y * sizeRate },
      'imageSize'   : { "width" : size.x, "height" : size.y },
      'byteData'    : frameImageBytes.containsKey(dbIndex) ? ("data:image/png;base64," + base64.encode(frameImageBytes[dbIndex]!)) : "",
    };
  }

  bool isRotateVertical(){
    return angle.isOdd;
  }

  Point<double> get rotateSize{
    if(isRotateVertical()) return Point<double>(size.y, size.x);

    return size;
  }

  void save(){
    if(!isDeskTop()) return;
    if( dbIndex.isEmpty ){
      insertSave();
      return;
    }
    _updateSave();
  }

  void insertSave() async {
    dbInstance.insertFrame(this);
  }

  void _updateSave() async {
    dbInstance.updateFrame(this);
  }

  void delete(){
    if(!isDeskTop()) return;
    dbInstance.deleteFrame(this);
  }

  void copy(FrameImage copy){
    position = copy.position;
    size = copy.size;
    sizeRate = copy.sizeRate;
    angle = copy.angle;
  }

  FrameImage clone(){
    return FrameImage(
      project   : project,
      dbInstance: dbInstance,
      dbIndex   : dbIndex,
      name      : name,
      angle     : angle,
      position  : position,
      size      : size,
      sizeRate  : sizeRate,
    );
  }

}

