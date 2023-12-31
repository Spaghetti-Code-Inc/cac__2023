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
        padding: EdgeInsets.all(15),
        child: const Text("ObjecTracer is an app created by Spaghetti Code Inc designed for integrating object detection technology into a mobile app. \n\nFor business inquiries, contact Spaghetti Code Inc at cac.pogg@gmail.com"),
      ),
    );
  }

}