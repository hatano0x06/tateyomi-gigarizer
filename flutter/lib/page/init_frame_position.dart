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


// comico設定　https://tips.clip-studio.com/ja-jp/articles/2781#:~:text=%E8%A7%A3%E5%83%8F%E5%BA%A6%E3%81%AF%E5%8D%B0%E5%88%B7%E3%81%AE%E9%9A%9B,%E3%81%99%E3%82%8B%E3%81%93%E3%81%A8%E3%81%8C%E5%A4%9A%E3%81%84%E3%81%A7%E3%81%99%E3%80%82
const double defaultCanvasWidth = 690;

Future<ui.Image> _loadImage(Uint8List _charThumbImg) async {
  final Completer<ui.Image> completer = Completer();

  ui.decodeImageFromList(_charThumbImg, (ui.Image convertedImg) {
    return completer.complete(convertedImg);
  });
  return completer.future;
}

Future<void> initLoadImage(
  List<PlatformFile> files, List<FrameImage> frameImageList, Map<String, Uint8List> frameImageBytes, Map<String, math.Point<double>> frameImageSize, Project project,
  void Function() mainBuild, void Function() allDoneAction
) async {
  List<PlatformFile> fileList = files.where((_file) => _file.extension != null && _file.extension == "png").toList();

  await Future.forEach(fileList, (PlatformFile _file) async {
    Uint8List bytes = Uint8List.fromList(_file.bytes!);
    ui.Image _image = await _loadImage(bytes);

    try{
      FrameImage frameImage = frameImageList.singleWhere((_frameImage) => _frameImage.name == _file.name);

      frameImageBytes[frameImage.dbIndex] = bytes;
      frameImageSize[frameImage.dbIndex] = math.Point(_image.width.toDouble(), _image.height.toDouble());
      frameImage.size = math.Point<double>(_image.width.toDouble(), _image.height.toDouble());
    } catch(e){
      FrameImage newImage = FrameImage(
        dbInstance  : project.dbInstance,
        project     : project,
        dbIndex     : "",
        name        : _file.name,
        angle       : 0,
        sizeRate    : 1.0,
        position    : const math.Point<double>(0,0),
        size        : math.Point(_image.width.toDouble(), _image.height.toDouble())
      );
      newImage.sizeRate = defaultCanvasWidth/newImage.rotateSize.x;
      newImage.size = math.Point<double>(_image.width.toDouble(), _image.height.toDouble());

      frameImageList.add( newImage );

      newImage.save();
      frameImageBytes[newImage.dbIndex] = bytes;
      frameImageSize[newImage.dbIndex] = math.Point<double>(_image.width.toDouble(), _image.height.toDouble());
    }

  });

  allDoneAction();
  mainBuild();
}

void initFramePos(List<PlatformFile> files, List<FrameImage> frameImageList, Project project, void Function() mainBuild){
  for (PlatformFile _file in files.where((_file) => _file.extension != null && _file.extension == "json").toList()) {
    // map作成
    List<List<FramePagePos>> frameStepMap = _createFrameStepMap(_file.bytes as Uint8List, frameImageList);

    double currentHeight  = 225;
    double preFrameHeight = 0;
    bool rightToLeft = false;
    frameStepMap.asMap().forEach((_pageIndex, _frameMap) {
      List<FramePagePos> samePageFrameList = _frameMap;

      _frameMap.asMap().forEach((_frameIndex, currentFramePos) {
        FrameImage targetFrame = currentFramePos.frameImageData;
        // FramePagePos? currentFramePos = frameStepMap[_pageIndex]?[_frameIndex];

        // // コマとして認識できていない場合は、横幅いっぱいのコマにする
        // if( currentFramePos == null ){
        //   rightToLeft = !rightToLeft;
        //   targetFrame.position = math.Point(0, preFrameHeight == 0 ? currentHeight : currentHeight + (targetFrame.rotateSize.y * targetFrame.sizeRate)/3);
        //   targetFrame.sizeRate = defaultCanvasWidth/targetFrame.rotateSize.x;

        //   // 次のコマの高さ
        //   currentHeight = targetFrame.position.y + targetFrame.rotateSize.y * targetFrame.sizeRate;
        //   preFrameHeight = targetFrame.rotateSize.y * targetFrame.sizeRate;
        //   return;
        // }

        List<FramePagePos> sameStepFrameList = samePageFrameList.where((_frameData) => _frameData.step == currentFramePos.step).toList();

        // 波状に配置するので、反転処理
        if( sameStepFrameList.first == currentFramePos ) rightToLeft = !rightToLeft;

        // 前後のコマが別の段落だった場合は、横幅いっぱいのコマ
        if( sameStepFrameList.length == 1){
          targetFrame.position = math.Point(0, preFrameHeight == 0 ? currentHeight : currentHeight + (targetFrame.rotateSize.y * targetFrame.sizeRate)/3);
          targetFrame.sizeRate = defaultCanvasWidth/targetFrame.rotateSize.x;

          // 次のコマの高さ
          currentHeight = targetFrame.position.y + targetFrame.rotateSize.y * targetFrame.sizeRate;
          preFrameHeight = targetFrame.rotateSize.y * targetFrame.sizeRate;
          return;
        }

        double maxWidth = 0.0;
        List<double> widthList = [];
        for (FramePagePos _frame in sameStepFrameList) { widthList.add(_frame.frameImageData.rotateSize.x); maxWidth += _frame.frameImageData.rotateSize.x; }
        widthList.sort();

        double rate = 1/maxWidth * defaultCanvasWidth;

        void wideFramePosition(){
          double xPos = 0.0;
          for (FramePagePos _frame in sameStepFrameList) {
            double resizeWidth = _frame.frameImageData.rotateSize.x * rate;

            // 対象のコマはなにもしない
            if( _frame != currentFramePos ){
              xPos += resizeWidth;
              continue;
            }

            // ちょっとコマがかぶるように大きくする
            double overRateSize = rate * 0.05;
            _frame.frameImageData.sizeRate = rate + overRateSize;

            // 大きくしたときに、キャンパスのサイズを超えてしまった場合は、対応
            if( _frame.frameImageData.rotateSize.x * _frame.frameImageData.sizeRate > defaultCanvasWidth){
              _frame.frameImageData.sizeRate = defaultCanvasWidth/_frame.frameImageData.rotateSize.x;
              overRateSize = _frame.frameImageData.sizeRate - rate;
            }

            // 波状に配置するので、反転処理
            double pos = rightToLeft ? 
              defaultCanvasWidth - xPos - (_frame.frameImageData.rotateSize.x*(rate+overRateSize/2))
              : xPos;

            _frame.frameImageData.position = math.Point( 
              // 画面外にいかない対応
              math.min( math.max(0, pos), defaultCanvasWidth - (_frame.frameImageData.rotateSize.x*(rate+overRateSize)), ),
              preFrameHeight == 0 ? currentHeight : currentHeight + targetFrame.rotateSize.y * targetFrame.sizeRate/4
            );

            // 次のコマの高さ
            currentHeight = targetFrame.position.y + targetFrame.rotateSize.y * targetFrame.sizeRate;
            preFrameHeight = targetFrame.rotateSize.y * targetFrame.sizeRate;
          }
        }

        void normalFramePosition(){
          double xPos = 0.0;
          
          for (FramePagePos _frame in sameStepFrameList) {
            double resizeWidth = _frame.frameImageData.rotateSize.x * rate;

            // 対象のコマはなにもしない
            if( _frame != currentFramePos ){
              xPos += resizeWidth;
              continue;
            }

            // ちょっとコマがかぶるように大きくする
            double overRateSize = rate * 0.05;
            _frame.frameImageData.sizeRate = rate - overRateSize;

            // 波状に配置するので、反転処理
            double pos = rightToLeft ? 
              defaultCanvasWidth - xPos - (_frame.frameImageData.rotateSize.x*(rate-overRateSize/2))
              : xPos;

            if( sameStepFrameList.first == currentFramePos ) pos = rightToLeft ? defaultCanvasWidth : 0;
            if( sameStepFrameList.last == currentFramePos ) pos = rightToLeft ? 0 : defaultCanvasWidth;

            _frame.frameImageData.position = math.Point( 
              // 画面外にいかない対応
              math.min( math.max(0, pos), defaultCanvasWidth - (_frame.frameImageData.rotateSize.x*(rate-overRateSize)), ),
              preFrameHeight == 0 ? currentHeight : (sameStepFrameList.first == currentFramePos ? currentHeight + targetFrame.rotateSize.y * targetFrame.sizeRate/4 : currentHeight - preFrameHeight/2)
            );

            // 次のコマの高さ
            currentHeight = targetFrame.position.y + targetFrame.rotateSize.y * targetFrame.sizeRate;
            preFrameHeight = targetFrame.rotateSize.y * targetFrame.sizeRate;

          }
        }        

        bool haveWideFrame = (widthList.last > widthList[widthList.length-2] * 2.5);
        if( haveWideFrame ){
          wideFramePosition();
          return;
        }

        normalFramePosition();


      });
    });

    // 保存処理
    for (var _frameMap in frameStepMap) {
      for (var _frameStepData in _frameMap) {
        _frameStepData.frameImageData.save();
      }
    }

    project.canvasSize = Size(defaultCanvasWidth, currentHeight + 100);
    project.save();

    mainBuild();
  }
}

List<List<FramePagePos>> _createFrameStepMap(Uint8List _filebyte, List<FrameImage> frameImageList,){
  List<List<FramePagePos>> frameStepMap = [];

  List<dynamic> jsonData = json.decode(utf8.decode(_filebyte)); 
  // List<List<Map<String, dynamic>>> jsonData = json.decode(utf8.decode(_file.bytes!)); 
  // print( jsonData );
  jsonData.asMap().forEach((_pageIndex, _pageValueJson) {
    List<dynamic> _pageJson  = _pageValueJson as List<dynamic>;

    List<FramePagePos> frameList = [];

    // print( "frameNum in Page : $_pageIndex" );
    _pageJson.asMap().forEach((_frameIndex, _frameValuejson) {
      Map<String, dynamic> _framejson  = _frameValuejson as Map<String, dynamic>;
      int frameNum = _framejson["FrameNumber"];

      String _imageTitle(){
        int pageNumCutLength = jsonData.length >= 100 ? -3:-2;
        String fullPageNum = '00000' + (_pageIndex+1).toString();
        String cutPageNum  = fullPageNum.substring(fullPageNum.length+pageNumCutLength);

        int frameNumCutLength = _pageJson.length >= 100 ? -3:-2;
        String fullFrameNum = '00000' + (_frameIndex+1).toString();
        String cutFrameNum  = fullFrameNum.substring(fullFrameNum.length+frameNumCutLength);

        return cutPageNum + "p_" + cutFrameNum + ".png";
      }

      int targetFrameIndex = frameImageList.indexWhere((_frameImage) => _frameImage.name == (_framejson.containsKey("fileName") ? _framejson["fileName"] : _imageTitle()));
      if( targetFrameIndex < 0 ) return;

      frameList.add(
        FramePagePos(
          _framejson["StepData"]["X"],
          _framejson["StepData"]["Y"],
          _framejson["StepData"]["StepNum"],
          frameNum,
          frameImageList[targetFrameIndex]
        )
      );      
    });

    frameStepMap.add(frameList);
  });

  for (List<FramePagePos> _frameList in frameStepMap) {
    _frameList.sort((FramePagePos a, FramePagePos b){
      return a.frameNumber.compareTo(b.frameNumber);
    });
  }

  return frameStepMap;

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


}



class FramePagePos {
  final int x;
  final int y;
  final int step;
  final int frameNumber;
  final FrameImage frameImageData;

  FramePagePos(this.x, this.y, this.step, this.frameNumber, this.frameImageData);

  @override
  String toString() {
    return "framepos: $step $x $y";
  }
}