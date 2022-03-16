// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:esys_flutter_share_plus/esys_flutter_share_plus.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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

  Future<void> download() async {
    Map<double, Uint8List> outputMap = await canvasImageList();
    if( outputMap.isEmpty ) return;

    // 一枚ならそのままダウンロード
    if( outputMap.length == 1){
      double pixelSize = outputMap.keys.first;
      Uint8List file = outputMap[pixelSize]!;
      Share.file( project.name + "_" + pixelSize.toInt().toString() +"px", project.name, file, 'image/png', );
      return;
    }

    Directory tempDirectory = await getTemporaryDirectory();
    ZipFileEncoder zipEncoder = ZipFileEncoder();
    zipEncoder.create(tempDirectory.path + "/" + project.name + '.zip');
    // outputMap.forEach((pixelWidth, fileBytes) {
    await Future.forEach(outputMap.keys.toList(), (double pixelWidth) async {
      Uint8List fileBytes = outputMap[pixelWidth]!;

      File file = File(tempDirectory.path + "/" + pixelWidth.toInt().toString() + ".png");
      await file.writeAsBytes(fileBytes);
      zipEncoder.addFile(file);
    });
    zipEncoder.close();

    Share.file( project.name, project.name, File(tempDirectory.path + "/" + project.name + '.zip').readAsBytesSync(), 'application/zip', );
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

      Offset startPosOffset = Offset.zero;
      if( _frameData.angle == 1) startPosOffset = Offset( _frameData.size.y, 0);
      if( _frameData.angle == 2) startPosOffset = Offset( _frameData.size.x, _frameData.size.y);
      if( _frameData.angle == 3) startPosOffset = Offset( 0, _frameData.size.x);

      canvas.save();
      canvas.translate(_frameData.position.x + startPosOffset.dx, _frameData.position.y + startPosOffset.dy);
      canvas.rotate(_frameData.angle * math.pi/2);
      Rect srcRect = Rect.fromLTWH( 0, 0, _image.width.toDouble(), _image.height.toDouble() );
      Rect dstRect = Rect.fromLTWH( 0 , 0, _frameData.size.x * _frameData.sizeRate,  _frameData.size.y * _frameData.sizeRate );
      canvas.drawImageRect(_image, srcRect, dstRect, Paint()..style = PaintingStyle.fill..filterQuality = FilterQuality.high);
      canvas.restore();
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