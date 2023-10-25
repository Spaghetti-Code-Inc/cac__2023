import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tf;
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
      title: 'ObjecTracer',
      theme: ThemeData(
        // This is the theme of your application.

        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff8b0000),
            brightness: Brightness.dark,
            background: Colors.black),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
          ),
          // ···
          titleLarge: GoogleFonts.belanosima(
            fontSize: 30,
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
              width: 180,
              margin: const EdgeInsets.fromLTRB(0, 80, 0, 30),
              child: ElevatedButton(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(10)),
                  ),
                  onPressed: () async {
                    await availableCameras().then((value) => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => Camera(camera: value.first))));
                    print("pressed");
                  },
                  child: const Row(
                    children: [
                      Padding(padding: EdgeInsets.all(10), child: Icon(Icons.camera_alt_outlined)),
                      Text("Open Camera")
                    ],
                  )),
            ),
            Align(
                alignment: Alignment.bottomCenter,
                child: OverflowBar(
                  alignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    TextButton(child: const Text('Config'), onPressed: () {}),
                    TextButton(child: const Text('Models'), onPressed: () {}),
                    TextButton(child: const Text('About'), onPressed: () {}),
                    TextButton(
                        child: const Text('Test model'),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => TestModel()));
                        }),
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
  late tf.Interpreter interpreter;
  late img.Image resized;
  late List<int> imageWithHeader;
  late List<List<double>> result;
  late List<ObjectDetected> objects;
  late List<String> labels;

  loadModel() async {
    final options = tf.InterpreterOptions();
    interpreter = await tf.Interpreter.fromAsset(
        'assets/models/ssd_mobilenet_v1_1_metadata_1.tflite',
        options: options);
    interpreter.allocateTensors();
  }

  Future<void> loadClasses() async {
    // Waits to get the text file then sets classes equal to the correct version
    await rootBundle
        .loadString('assets/models/labelmap.txt')
        .then((holder) => labels = holder.split('\n'));
  }

  Future<void> loadImage() async {
    // TODO works for jpg only
    ByteData data = await rootBundle.load('assets/images/cat_again.jpg');

    resized = img.decodeImage(data.buffer.asUint8List())!;
    resized = img.copyResize(resized, width: 300, height: 300);

    imageWithHeader = img.encodeNamedImage("Test_Image.bmp", resized)!;
  }

  dispose() {
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
    /// 5 is max detections per image
    objects = [];
    for (int i = 0; i < 5; i++) {
      objects.add(ObjectDetected(labels[classes[0][i].round()].substring(0, labels[classes[0][i].round()].length-1), scores[0][i], bboxes[0][i]));
    }
  }

  updateImg() {
    setState(() {
      widget.showImg = !widget.showImg;
      if (widget.showImg == false) {
        List<List<List<int>>> check = [];

        // Create the rgb array
        // width and height of processed image is 300x300
        for (int i = 0; i < 300; i++) {
          check.add([]);
          for (int j = 0; j < 300; j++) {
            List<int> rgb = [
              resized.getPixel(i, j)[0].toInt(),
              resized.getPixel(i, j)[1].toInt(),
              resized.getPixel(i, j)[2].toInt()
            ];
            check[i].add(rgb);
          }
        }
        runInference(check);
      }
    });
  }

  List<Widget> renderBoxes() {
    // Confidence threshold
    const double CONF = 0.5;
    double factorX = 300;
    double factorY = 300;

    Color blue = Colors.blue;

    List<Widget> o = objects.map((re) {
      return Container(
        child: Positioned(
            left: re.bbox[0] * factorX,
            top: re.bbox[1] * factorY,
            width: re.bbox[2] * factorX,
            height: re.bbox[3] * factorY,
            child: ((re.score > CONF))
                ? Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                      color: blue,
                      width: 3,
                    )),
                    child: Text(
                      "${re.name} ${(re.score * 100).toStringAsFixed(0)}%",
                      style: TextStyle(
                        background: Paint()..color = blue,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  )
                : Container()),
      );
    }).toList();
    
    o.insert(0, Container(child: Image(image: MemoryImage(Uint8List.fromList(imageWithHeader)))));

    return o;
  }

  @override
  Widget build(BuildContext context) {
    loadImage();
    loadModel();
    loadClasses();

    return Column(
      children: [
        Container(margin: EdgeInsets.all(20)),
        (widget.showImg)
            ? Image.asset('assets/images/cat_again.jpg')
            : Stack(
                children: renderBoxes()
              ),
        ElevatedButton(
            style: ButtonStyle(
              padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(10)),
            ),
            onPressed: () {
              updateImg();
            },
            child: const Row(
              children: [
                Padding(padding: EdgeInsets.all(10), child: Icon(Icons.camera_alt_outlined)),
                Text("Take Image")
              ],
            )),
      ],
    );
  }
}
