// This is a single-file example of a Flutter application.
// To run this, you must have a Flutter project set up.
// Add the following dependencies to your pubspec.yaml file:
//
// dependencies:
//   flutter:
//     sdk: flutter
//   camera: ^0.10.5+9
//   http: ^1.1.0
//   path_provider: ^2.1.1
//   image_picker: ^1.0.4
//   image: ^4.1.3
//
// After adding, run 'flutter pub get' in your terminal.

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; // Import the image package

// A simple painter to draw a bounding box rectangle.
class BoundingBoxPainter extends CustomPainter {
  final List<Rect> boundingBoxes;
  final double imageWidth;
  final double imageHeight;

  BoundingBoxPainter(this.boundingBoxes, this.imageWidth, this.imageHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Calculate the scaling factors and offsets to match the BoxFit.contain
    final double scaleX = size.width / imageWidth;
    final double scaleY = size.height / imageHeight;
    final double finalScale = min(scaleX, scaleY);

    final double offsetX = (size.width - imageWidth * finalScale) / 2;
    final double offsetY = (size.height - imageHeight * finalScale) / 2;

    for (var box in boundingBoxes) {
      // Scale and offset the bounding box coordinates
      final scaledBox = Rect.fromLTWH(
        (box.left * finalScale) + offsetX,
        (box.top * finalScale) + offsetY,
        box.width * finalScale,
        box.height * finalScale,
      );
      canvas.drawRect(scaledBox, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  if (cameras.isEmpty) {
    // Handle case where no cameras are available
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('No camera found on this device.'),
          ),
        ),
      ),
    );
  } else {
    runApp(MyApp(camera: cameras.first));
  }
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera Bounding Box Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(camera: camera),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final CameraDescription camera;

  const MyHomePage({Key? key, required this.camera}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  XFile? _imageFile;
  Uint8List? _resizedImageBytes;
  List<Rect>? _boundingBoxes;
  bool _isLoading = false;
  int _imageWidth = 0;
  int _imageHeight = 0;

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _cameraController.initialize();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      setState(() {
        _isLoading = true;
        _resizedImageBytes = null;
        _boundingBoxes = null;
      });
      await _initializeControllerFuture;
      final image = await _cameraController.takePicture();
      await _uploadAndProcessImage(image);
    } catch (e) {
      print('Error taking picture: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() {
        _isLoading = true;
        _resizedImageBytes = null;
        _boundingBoxes = null;
      });
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        await _uploadAndProcessImage(image);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadAndProcessImage(XFile image) async {
    setState(() {
      _imageFile = image;
      _boundingBoxes = null;
    });

    try {
      final imageBytes = await image.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        print('Error: Failed to decode image.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final resizedImage = img.copyResize(originalImage, width: 800);
      _imageWidth = resizedImage.width;
      _imageHeight = resizedImage.height;

      final resizedImageBytes = img.encodeJpg(resizedImage, quality: 85);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/resized_image.jpg');
      await tempFile.writeAsBytes(resizedImageBytes);

      var uri = Uri.parse('http://192.168.1.3:8000/upload');
      var request = http.MultipartRequest("POST", uri);
      request.files.add(
        await http.MultipartFile.fromPath('file', tempFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      await tempFile.delete();

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final List<dynamic> outData = responseBody['result'];

        if (outData.isEmpty) {
          print('Server returned no bounding box data.');
          setState(() {
            _resizedImageBytes = resizedImageBytes;
            _isLoading = false;
          });
          return;
        }

        List<Rect> boxes = [];
        for (var data in outData) {
          final rect = Rect.fromLTWH(
            data['xmin'].toDouble(),
            data['ymin'].toDouble(),
            data['xmax'].toDouble() - data['xmin'].toDouble(),
            data['ymax'].toDouble() - data['ymin'].toDouble(),
          );
          boxes.add(rect);
        }

        setState(() {
          _resizedImageBytes = resizedImageBytes;
          _boundingBoxes = boxes;
          _isLoading = false;
        });

        print('Successfully received and parsed bounding box data: $_boundingBoxes');
      } else {
        print('Server responded with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error uploading image: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera App'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Center(
              child: Stack(
                children: [
                  if (_resizedImageBytes == null)
                    SizedBox(
                      width: 300,
                      height: 400,
                      child: CameraPreview(_cameraController),
                    ),
                  if (_resizedImageBytes != null)
                    SizedBox(
                      width: 300,
                      height: 400,
                      child: Image.memory(
                        _resizedImageBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  if (_boundingBoxes != null)
                    SizedBox(
                      width: 300,
                      height: 400,
                      child: CustomPaint(
                        painter: BoundingBoxPainter(
                          _boundingBoxes!,
                          _imageWidth.toDouble(),
                          _imageHeight.toDouble(),
                        ),
                      ),
                    ),
                  if (_isLoading)
                    SizedBox(
                      width: 300,
                      height: 400,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _takePicture,
            tooltip: 'Take Picture',
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _pickImageFromGallery,
            tooltip: 'Pick from Gallery',
            child: const Icon(Icons.photo_library),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
