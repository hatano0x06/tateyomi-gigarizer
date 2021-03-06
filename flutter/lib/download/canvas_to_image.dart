// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:esys_flutter_share_plus/esys_flutter_share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tateyomi_gigarizer/model/background_color_change.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';
import 'package:tateyomi_gigarizer/model/project.dart';

// ignore: unnecessary_import
import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:universal_html/js.dart' as javascript;
import "package:universal_html/html.dart" as html;

class CanvasToImage{
  final Project project;
  final List<FrameImage> frameImageList;
  final List<BackGroundColorChange> backgroundColorList;
  final Map<String, Uint8List> frameImageBytes;
  final List<double> outputPixelList;

  CanvasToImage(this.project, this.frameImageList, this.backgroundColorList, this.frameImageBytes, this.outputPixelList);

  Future<void> download() async {
    Map<double, Uint8List> outputMap = await canvasImageList();
    saveFile(outputMap);

  }

  void saveFile(Map<double, Uint8List> outputMap) async {
    if( outputMap.isEmpty ) return;

    DateTime currentDate = DateTime.now();

    String fillByZero(int value){
      String magicPassCode = ("00" + value.toString());
      return magicPassCode.substring(magicPassCode.toString().length-2);
    }
    Map<String, dynamic> createMap(double _canvasWidth, Uint8List canvasData){
      double rate = _canvasWidth/project.canvasSize.width;
      Size canvasSize = Size( _canvasWidth, project.canvasSize.height * rate );
      
      return {
        "width" : canvasSize.width,
        "height" : canvasSize.height,
        "base64" : "data:image/png;base64," + base64.encode(canvasData),
        "fileName" : _canvasWidth.toInt().toString() + ".png",
      };
    }

    String dateTime = "${currentDate.year}-${fillByZero(currentDate.month)}-${fillByZero(currentDate.day)}_${fillByZero(currentDate.hour)}:${fillByZero(currentDate.minute)}:${currentDate.second}";

    if( kIsWeb ){
      if( outputMap.length == 1){

        Map<String, dynamic> downloadMap = createMap(outputMap.keys.first, outputMap.values.first);
        downloadMap["fileName"] = project.name + "_" + dateTime + "_" + outputMap.keys.first.toInt().toString() +"px";
        javascript.context.callMethod('saveMonoCanvas', [jsonEncode(downloadMap)]);  

        return;
      }

      List<Map> jsonList = [];
      outputMap.forEach((_pixelWidth, _imageData) {
        jsonList.add(createMap(_pixelWidth, _imageData));
      });

      javascript.context.callMethod('saveCanvas', [jsonEncode(jsonList), project.name+"_" + dateTime + ".zip"]);  
      return;
    }

    // ??????????????????????????????????????????
    if( outputMap.length == 1){
      double pixelSize = outputMap.keys.first;
      Uint8List file = outputMap[pixelSize]!;
      Share.file( project.name + "_" + dateTime + "_" + pixelSize.toInt().toString() +"px", project.name, file, 'image/png', );
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

    Share.file( project.name, project.name+"_" + dateTime + ".zip", File(tempDirectory.path + "/" + project.name + '.zip').readAsBytesSync(), 'application/zip', );

  }

  Future<Map<double, Uint8List>> canvasImageList() async {

    Map<double, Uint8List> resultList = {};

    await Future.forEach(outputPixelList.toList(), (double _canvasWidth) async {
      Uint8List? _image = await _saveRelationMapUnit(_canvasWidth);
      if( _image == null ) return;

      resultList[_canvasWidth] = _image;
    });

    return resultList;
  }

  Future<Uint8List?> _saveRelationMapUnit(double canvasWidth) async {
    double rate = canvasWidth/project.canvasSize.width;
    Size canvasSize = Size( canvasWidth, project.canvasSize.height * rate );
    
    // ?????????
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints( 
        Offset.zero, 
        Offset(canvasSize.width, canvasSize.height)
      )
    );

    // ?????????
    canvas.drawRect( 
      Rect.fromPoints(Offset.zero, Offset(canvasSize.width, canvasSize.height)), 
      Paint()..color = Colors.white..style = PaintingStyle.fill
    );

    _writeBackGroundColor(canvas, canvasSize, rate, backgroundColorList);
    await _writeFrameImage(canvas, canvasSize, rate, frameImageList, frameImageBytes);

    // ??????
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
    // ????????????
    if( backgroundColorList.isNotEmpty ) {

      // ????????????????????????????????????????????????
      if( backgroundColorList.first.pos >= 0 ){
        canvas.drawRect( 
          Rect.fromPoints(Offset.zero, Offset(canvasSize.width, math.max(0, backgroundColorList.first.pos * rate + offsetSize))), 
          Paint()..color = Colors.white..style = PaintingStyle.fill
        );
      }

      // ???????????????????????????????????????????????????
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


    // ????????????????????????????????????
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

    // ?????????????????????
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

  Future<void> _writeFrameImage(Canvas canvas, Size canvasSize, double rate, List<FrameImage> frameImageList, Map<String, Uint8List> frameImageBytes) async {
    // ???????????????
    await Future.forEach(frameImageList.toList(), (FrameImage _frameData) async {
      if( !frameImageBytes.containsKey(_frameData.dbIndex)) return;
      if( _frameData.sizeRate <= 0 ) return;

      String jpg64 = base64Encode(frameImageBytes[_frameData.dbIndex]!);
      html.ImageElement myImageElement = html.ImageElement();
      myImageElement.src = 'data:png;base64,$jpg64';

      await myImageElement.onLoad.first; // allow time for browser to render

      int width = math.min(1200, (_frameData.size.x * _frameData.sizeRate * rate).toInt());
      int height = (width * myImageElement.height! / myImageElement.width!).round();

      html.CanvasElement myCanvas = html.CanvasElement(width: width, height: height);
      html.CanvasRenderingContext2D ctx = myCanvas.context2D;

      ctx.drawImageScaled(myImageElement, 0, 0, width, height);

      Future<Uint8List> _getBlobData(html.Blob blob) {
        final completer = Completer<Uint8List>();
        final reader = html.FileReader();
        reader.readAsArrayBuffer(blob);
        reader.onLoad.listen((_) => completer.complete(reader.result as Uint8List));
        return completer.future;
      }

      Uint8List _imageUint8List = await _getBlobData(await myCanvas.toBlob("png"));

      ui.Image _image = await _loadImage(_imageUint8List);

      Offset startPosOffset = Offset.zero;
      if( _frameData.angle == 1) startPosOffset = Offset( _frameData.size.y, 0);
      if( _frameData.angle == 2) startPosOffset = Offset( _frameData.size.x, _frameData.size.y);
      if( _frameData.angle == 3) startPosOffset = Offset( 0, _frameData.size.x);

      canvas.save();

      canvas.translate((_frameData.position.x + startPosOffset.dx) * rate, (_frameData.position.y + startPosOffset.dy) * rate);
      canvas.rotate(_frameData.angle * math.pi/2);

      Rect srcRect = Rect.fromLTWH( 0, 0, _image.width.toDouble(), _image.height.toDouble() );
      Rect dstRect = Rect.fromLTWH( 0 , 0, _frameData.size.x * _frameData.sizeRate * rate,  _frameData.size.y * _frameData.sizeRate * rate );
      canvas.drawImageRect(_image, srcRect, dstRect, Paint()..style = PaintingStyle.fill..filterQuality = FilterQuality.high);

      canvas.restore();
    });
  }

  Future<ui.Image> _loadImage(Uint8List _imageBytes) async {
    return await decodeImageFromList(_imageBytes);
  }
    
}