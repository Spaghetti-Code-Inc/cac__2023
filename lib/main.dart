import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'camera.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.

        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff8b0000),
            brightness: Brightness.dark,
            background: Colors.black
        ),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
          ),
          // ···
          titleLarge: GoogleFonts.firaCode(
            fontSize: 30,
            fontStyle: FontStyle.italic,
          ),
          bodyMedium: GoogleFonts.firaCode(),
          displaySmall: GoogleFonts.firaSans(),
        ),

      ),
      home: const MyHomePage(title: 'ObjecTracer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Center(
        child: Column(

          children: <Widget>[
            Container(
              width: 150,
              margin: const EdgeInsets.fromLTRB(60, 80, 60, 30),
              child: ElevatedButton(
                  style: ButtonStyle(
                    padding:MaterialStateProperty.all<EdgeInsets>(
                        EdgeInsets.all(10)),

                  ),
                  onPressed: () async {
                    await availableCameras().then((value) => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => Camera(camera: value.first))));
                    print("pressed");
                  },
                  child: const Row(
                    children: [
                      Padding(padding: EdgeInsets.all(10),
                          child: Icon(Icons.camera_alt_outlined)),
                      Text("Open Camera")
                    ],
                  )
              ),
            ),
            Align(alignment: Alignment.bottomCenter,
                child: OverflowBar(
                  alignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    TextButton( child: const Text('Config'), onPressed: () {}),
                    TextButton( child: const Text('Models'), onPressed: () {}),
                    TextButton( child: const Text('About'), onPressed: () {}),
                    TextButton( child: const Text('Test model'), onPressed: () { Navigator.push(context,
                        MaterialPageRoute(builder: (_) => TestModel()));}),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}

class TestModel extends StatefulWidget {
  TestModel({Key? key}) : super(key: key);
  bool showImg = true;

  @override
  State<TestModel> createState() => _TestModelState();
}

/// Wrapper for every detected class
final class ObjectDetected {
  final String name;
  final double score;
  final List bbox;

  // String name, Int Score, [left x, upper y, right x, lower y]
  const ObjectDetected(this.name, this.score, this.bbox);
}

class _TestModelState extends State<TestModel> {
  late Interpreter interpreter;
  late img.Image resized;
  late List<int> imageWithHeader;
  late List<List<double>> result;
  late List<ObjectDetected> objects;
  late List<String> labels;

  loadModel() async {
    final options = InterpreterOptions();
    interpreter = await Interpreter.fromAsset('assets/models/ssd_mobilenet_v1_1_metadata_1.tflite', options: options);
    interpreter.allocateTensors();
  }

  Future<void> loadClasses() async {
    // Waits to get the text file then sets classes equal to the correct version
    await rootBundle.loadString('assets/models/labelmap.txt').then(
      (holder) => labels = holder.split('\n')
    );
  }

  Future<void> loadImage() async {
    // TODO works for jpg only
    ByteData data = await rootBundle.load('assets/images/cat_again.jpg');

    resized = img.decodeImage(data.buffer.asUint8List())!;
    resized = img.copyResize(resized, width: 300, height: 300);

    imageWithHeader = img.encodeNamedImage("Test_Image.bmp", resized)!;
  }

  dispose(){
    interpreter.close();
  }


  runInference(
      List<List<List<int>>> imageMatrix,
      ) async {
    // Tensor input [1, 300, 300, 3]
    final input = [imageMatrix];
    // Place holder
    final output = [];

    // Run inference
    interpreter.run(input, output);

    final bboxes = [List.filled(10, List.filled(4, 0.0))];
    interpreter.getOutputTensor(0).copyTo(bboxes);

    final classes = [List.filled(10, 0.0)];
    interpreter.getOutputTensor(1).copyTo(classes);

    final scores = [List.filled(10, 0.0)];
    interpreter.getOutputTensor(2).copyTo(scores);

    final detections = [0.0];
    interpreter.getOutputTensor(3).copyTo(detections);

    print(bboxes);
    print(classes);
    print(scores);

    /// 0.5 can be used for the confidence threshold
    for(int i = 0; i < 3 && scores[0][i] > 0.5; i++){

      print(labels[classes[0][i].round()]);
    }



  }

  updateImg(){
    setState(() {
      widget.showImg = !widget.showImg;
      if(widget.showImg == false) {
        List<List<List<int>>> check = [];

        // Create the rgb array
        for(int i = 0; i < 300; i++){
          check.add([]);
          for(int j = 0; j < 300; j++){
            List<int> rgb = [resized.getPixel(i, j)[0].toInt(), resized.getPixel(i, j)[1].toInt(), resized.getPixel(i, j)[2].toInt()];
            check[i].add(rgb);
          }
        }
       runInference(check);

      }
    });
  }

  @override
  Widget build(BuildContext context) {
    loadImage();
    loadModel();
    loadClasses();

    return Column( children: [
      (widget.showImg) ? Image.asset('assets/images/cat_again.jpg') : Container(child: Image(image: MemoryImage(Uint8List.fromList(imageWithHeader)))),

      ElevatedButton(
          style: ButtonStyle(
            padding:MaterialStateProperty.all<EdgeInsets>(
                EdgeInsets.all(10)),

          ),
          onPressed: () {
            updateImg();
          },
          child: const Row(
            children: [
              Padding(padding: EdgeInsets.all(10),
                  child: Icon(Icons.camera_alt_outlined)),
              Text("Take Image")
            ],
          )
      ),
    ],


    );
  }
}
