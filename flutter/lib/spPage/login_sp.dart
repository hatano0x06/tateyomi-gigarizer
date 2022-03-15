// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
// ignore: unused_import
import 'package:tateyomi_gigarizer/dialog/text_input_dialog.dart';
import 'package:tateyomi_gigarizer/model/project.dart';
import 'package:tateyomi_gigarizer/page/edit_page.dart';

class SpLoginPageWidget extends StatefulWidget {
  final DbImpl dbInstance;

  const SpLoginPageWidget({
    Key? key, 
    required this.dbInstance, 
  }):super(key:key);

  @override
  _SpLoginPageWidgetState createState() => _SpLoginPageWidgetState();
}

class _SpLoginPageWidgetState extends State<SpLoginPageWidget> {

  final TextEditingController loginNameController = TextEditingController();
  List<Project> projectList = [];

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children    : [
              loginUnit(),
              loginButton(),
              existProjectList()
            ]
          ),
        ),
      ),
    );
  } 

  Widget existProjectList(){
    if(projectList.isEmpty) return Container();

    return SizedBox(
      child : SingleChildScrollView(
        child: ListView.builder(
          shrinkWrap  : true,
          itemBuilder : (BuildContext context, int index) {
            Project _proj = projectList[index];

            return Card(
              color: Colors.grey[400],
              child : InkWell(
                child : ListTile(
                  title : Text(_proj.name, style: const TextStyle( fontWeight: FontWeight.bold),),
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

                  Navigator.push( context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) => EditPage(
                        dbInstance  : widget.dbInstance,
                        project     : _proj,
                      )
                    ),
                  );
                },
              ),
            );
          },
          itemCount: projectList.length,
        )
      ),
    );
  }

  Widget loginButton(){
    return ElevatedButton(
      child   : const Text('このidでデータの取得'),
      onPressed: () async { 
        setState(() { });
        projectList.clear();
        widget.dbInstance.loginId = "caramelmama";

        // caramelmama以外許さない（一旦
        // TODO: asdf
        //  firebaseのセキュリティのほうでも制限かかっているので、注意
        // if( loginNameController.text != "caramelmama") return;
        // widget.dbInstance.loginId = loginNameController.text;

        projectList = await widget.dbInstance.getProjectList();
        print( projectList );
        setState(() { });
      }
    );    
  }


  Widget loginUnit(){
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
    );

  }
}