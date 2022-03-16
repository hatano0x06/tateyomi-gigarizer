// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/model/background_color_change.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';
import 'package:tateyomi_gigarizer/model/project.dart';

// ignore: unnecessary_import
import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:math' as math;

class CanvasToImage{
  final Project project;
  final List<FrameImage> frameImageList;
  final List<BackGroundColorChange> backgroundColorList;

  CanvasToImage(this.project, this.frameImageList, this.backgroundColorList, );

  final List<double> outputPixelList = [690];

  List<double> createOutputList(){
    List<double> outputList = outputPixelList.toList();
    if(outputList.contains(project.canvasSize.width)) return outputList;
    outputList.add(project.canvasSize.width);

    return outputList;
  }

  Future<void> download(String fileName) async {

  }

  Future<Map<double, Uint8List>> canvasImageList() async {

    Map<double, Uint8List> resultList = {};

    List<double> outputWidthList = createOutputList();
    await Future.forEach(outputWidthList.toList(), (double _canvasWidth) async {
      Uint8List? _image = await _saveRelationMapUnit(_canvasWidth);
      if( _image == null ) return;

      resultList[_canvasWidth] = _image;
    });

    return resultList;
  }

  Future<Uint8List?> _saveRelationMapUnit(double canvasWidth) async {
    double rate = canvasWidth/project.canvasSize.width;
    Size canvasSize = Size( canvasWidth, project.canvasSize.height * rate );
    
    // 下準備
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints( 
        Offset.zero, 
        Offset(canvasSize.width, canvasSize.height)
      )
    );

    // 背景色
    canvas.drawRect( 
      Rect.fromPoints(Offset.zero, Offset(canvasSize.width, canvasSize.height)), 
      Paint()..color = Colors.white..style = PaintingStyle.fill
    );

    _writeBackGroundColor(canvas, canvasSize, rate, backgroundColorList);
    await _writeFrameImage(canvas, canvasSize, rate, frameImageList);

    // 保存
    try{
      final picture = recorder.endRecording();
      final ui.Image img = await picture.toImage(canvasSize.width.toInt(), canvasSize.height.toInt());
      final ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      return Uint8List.view(pngBytes!.buffer);
    // ignore: empty_catches
    } catch(e){
    }

    return null;
  }

  void _writeBackGroundColor(Canvas canvas, Size canvasSize, double rate, List<BackGroundColorChange> backgroundColorList){

    double offsetSize = 1;
    // 一番最初
    if( backgroundColorList.isNotEmpty ) {

      // 先頭のグラデーションまでの色埋め
      if( backgroundColorList.first.pos >= 0 ){
        canvas.drawRect( 
          Rect.fromPoints(Offset.zero, Offset(canvasSize.width, math.max(0, backgroundColorList.first.pos * rate + offsetSize))), 
          Paint()..color = Colors.white..style = PaintingStyle.fill
        );
      }

      // 一番後ろグラデーション以降の色埋め
      if( canvasSize.height - (backgroundColorList.last.pos + backgroundColorList.last.size)* rate >= 0 ){
        canvas.drawRect( 
          Rect.fromPoints(
            Offset(0, (backgroundColorList.last.pos + backgroundColorList.last.size)* rate - offsetSize ), 
            Offset(canvasSize.width, canvasSize.height),
          ), 
          Paint()..color = backgroundColorList.last.targetColor..style = PaintingStyle.fill
        );
      }
    }


    // グラデーション間の穴埋め
    for (BackGroundColorChange _background in backgroundColorList) {
      int backGroundIndex = backgroundColorList.indexOf(_background);
      if( backGroundIndex == 0 ) continue;
      
      BackGroundColorChange preBackGround = backgroundColorList[backGroundIndex-1];

      canvas.drawRect( 
        Rect.fromPoints(
          Offset(0, (preBackGround.pos + preBackGround.size)* rate - offsetSize ), 
          Offset(canvasSize.width, _background.pos*rate + offsetSize),
        ), 
        Paint()..color = preBackGround.targetColor..style = PaintingStyle.fill
      );
    }

    // グラデーション
    for (BackGroundColorChange _background in backgroundColorList) {
      int backGroundIndex = backgroundColorList.indexOf(_background);
      Color preColor = (backGroundIndex == 0 ? Colors.white : backgroundColorList[backGroundIndex-1].targetColor);

      Rect _rect = Rect.fromLTWH(
        0, _background.pos * rate, 
        canvasSize.width, _background.size * rate
      );

      final paint = Paint()
        ..shader = LinearGradient(
          begin : Alignment.topCenter,
          end   : Alignment.bottomCenter,
          colors: [ preColor, _background.targetColor, ],
        ).createShader(_rect);

      canvas.drawRect( _rect, paint );
    }

  }

  Future<void> _writeFrameImage(Canvas canvas, Size canvasSize, double rate, List<FrameImage> frameImageList) async {
    // 画像の描画
    await Future.forEach(frameImageList.toList(), (FrameImage _frameData) async {
      if( _frameData.byteData == null ) return;
      if( _frameData.sizeRate <= 0 ) return;

      ui.Image _image = await _loadImage(_frameData.byteData!);
      Rect srcRect = Rect.fromLTWH( 0, 0, _image.width.toDouble(), _image.height.toDouble() );
      Rect dstRect = Rect.fromLTWH(
        _frameData.position.x, _frameData.position.y, 
        _frameData.size.x * _frameData.sizeRate, 
        _frameData.size.y * _frameData.sizeRate
      );

      // TODO: rotate
      final paint = Paint()..style = PaintingStyle.fill..filterQuality = FilterQuality.high;
      canvas.drawImageRect(_image, srcRect, dstRect, paint);
    });
  }

  Future<ui.Image> _loadImage(Uint8List _imageBytes) async {
    final Completer<ui.Image> completer = Completer();

    ui.decodeImageFromList(_imageBytes, (ui.Image convertedImg) {
      return completer.complete(convertedImg);
    });
    return completer.future;
  }
    
}