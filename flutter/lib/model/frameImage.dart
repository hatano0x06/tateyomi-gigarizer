// コマデータ

class FrameImage{
  //  late DbImplement dbInstance;
  //  late String frameIndex;
  //  late String frameName;
  //  late double sizeRate;
  //  late Point<double> position;
  FrameImage(
    // {
    //   // required this.dbInstance, 
    //   // this.frameIndex = "", 
    //   // this.frameName = "", 

    // }
  );

  void save(){
    _insertSave();
    _updateSave();

  }

  Future<void> _insertSave() async {
  }

  Future<void> _updateSave() async {
  }

}