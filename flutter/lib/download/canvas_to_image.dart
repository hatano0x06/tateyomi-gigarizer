import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';
import 'dart:ui' as ui;

import 'package:universal_html/js.dart' as javascript;


class CanvasToImage{
  final List<FrameImage> frameImageList;
  final Size canvasSize;

  CanvasToImage(this.frameImageList, this.canvasSize);

  Future<void> download(String fileName) async {
    saveRelationMapUnit().then((_imageBytes){
      javascript.context.callMethod('saveCanvas', [_imageBytes, fileName + ".png"]);  
    });
  }

  Future<Uint8List?> saveRelationMapUnit() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints( 
        Offset.zero, 
        Offset(canvasSize.width, canvasSize.height)
      )
    );

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

      final paint = Paint()..style = PaintingStyle.fill..filterQuality = FilterQuality.high;
      canvas.drawImageRect(_image, srcRect, dstRect, paint);
    });

    try{
      final picture = recorder.endRecording();
      final ui.Image img = await picture.toImage(canvasSize.width.toInt(), canvasSize.height.toInt());
      final ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      return Uint8List.view(pngBytes!.buffer);
    } catch(e){
    }

    return null;


  }

  Future<ui.Image> _loadImage(Uint8List _imageBytes) async {
    final Completer<ui.Image> completer = Completer();

    ui.decodeImageFromList(_imageBytes, (ui.Image convertedImg) {
      return completer.complete(convertedImg);
    });
    return completer.future;
  }


}