// コマデータ

import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'package:tateyomi_gigarizer/db/db_impl.dart';
import 'package:tateyomi_gigarizer/model/project.dart';

class FrameImage{
  late Project project;
  late DbImpl dbInstance;

  late String dbIndex;
  late String name;

  late double sizeRate;
  late Point<double> position;
  late int angle;

  late Uint8List? byteData;  // こいつは保存しない
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
      required this.byteData, 
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

  Map<String, dynamic> toDownloadJson(){
    return {
      'angle'       : angle,
      'position'    : { "x" : position.x, "y" : position.y },
      'size'        : { "width" : size.x * sizeRate, "height" : size.y * sizeRate },
      'imageSize'   : { "width" : size.x, "height" : size.y },
      'byteData'    : byteData != null ? ("data:image/png;base64," + base64.encode(byteData!)) : "",
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
    if( dbIndex.isEmpty ){
      _insertSave();
      return;
    }
    _updateSave();
  }

  Future<void> _insertSave() async {
    dbInstance.insertFrame(this);
  }

  Future<void> _updateSave() async {
    dbInstance.updateFrame(this);
  }

}

