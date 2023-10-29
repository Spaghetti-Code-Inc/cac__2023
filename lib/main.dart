import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'about.dart';
import 'camera.dart';
import 'config.dart';


class Globals {
  static double confidence = 0.5;
  static int maxDetections = 5;
}

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
                    TextButton(child: const Text('Config'), onPressed: () {Navigator.push(
                        context, MaterialPageRoute(builder: (_) => Config()));}),
                    TextButton(child: const Text('About'), onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => About()));
                    }),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}