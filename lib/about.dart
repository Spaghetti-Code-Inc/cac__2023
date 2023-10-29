import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

class About extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _AboutState();

}

class _AboutState extends State<About> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
      ),
      body: Container(
        child: const Text("ObjecTracer is an app created by Spaghetti Code Inc designed for integrating object detection technology into a mobile app."),
      ),
    );
  }

}