import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';



void main() {
  runApp(MaterialApp(
    home: OCRScreen(),
  ));
}

class OCRScreen extends StatefulWidget {
  @override
  _OCRScreenState createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  File? _image;
  List<Map<String, dynamic>>? _recognitions;
  bool _loading = false;
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    loadModel().then((_) {
      setState(() {
        _modelLoaded = true;
      });
    });
  }

  Future<void> loadModel() async {
    try {
      final modelPath = 'assets/models/vgg.tflite';
      await Tflite.loadModel(
        model: modelPath,
      );
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> getImage() async {
    if (!_modelLoaded) {
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _loading = true;
      });

      try {
        String textoutput = '';
        String? text = await performOCR(_image!);
        int predictedLabel = await performPrediction(_image!);
        if (text != null) {
          textoutput = text;
        }

        setState(() {
          _loading = false;
          _recognitions = [
            {"label": "Result:", "text": textoutput}
          ];
        });
      } catch (e) {
        print('Error performing OCR: $e');
      }
    }
  }

  Future<String?> performOCR(File image) async {
    try {
      final text = await FlutterTesseractOcr.extractText(image.path);
      return text;
    } catch (e) {
      print("Error performing OCR: $e");
      return null;
    }
  }

  Future<int> performPrediction(File image) async {
    try {
      var recognitions = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 1,
      );

      if (recognitions != null && recognitions.isNotEmpty) {
        return recognitions[0]["index"].toInt();
      } else {
        return -1;
      }
    } catch (e) {
      print('Error performing prediction: $e');
      return -1;
    }
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Recognize'),
        backgroundColor: Color.fromARGB(255, 138, 177, 229),
      ),
      body: _loading
          ? CircularProgressIndicator()
          : Column(
              children: <Widget>[
                _image == null ? Container() : Image.file(_image!),
                SizedBox(height: 20),
                _recognitions == null || _recognitions!.isEmpty
                    ? Container()
                    : Column(
                        children: _recognitions!.map((res) {
                          return Text(
                            "${res["label"]} ${res["text"] ?? res["labelValue"]}",
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList(),
                      ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: takePicture,
            tooltip: 'Take Picture',
            child: Icon(Icons.camera),
            backgroundColor: Color.fromARGB(255, 138, 177, 229),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: getImage,
            tooltip: 'Pick Image',
            child: Icon(Icons.image),
            backgroundColor: Color.fromARGB(255, 138, 177, 229),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 138, 177, 229),
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.perm_device_information_sharp),
              title: Text('About'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text('Help'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

void takePicture() async {
  final picker = ImagePicker();
  final pickedFile = await picker.getImage(source: ImageSource.camera);

  if (pickedFile != null) {
    setState(() {
      _image = File(pickedFile.path); // Convert XFile to File
      _loading = true;
    });

    try {
      final int maxHeight = 200;
      final int maxWidth = 200;

      final originalImage = img.decodeImage(_image!.readAsBytesSync());
      final resizedImage = img.copyResize(originalImage!, height: maxHeight, width: maxWidth);

      // Get the temporary directory and create a temporary File
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temporary_image.jpg');

      // Save the resized image to the temporary File
      tempFile.writeAsBytesSync(img.encodeJpg(resizedImage));

      String textoutput = '';
      String? text = await performOCR(tempFile);
      int predictedLabel = await performPrediction(tempFile);
      if (text != null) {
        textoutput = text;
      }

      setState(() {
        _loading = false;
        _recognitions = [
          {"label": "Result:", "text": textoutput}
        ];
      });
    } catch (e) {
      print('Error performing OCR: $e');
    }
  }
}


}
