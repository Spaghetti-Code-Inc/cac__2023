import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tf;
import 'package:image/image.dart' as img;
import 'dart:io';

// class DisplayPicture extends StatefulWidget {
//   final String imagePath;
//
//   const DisplayPicture({Key? key, required this.imagePath}) : super(key: key);
//
//   @override
//   State<DisplayPicture> createState() => _DisplayPictureState();
// }
//
// class _DisplayPictureState extends State<DisplayPicture> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text(F'Picture')),
//       // The image is stored as a file on the device. Use the `Image.file`
//       // constructor with the given path to display the image.
//       body: Column(children: [
//         Image.file(File(widget.imagePath)),
//         Container(
//           padding: const EdgeInsets.only(top: 10),
//           child: FloatingActionButton(
//             onPressed: () async {
//               try {
//                 print("test");
//               } catch (oof) {
//                 print("ACK");
//               }
//             },
//             child: const Icon(Icons.auto_mode_rounded),
//           ),
//         ),
//       ]),
//     );
//   }
// }

class RunModel extends StatefulWidget {
  RunModel({Key? key, required this.imagePath}) : super(key: key);
  bool showImg = true;
  final String imagePath;

  @override
  State<RunModel> createState() => _RunModelState();
}

/// Wrapper for every detected class
final class ObjectDetected {
  final String name;
  final double score;
  final List bbox;

// String name, Int Score, [left x, upper y, right x, lower y]
  const ObjectDetected(this.name, this.score, this.bbox);
}

class _RunModelState extends State<RunModel> {
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
    final bytes = await File(widget.imagePath).readAsBytes();
    final img.Image image = img.decodeImage(bytes)!;
    print(image.data);
    resized = img.copyResize(image, width: 300, height: 300);

    imageWithHeader = img.encodeNamedImage("Test_Image.bmp", resized)!;
  }

  @override
  dispose() {
    super.dispose();
    interpreter.close();
  }

  runInference(
    List<List<List<int>>> imageMatrix,
  ) async {
// Tensor input [1, 300, 300, 3]
    final input = [imageMatrix];
// Place holder
    final output = [];
    print(output.shape);
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

    /// 5 is max detections per image
    objects = [];
    for (int i = 0; i < 5; i++) {
      objects.add(ObjectDetected(
          labels[classes[0][i].round()].substring(0, labels[classes[0][i].round()].length - 1),
          scores[0][i],
          bboxes[0][i]));
    }
  }

  updateImg() {
    setState(() {
      if (widget.showImg == true) {
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
        print('going into running inference');
        runInference(check);
      }
      widget.showImg = !widget.showImg;
    });
  }

  List<Widget> renderBoxes() {
    // Confidence threshold
    const double CONF = 0.5;
    double factorX = MediaQuery.of(context).size.width;
    double factorY = 720*MediaQuery.of(context).size.width/480;

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

    // o.insert(0, Container(child: Image(image: MemoryImage(Uint8List.fromList(imageWithHeader)))));
    o.insert(0, Container(child: Image.file(File(widget.imagePath))));

    return o;
  }

  @override
  Widget build(BuildContext context) {
    loadImage();
    loadModel();
    loadClasses();

    return Column(
      children: [
        Container(
          child: (widget.showImg) ? Image.file(File(widget.imagePath)) : Stack(children: renderBoxes()),
        ),
        Container(
          padding: EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Icon(Icons.arrow_back),
              ),
              Container(
                padding: const EdgeInsets.only(left: 10),
                child: FloatingActionButton(
                  onPressed: () {
                    updateImg();
                  },
                  child: const Icon(Icons.auto_mode_rounded),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
