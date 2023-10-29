import 'package:flutter/material.dart';
import 'main.dart';

class Config extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _ConfigState();
}

class _ConfigState extends State<Config> {
  TextEditingController _confidence = TextEditingController(text: Globals.confidence.toString());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Config"),
      ),
      body: Container(
        margin: EdgeInsets.all(20),
        child: Column(

          children:[

            Row(
              children: [
                Expanded(
                  child: Text(
                      "Enter confidence rate for the AI (Values from 0-1): ",
                      textAlign: TextAlign.left,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.visible,
                  ),
                ),

                Container(

                  width: 30,
                  child: TextField(
                    controller: _confidence,
                    maxLength: 6,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )



        ]
    ),
      ),
    );
  }
}
