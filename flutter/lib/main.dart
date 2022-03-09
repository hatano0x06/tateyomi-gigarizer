import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
import 'package:tateyomi_gigarizer/page/login_page.dart';
import 'package:url_strategy/url_strategy.dart';

void main() {
  setPathUrlStrategy();
  runApp(const MyApp());
}

// TODO: 縦読みの機能（２１日まで
//  - firebase連携
//  - スマホ連携
//  - firebase反映

// TODO: オプション
//  - 配置を良い感じにする
//  - 背景レイヤー
//  - 横に全体像が見れるやつ
//  - クラッシュログ

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
        primaryColor: Colors.white,
        scaffoldBackgroundColor   : Colors.grey,
        scrollbarTheme: ScrollbarThemeData(
          showTrackOnHover: true,
          thumbColor      : MaterialStateProperty.all<Color>(const Color.fromARGB(255, 88, 75, 66)),
        ),
        primarySwatch: Colors.blue,
      ),
      home: LoginPageWidget(dbInstance: DbImpl(),),
    );
  }
}
