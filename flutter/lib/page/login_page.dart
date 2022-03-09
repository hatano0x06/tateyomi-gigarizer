// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';
import 'package:tateyomi_gigarizer/dialog/text_input_dialog.dart';
import 'package:tateyomi_gigarizer/model/project.dart';
import 'package:tateyomi_gigarizer/page/edit_page.dart';

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
    return Scaffold(
      appBar: AppBar(
        title   : const Text( "ログインページ" ),
      ),
      body: Container(
        margin  : const EdgeInsets.symmetric(vertical: 50, horizontal: 10),
        width   : MediaQuery.of(context).size.width/2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children    : [
            loginUnit(),
            existProjectList()
          ]
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


  Widget loginUnit(){
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child : TextFormField(
            autofocus: true,
            autovalidateMode: AutovalidateMode.always,
            controller  : loginNameController,
            decoration      : const InputDecoration( labelText: "id名", ),
            validator    : (String? _value){
              if(_value == null ) return null;
              if(_value.isEmpty) return "id名を入力してください";
              return null;
            },
          ),
        ),
        const SizedBox(width: 5,),
        ElevatedButton(
          child   : const Text('このidでデータの取得'),
          onPressed: () async { 
            setState(() { });
            projectList.clear();
            isEnableLoginId = false;
            widget.dbInstance.loginId = loginNameController.text;

            // caramelmama以外許さない（一旦
            // TODO: asdf
            // if( loginNameController.text != "caramelmama") return;

            projectList = await widget.dbInstance.getProjectList();
            isEnableLoginId = true;
            setState(() { });
          }
        ),
        const SizedBox(width: 5,),
        ElevatedButton(
          child   : const Text('プロジェクトの新規作成'),
          onPressed: !isEnableLoginId ? null : () async { 
            showDialog( 
              context: context, 
              builder: (BuildContext context) => const TextInputDialog("")
            ).then((_text){
              if( _text == null ) return;
              String _fixText = _text as String;
              if( _fixText.isEmpty ) return;

              Project _newProj = Project(
                widget.dbInstance,
                "",
                _fixText,
                _fixText,
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
            });
          }
        ),
      ],
    );

  }
}