
// コマデータ
import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/model/project.dart';

class DbImpl{
  String loginId = "";

  Future<List<Project>> getProjectList() async {
    return [
      Project(
        this, "aaa", "test1", "test1", const Size(200, 200), DateTime.now().millisecondsSinceEpoch, DateTime.now().millisecondsSinceEpoch
      ),
      Project(
        this, "bbb", "test2", "test1", const Size(300, 300), DateTime.now().millisecondsSinceEpoch, DateTime.now().millisecondsSinceEpoch
      ),
      Project(
        this, "aaa", "test1", "test1", const Size(200, 200), DateTime.now().millisecondsSinceEpoch, DateTime.now().millisecondsSinceEpoch
      ),

    ];
  }

}