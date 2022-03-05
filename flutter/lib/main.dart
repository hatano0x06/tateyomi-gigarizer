import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
import 'package:tateyomi_gigarizer/page/edit_page.dart';
import 'package:url_strategy/url_strategy.dart';

void main() {
  setPathUrlStrategy();
  runApp(const MyApp());
}

// TODO: 
//  スクロール(消えるようにする)
//  ドラッグ移動の修正
//  キャンパスの拡大縮小
//  フォーカス


// TODO: 縦読みの機能
//  - 背景レイヤー
//  - 21日にモックアップ（連動機能とか、なし
//  - 大コマは90度回転（機能としても出しておく

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: "NotoSansJP",
        scrollbarTheme: ScrollbarThemeData(
          showTrackOnHover: true,
          thumbColor      : MaterialStateProperty.all<Color>(const Color.fromARGB(255, 88, 75, 66)),
        ),
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey,
      ),
      home: EditPage(dbInstance: DbImpl(),),
    );
  }
}
