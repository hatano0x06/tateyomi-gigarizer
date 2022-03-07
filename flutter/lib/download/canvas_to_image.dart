// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';

import 'package:universal_html/js.dart' as javascript;


class CanvasToImage{
  final List<FrameImage> frameImageList;
  final Size canvasSize;

  CanvasToImage(this.frameImageList, this.canvasSize);

  Future<void> download(String fileName) async {
    List<Map<String, dynamic>> frameImageJsonList = [];
    for (FrameImage _frameImage in frameImageList) {
      if( _frameImage.byteData == null )  continue;
      if(_frameImage.sizeRate <= 0.0)     continue;
      frameImageJsonList.add(_frameImage.toJson());
    }

    javascript.context.callMethod('saveCanvas', [jsonEncode(frameImageJsonList), canvasSize.width, canvasSize.height,  fileName + ".png"]);  
  }
}