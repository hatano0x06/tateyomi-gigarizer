// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:tateyomi_gigarizer/model/frame_image.dart';
import 'package:tateyomi_gigarizer/model/project.dart';
import 'dart:convert';


Future<void> initLoadImage(List<PlatformFile> files, List<FrameImage> frameImageList, Map<String, Uint8List> frameImageBytes, Project project) async {
  await Future.forEach(files.where((_file) => _file.extension != null && _file.extension == "png").toList(), (PlatformFile _file) async {
    if(_file.bytes == null) return;

    Future<ui.Image> _loadImage(Uint8List _charThumbImg) async {
      final Completer<ui.Image> completer = Completer();

      ui.decodeImageFromList(_charThumbImg, (ui.Image convertedImg) {
        return completer.complete(convertedImg);
      });
      return completer.future;
    }
                
    ui.Image _image = await _loadImage(_file.bytes!);

    try{
      FrameImage frameImage = frameImageList.singleWhere((_frameImage) => _frameImage.name == _file.name);
      frameImageBytes[frameImage.dbIndex] = _file.bytes!;
      frameImage.size = math.Point(_image.width.toDouble(), _image.height.toDouble());
    } catch(e){
      FrameImage newImage = FrameImage(
        dbInstance  : project.dbInstance,
        project     : project,
        dbIndex     : "",
        byteData    : null, 
        name        : _file.name,
        angle       : 0,
        sizeRate    : 1.0,
        position    : const math.Point<double>(0,0),
        size        : math.Point(_image.width.toDouble(), _image.height.toDouble())
      );
      newImage.save();
      frameImageBytes[newImage.dbIndex] = _file.bytes!;

      frameImageList.add( newImage );
    }
  });
  
}

void initFramePos(List<PlatformFile> files, List<FrameImage> frameImageList, Project project){
  for (PlatformFile _file in files.where((_file) => _file.extension != null && _file.extension == "json").toList()) {
    if(_file.bytes == null) continue;

    // map作成
    Map<int, Map<int, FramePagePos>> frameStepMap = {};

    List<dynamic> jsonData = json.decode(utf8.decode(_file.bytes!)); 
    // List<List<Map<String, dynamic>>> jsonData = json.decode(utf8.decode(_file.bytes!)); 
    // print( jsonData );
    jsonData.asMap().forEach((_pageIndex, _pageValueJson) {
      if( !frameStepMap.containsKey(_pageIndex) ) frameStepMap[_pageIndex] = {};

      List<dynamic> _pageJson  = _pageValueJson as List<dynamic>;

      // print( "frameNum in Page : $_pageIndex" );
      _pageJson.asMap().forEach((_frameIndex, _frameValuejson) {
        Map<String, dynamic> _framejson  = _frameValuejson as Map<String, dynamic>;
        int frameNum = _framejson["FrameNumber"];

        // {SpeakBlockList: [], Cornermath.Points: [{X: 0, Y: 0}, {X: 502, Y: 0}, {X: 505, Y: 259}, {X: 0, Y: 259}], FrameNumber: 0, StepData: {X: 0, Y: 0, StepNum: 0}}
        // print(_framejson);

        frameStepMap[_pageIndex]![frameNum] = FramePagePos(
          _framejson["StepData"]["X"],
          _framejson["StepData"]["Y"],
          _framejson["StepData"]["StepNum"],
        );

      });
    });

    // print( frameStepMap.toString() );

    /*
    {
      0: {
        0: {x: 0, y: 0, step: 0}, 
        1: {x: 0, y: 0, step: 1}, 
        2: {x: 0, y: 0, step: 2}, 
        3: {x: 1, y: 0, step: 2}, 
        4: {x: 2, y: 0, step: 2}
      }, 
      1: {
        0: {x: 0, y: 0, step: 0}, 
        1: {x: 0, y: 0, step: 1}, 
        2: {x: 1, y: 0, step: 1}, 
        3: {x: 0, y: 0, step: 2}, 
        4: {x: 1, y: 0, step: 2}, 
        5: {x: 2, y: 0, step: 2}
      }
    }
    */

    // comico設定　https://tips.clip-studio.com/ja-jp/articles/2781#:~:text=%E8%A7%A3%E5%83%8F%E5%BA%A6%E3%81%AF%E5%8D%B0%E5%88%B7%E3%81%AE%E9%9A%9B,%E3%81%99%E3%82%8B%E3%81%93%E3%81%A8%E3%81%8C%E5%A4%9A%E3%81%84%E3%81%A7%E3%81%99%E3%80%82
    const double defaultCanvasWidth = 690;

    // TODO: 真ん中になるように調整
    double currentHeight = 100;
    frameStepMap.forEach((_pageIndex, _frameMap) {
      print(" -- page $_pageIndex ");
      _frameMap.forEach((_frameIndex, _frameStepData) {
        String _imageTitle(){
          int pageNumCutLength = frameStepMap.length >= 100 ? -3:-2;
          String fullPageNum = '00000' + (_pageIndex+1).toString();
          String cutPageNum  = fullPageNum.substring(fullPageNum.length+pageNumCutLength);

          int frameNumCutLength = _frameMap.length >= 100 ? -3:-2;
          String fullFrameNum = '00000' + (_frameIndex+1).toString();
          String cutFrameNum  = fullFrameNum.substring(fullFrameNum.length+frameNumCutLength);

          return cutPageNum + "p_" + cutFrameNum + ".png";
        }

        // すでにwebに設定済みのデータがある（読み込み済み）なら、なにもせずに終了
        int targetFrameIndex = frameImageList.indexWhere((_frameImage) => _frameImage.name == _imageTitle());
        if( targetFrameIndex < 0 ) return;

        FrameImage targetFrame = frameImageList[targetFrameIndex];

        // TODO: 配置に関してはこいつを良い感じにする
        void setFrameInitPos(){
          math.Point<double> calcPosition(){

            FramePagePos? preFramePos = frameStepMap[_pageIndex]?[_frameIndex-1];
            FramePagePos? currentFramePos = frameStepMap[_pageIndex]?[_frameIndex];

            // ignore: prefer_const_constructors
            return math.Point(0, currentHeight);
          }

          targetFrame.position = calcPosition();

          currentHeight = currentHeight + 100;
        }

        setFrameInitPos();

        // 枠を超えていた場合は、rateで枠内に収まるようにする
        if( targetFrame.rotateSize.x > defaultCanvasWidth ) targetFrame.sizeRate = targetFrame.rotateSize.x/defaultCanvasWidth;

        targetFrame.save();

        currentHeight = targetFrame.position.y + targetFrame.rotateSize.y * targetFrame.sizeRate;
      });
    });

    project.canvasSize = Size(defaultCanvasWidth, currentHeight + 100);
    project.save();

    //  ないなら、ファイルを作って保存処理＋自然配置
    continue;
  }
}

class FramePagePos {
  final int x;
  final int y;
  final int step;

  FramePagePos(this.x, this.y, this.step);

  @override
  String toString() {
    return "framepos: $step $x $y";
  }
}