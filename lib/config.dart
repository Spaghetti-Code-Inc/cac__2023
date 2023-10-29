import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

class Config extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _AboutState();

}

class _ConfigState extends State<Config> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Config"),
      ),
      body: Container(
        child: const Text("Balsl"),
      ),
    );
  }
