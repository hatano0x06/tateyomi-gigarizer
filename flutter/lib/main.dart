import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:tateyomi_gigarizer/db/db_firebase.dart';
// ignore: unused_import
import 'package:tateyomi_gigarizer/db/db_impl.dart';
import 'package:tateyomi_gigarizer/firebase_options.dart';
import 'package:tateyomi_gigarizer/page/login_page.dart';
import 'package:url_strategy/url_strategy.dart';

void main() async {
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '縦読みツール',
      theme: ThemeData(
        fontFamily: "NotoSansJP",
        primaryColor: Colors.white,
        scaffoldBackgroundColor   : Colors.grey,
        scrollbarTheme: ScrollbarThemeData(
          showTrackOnHover: true,
          trackVisibility : MaterialStateProperty.all<bool>(true),
          thumbColor      : MaterialStateProperty.all<Color>(const Color.fromARGB(255, 88, 75, 66)),
        ),
        primarySwatch: Colors.blue,
      ),
      navigatorObservers: [ FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance), ],
      // // test用
      // home: LoginPageWidget(dbInstance: DbImpl(),)
      home: LoginPageWidget(dbInstance: DbFireStore(),),
    );
  }
}
