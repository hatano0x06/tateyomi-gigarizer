// キャンパス

import 'package:tateyomi_gigarizer/db/db_impl.dart';

class TateCanvas{
   late DbImpl dbInstance;
   late String canvasIndex;
  TateCanvas(
    {
      required this.dbInstance, 
      required this.canvasIndex, 
    }
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