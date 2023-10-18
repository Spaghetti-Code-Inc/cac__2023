import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'camera.dart';

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

class _TestModelState extends State<TestModel> {
  late Interpreter interpreter;
  late img.Image resized;
  late List<int> imageWithHeader;

  loadModel() async {
    final options = InterpreterOptions();
    interpreter = await Interpreter.fromAsset('assets/mobilenet_v1_1.0_224.tflite', options: options);

    print(interpreter.getInputTensors().first);
    print(interpreter.getOutputTensors().first);
  }

  Future<void> loadImage() async {
    // TODO works for jpg only
    ByteData data = await rootBundle.load('assets/images/img.jpg');

    resized = img.decodeImage(data.buffer.asUint8List())!;
    resized = img.copyResize(resized, width: 224, height: 224);

    imageWithHeader = img.encodeNamedImage("Test_Image.bmp", resized)!;
  }

  dispose(){
    interpreter.close();
  }


  runInference(
      List<List<List<num>>> imageMatrix,
      ) async {
    // Tensor input [1, 224, 224, 3]
    final input = [imageMatrix];
    // Tensor output [1, 1001]
    final output = [List<int>.filled(1001, 0)];

    // Run inference
    interpreter.run(input, output);

    // Get first output tensor
    final result = output.first;
    print(result);
  }

  updateImg(){
    setState(() {
      widget.showImg = !widget.showImg;
      if(widget.showImg == false) {
        // Next step is too get pixel array and use the 'runInference' function
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    loadImage();
    loadModel();

    return Column( children: [
      (widget.showImg) ? Image.asset('assets/images/img.jpg') : Container(child: Image(image: MemoryImage(Uint8List.fromList(imageWithHeader)))),

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
