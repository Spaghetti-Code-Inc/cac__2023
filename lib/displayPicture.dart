import 'dart:io';
import 'package:flutter/material.dart';

class DisplayPicture extends StatefulWidget {

  final String imagePath;

  const DisplayPicture({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<DisplayPicture> createState() => _DisplayPictureState();
}

class _DisplayPictureState extends State<DisplayPicture> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(widget.imagePath)),
    );
  }
}
