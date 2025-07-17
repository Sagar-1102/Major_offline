// lib/services/face_embedding_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceEmbeddingService {
  late Interpreter _interpreter;

  FaceEmbeddingService() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        'assets/models/mobile_facenet.tflite',
        options: options,
      );
    } catch (e) {
      print("Failed to load TFLite model: $e");
    }
  }

  Future<List<double>?> getEmbedding(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    
    final List<Face> faces = await faceDetector.processImage(inputImage);
    faceDetector.close();

    if (faces.isEmpty) {
      print("No face detected in the image.");
      return null;
    }

    // Use the largest face found
    final face = faces.first; 
    final boundingBox = face.boundingBox;

    final imageBytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) return null;

    // Crop the image to the detected face
    final croppedFace = img.copyCrop(
      originalImage,
      x: boundingBox.left.toInt(),
      y: boundingBox.top.toInt(),
      width: boundingBox.width.toInt(),
      height: boundingBox.height.toInt(),
    );

    // Resize to model's input size (112x112) and normalize
    final preprocessedImage = _preprocess(croppedFace, 112);

    // Run inference
    final input = preprocessedImage.reshape([1, 112, 112, 3]);
    final output = List.filled(1 * 192, 0.0).reshape([1, 192]);

    _interpreter.run(input, output);
    
    // Normalize the output embedding vector
    final embedding = _normalize(output[0] as List<double>);
    return embedding;
  }

  Float32List _preprocess(img.Image image, int size) {
    final resizedImage = img.copyResize(image, width: size, height: size);
    final imageBytes = resizedImage.getBytes(order: img.ChannelOrder.rgb);
    final imageAsList = Float32List(size * size * 3);
    
    int i = 0;
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final pixel = resizedImage.getPixel(x, y);
        imageAsList[i++] = (pixel.r - 127.5) / 128.0;
        imageAsList[i++] = (pixel.g - 127.5) / 128.0;
        imageAsList[i++] = (pixel.b - 127.5) / 128.0;
      }
    }
    return imageAsList;
  }
  
  List<double> _normalize(List<double> vector) {
    double sum = vector.map((e) => e * e).reduce((a, b) => a + b);
    double norm = 1.0 / (sum > 0 ? sum : 1e-12);
    return vector.map((e) => e * norm).toList();
  }
}