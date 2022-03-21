
// import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tateyomi_gigarizer/download/canvas_to_image.dart';
import 'package:tateyomi_gigarizer/model/background_color_change.dart';
import 'package:tateyomi_gigarizer/model/frame_image.dart';
import 'package:tateyomi_gigarizer/model/project.dart';

class DownloadViewerBoard extends StatefulWidget {
  final Project project;
  final List<FrameImage> frameImageList;
  final List<BackGroundColorChange> backgroundColorList;
  final Map<String, Uint8List> frameImageBytes;


  const DownloadViewerBoard({
    Key? key,
    required this.project, 
    required this.frameImageList, 
    required this.backgroundColorList, 
    required this.frameImageBytes, 
  }):super(key:key);
  
  @override
  _DownloadViewerBoardState createState() => _DownloadViewerBoardState();
}

class _DownloadViewerBoardState extends State<DownloadViewerBoard> {

  Uint8List? showByteImage;

  @override
  void initState(){
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      Map<double, Uint8List> imageMap = await CanvasToImage(widget.project, widget.frameImageList, widget.backgroundColorList, widget.frameImageBytes).canvasImageList();
      if( imageMap.isEmpty ) return;

      showByteImage = imageMap[imageMap.keys.first];
      setState(() { });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: const Text( "asdfasdfdsa", ), ),

      body: Center(child: Center(child: body() )),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.repeat),
        onPressed: () async {
          Map<double, Uint8List> imageMap = await CanvasToImage(widget.project, widget.frameImageList, widget.backgroundColorList, widget.frameImageBytes).canvasImageList();
          if( imageMap.isEmpty ) return;

          showByteImage = imageMap[imageMap.keys.first];
          setState(() { });

        },
      ),
    );
  }

  Widget body(){
    if(showByteImage == null) return const Text("loading");

    Image showImage = Image.memory(
      showByteImage!,
      width   : MediaQuery.of(context).size.width,
      height  : MediaQuery.of(context).size.height,
      filterQuality: FilterQuality.high,
      fit: BoxFit.contain,
    );

    return Container( child: showImage, );
  }

}