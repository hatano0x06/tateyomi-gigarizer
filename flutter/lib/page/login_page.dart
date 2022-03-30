// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
// ignore: unused_import
import 'package:tateyomi_gigarizer/dialog/text_input_dialog.dart';
import 'package:tateyomi_gigarizer/model/common.dart';
import 'package:tateyomi_gigarizer/model/project.dart';
import 'package:tateyomi_gigarizer/page/edit_page.dart';
import 'package:tateyomi_gigarizer/page/viewer.dart';

class LoginPageWidget extends StatefulWidget {
  final DbImpl dbInstance;

  const LoginPageWidget({
    Key? key, 
    required this.dbInstance, 
  }):super(key:key);

  @override
  _LoginPageWidgetState createState() => _LoginPageWidgetState();
}

class _LoginPageWidgetState extends State<LoginPageWidget> {

  final TextEditingController loginNameController = TextEditingController();
  List<Project> projectList = [];
  bool isEnableLoginId = false;

  @override
  void initState(){
    super.initState();
  }

  @override
  void dispose(){
    loginNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> widgetList = [];
    if( isDeskTop() ){
      widgetList.add(
        Row(children: [
          Expanded(child: loginIdWidget()),
          const SizedBox(width: 5,),
          loginButton(),
          const SizedBox(width: 5,),
          newProjectButton()
        ],)
      );
    } else {
      widgetList.addAll([
        loginIdWidget(),
        loginButton(),
      ]);
    }

    widgetList.addAll(existProjectList());


    return Scaffold(
      appBar: AppBar(
        title   : const Text( "ログインページ" ),
      ),

      body: Container(
        width   : MediaQuery.of(context).size.width,
        height  : MediaQuery.of(context).size.height - kToolbarHeight,
        color   : Colors.white,
        child : Container(
          margin  : const EdgeInsets.symmetric(vertical: 50, horizontal: 10),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children    : widgetList
            ),
          ),
        ),
      ),
    );
  } 

  List<Widget> existProjectList(){
    if(projectList.isEmpty) return [];

    projectList.sort((Project a, Project b){ return b.lastOpenTime.compareTo(a.lastOpenTime); });

    List<Widget> widgetList = [];
    for (Project _proj in projectList) {
      widgetList.add(
        Card(
          color: Colors.grey[300],
          child : InkWell(
            child : ListTile(
              title : Text(_proj.name, style: const TextStyle( fontWeight: FontWeight.bold,),),
              subtitle  : Column(mainAxisSize: MainAxisSize.min, children: [
                Align(
                  alignment : Alignment.centerLeft,
                  child     : Text("作成日：" + DateTime.fromMillisecondsSinceEpoch(_proj.createTime).toIso8601String() ),
                ),
                Align(
                  alignment : Alignment.centerLeft,
                  child     : Text("更新日：" + DateTime.fromMillisecondsSinceEpoch(_proj.lastOpenTime).toIso8601String()),
                ),
              ],),
            ),
            onTap: (){
              _proj.lastOpenTime = DateTime.now().millisecondsSinceEpoch;
              _proj.save();

              Widget openPage = isDeskTop() ?
              EditPage(
                dbInstance  : widget.dbInstance,
                project     : _proj,
              ) :
              ViewerPage(
                dbInstance  : widget.dbInstance,
                project     : _proj,
              );

              Navigator.push( context, PageRouteBuilder( pageBuilder: (context, animation1, animation2) => openPage ), );
            },
          ),
        )
      );
    }

    return widgetList;
  }

  Widget loginIdWidget(){
    return TextFormField(
      autofocus: true,
      autovalidateMode: AutovalidateMode.always,
      controller  : loginNameController,
      decoration      : const InputDecoration( labelText: "id名", ),
      validator    : (String? _value){
        if(_value == null ) return null;
        if(_value.isEmpty) return "id名を入力してください";
        return null;
      },
      onFieldSubmitted: (_){ loginAction(); },
    );
  }

  void loginAction() async {
    setState(() { });
    projectList.clear();
    isEnableLoginId = false;

    // widget.dbInstance.loginId = "caramelmama";

    if( widget.dbInstance.isTest ){
      widget.dbInstance.loginId = "caramelmama";
    } else {
      // TODO: firebaseのセキュリティのほうでも制限かかっているので、注意
      // caramelmama以外許さない（一旦
      if( !["caramelmama", "test"].contains(loginNameController.text) ) return;
      widget.dbInstance.loginId = loginNameController.text;
    }

    projectList = await widget.dbInstance.getProjectList();
    isEnableLoginId = true;
    setState(() { });
  }

  Widget loginButton(){
    return ElevatedButton(
      child   : const Text('このidでデータの取得'),
      onPressed: () async { loginAction(); }
    );
  }

  Widget newProjectButton(){
    return ElevatedButton(
      child   : const Text('プロジェクトの新規作成'),
      onPressed: !isEnableLoginId && !widget.dbInstance.isTest ? null : () async { 
        void moveToProj(String _text){
          Project _newProj = Project(
            widget.dbInstance,
            "",
            _text,
            Size.zero,
            DateTime.now().millisecondsSinceEpoch,
            DateTime.now().millisecondsSinceEpoch,
          );
          _newProj.save();

          Navigator.push( context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => EditPage(
                dbInstance  : widget.dbInstance,
                project     : _newProj,
              )
            ),
          );
        }

        if( widget.dbInstance.isTest ){
          moveToProj("");
          return;
        }

        showDialog( 
          context: context, 
          builder: (BuildContext context) => const TextInputDialog("")
        ).then((_text){
          if( _text == null ) return;
          String _fixText = _text as String;
          if( _fixText.isEmpty ) return;

          moveToProj(_fixText);
          return;
        });
      },
    );
  }

}