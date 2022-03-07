// コマデータ

import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'package:tateyomi_gigarizer/db/db_impl.dart';

class FrameImage{
   late DbImpl dbInstance;
   late String name; // indexを兼ねるので、index変数なし

   late double sizeRate;
   late Point<double> position;

   late Uint8List? byteData;  // こいつは保存しない
   late Point<double> size;          // こいつは保存しない

  FrameImage(
    {
      required this.dbInstance, 
      required this.name, 
      required this.sizeRate, 
      required this.position, 

      required this.byteData, 
      required this.size, 
    }
  );

   Map<String, dynamic> toJson(){
     return {
      'position'    : { "x" : position.x, "y" : position.y },
      'size'        : { "width" : size.x * sizeRate, "height" : size.y * sizeRate },
      'imageSize'   : { "width" : size.x, "height" : size.y },
      'byteData'    : byteData != null ? ("data:image/png;base64," + base64.encode(byteData!)) : "",
    };
   }

  void save(){
    _insertSave();
    _updateSave();
  }

  Future<void> _insertSave() async {
  }

  Future<void> _updateSave() async {
  }

}

