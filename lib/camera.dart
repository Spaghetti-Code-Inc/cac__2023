import 'main.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import 'displayPicture.dart';

// bool variable for flash
var flash = false;
var flashIcon = Icons.flash_off;

//CAMERA CLASS
class Camera extends StatefulWidget{
  final CameraDescription camera;


  Camera(
      {Key? key, required this.camera}) : super(key:key);
  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> {

  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // initialize the rear camera
    // only need low because model can not handle large images anyways
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(onPressed: () {
    Navigator.pop(context);},
            child: const Icon(Icons.arrow_back),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
              child: FloatingActionButton.large(
                onPressed: () async {
                  // Take the Picture in a try / catch block. If anything goes wrong,
                  // catch the error.
                  try {
                    // Ensure that the camera is initialized.
                    await _initializeControllerFuture;

                    // Attempt to take a picture and then get the location
                    // where the image file is saved.
                    final image = await _controller.takePicture();
                    await _controller.setFlashMode(FlashMode.off);
                    // if (!mounted) return;

                    print(image.path);
                    if (!mounted) return;

                    // If the picture was taken, display it on a new screen.
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RunModel(
                          // Pass the automatically generated path to
                          // the DisplayPictureScreen widget.
                          imagePath: image.path,
                        ),
                      ),
                    );


                  } catch (e) {
                    // If an error occurs, log the error to the console.
                    setState(() {
                      print(e);
                      print("reset");
                    });
                  }
                },
                child: const Icon(Icons.camera_alt),
              ),
            ),

            FloatingActionButton(onPressed: () async {
              if (!flash) {
                print("flash on");
                await _controller.setFlashMode(FlashMode.torch);
                setState(() {
                  flashIcon = Icons.flash_on;
                  flash = !flash;
                });

              }else{
                print("flash off");
                await _controller.setFlashMode(FlashMode.off);
                setState(() {
                  flashIcon = Icons.flash_off;
                  flash = !flash;
                });

              }
            },
              child: Icon(flashIcon),
            )
          ],
        )

      )

    );
  }
}

// takePicture() method to get the image from controller
// display using Image.file(File('path'));
