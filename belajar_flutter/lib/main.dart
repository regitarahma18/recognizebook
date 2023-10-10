import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
// import 'package:camera/camera.dart';


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
  // CameraController? _cameraController;
  // List<CameraDescription> cameras = [];


@override
void initState() {
  super.initState();
  loadModel().then((_) {
    setState(() {
      _modelLoaded = true;
      // _initializeCamera(); // Inisialisasi kamera saat model dimuat
    });
  });
  // availableCameras().then((cameras) {
  //   setState(() {
  //     this.cameras = cameras;
  //   });
  // });
}

  Future<void> loadModel() async {
    try {
      final modelPath = 'assets/models/model.tflite';
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
        if(text != null){
          textoutput = text;
        }

        setState(() {
          _loading = false;
          _recognitions = [
            {"label": "Result:", "text": textoutput},
            // {"label": "Predicted Label:", "labelValue": predictedLabel}
          ];
        });
      } catch (e) {
        print('Error performing : $e');
      }
    }
  }
// Future<void> _initializeCamera() async {
//   final CameraController controller = CameraController(
//     cameras[0], // Anda dapat memilih kamera lain jika perlu
//     ResolutionPreset.medium,
//   );

//   await controller.initialize();
//   setState(() {
//     _cameraController = controller;
//   });
// }
// Future<void> _takePicture() async {
//   if (!_modelLoaded || _cameraController == null) {
//     return;
//   }

//   try {
//     final XFile file = await _cameraController!.takePicture();
//     final File imageFile = File(file.path);

//     setState(() {
//       _image = imageFile;
//       _loading = true;
//     });

//     String textoutput = '';
//     String? text = await performOCR(_image!);
//     int predictedLabel = await performPrediction(_image!);

//     if (text != null) {
//       textoutput = text;
//     }

//     setState(() {
//       _loading = false;
//       _recognitions = [
//         {"label": "Result:", "text": textoutput},
//         // {"label": "Predicted Label:", "labelValue": predictedLabel}
//       ];
//     });
//   } catch (e) {
//     print('Error taking picture: $e');
//   }
// }

  Future<String?> performOCR(File image) async {
  try {
    final text = await FlutterTesseractOcr.extractText(image.path);
    return text; // Return the OCR result
  } catch (e) {
    print("Error performing : $e");
    return null; // Return null in case of an error
  }
}

  Future<int> performPrediction(File image) async {
    print('masuk awal');
    try {
      print('masuk ke2');
      print(Tflite.runModelOnImage(
        path: image.path,
        numResults: 1
      ));
      print('atas jalan');
      var recognitions = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 1,
      );
      print('masuk');
      print(recognitions);

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
    // _cameraController?.dispose();
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
        : SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Image.asset(
                  'assets/images/splash.png', 
                  width: 300, 
                  height: 500,
                  fit: BoxFit.contain,
                ),
                Text(
                  "Let's start scan your book", 
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 35.0,
                    color: Color.fromARGB(255, 138, 177, 229),
                  ),
                ),
                _image == null ? Container() : Image.file(_image!),
                SizedBox(height: 20),

                // _cameraController != null
                // ? CameraPreview(_cameraController!)
                // : Container(), 

                _recognitions == null || _recognitions!.isEmpty
                    ? Container()
                    : Column(
                        children: _recognitions!.map((res) {
                          return Column(
                            children: [
                              Image.asset(
                                'assets/images/splash.png', // Ganti dengan path gambar Anda
                                width: 100, // Sesuaikan ukuran gambar
                                height: 100,
                              ),
                              Text(
                                "${res["label"]} ${res["text"] ?? res["labelValue"]}",
                                style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                SizedBox(height: 20), // Spasi tambahan
              ],
            ),
          ),
  floatingActionButton: Column(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    FloatingActionButton(
      onPressed: () {
        // _takePicture(); // Panggil fungsi tangkapan gambar kamera
      },
      tooltip: 'Take Picture',
      child: Icon(Icons.camera),
      backgroundColor: Color.fromARGB(255, 138, 177, 229),
    ),
    SizedBox(height: 16), // Spasi antara dua tombol
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
}