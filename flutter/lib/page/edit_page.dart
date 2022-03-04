import 'package:flutter/material.dart';
import 'package:tateyomi_gigarizer/db/db_impl.dart';

class EditPage extends StatefulWidget {
  final DbImpl? dbInstance;

  const EditPage({
    Key? key,
    this.dbInstance, 
  }):super(key:key);
  
  @override
  EditPageState createState() => EditPageState();
}

class EditPageState extends State<EditPage> {

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}