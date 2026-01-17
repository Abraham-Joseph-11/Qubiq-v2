import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class RobotBrain {
  Interpreter? _interpreter;
  final Map<String, List<List<double>>> _memory = {};

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/mobilenet_feature.tflite');
    } catch (e) {
      print("Error loading brain: $e");
    }
  }

  List<double> _getFingerprint(img.Image image) {
    img.Image resized = img.copyResize(image, width: 224, height: 224);
    var input = List.generate(1, (i) => List.generate(224, (y) => List.generate(224, (x) {
      var pixel = resized.getPixel(x, y);
      return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
    })));
    var output = List.filled(1 * 1280, 0.0).reshape([1, 1280]);
    _interpreter!.run(input, output);
    return List<double>.from(output[0]);
  }

  Future<void> teach(img.Image image, String label) async {
    List<double> fingerprint = _getFingerprint(image);
    if (!_memory.containsKey(label)) _memory[label] = [];
    _memory[label]!.add(fingerprint);
  }

  Map<String, dynamic> guess(img.Image image) {
    if (_memory.isEmpty) return {};
    List<double> currentFingerprint = _getFingerprint(image);
    String bestLabel = "Unknown";
    double minDistance = double.infinity;

    _memory.forEach((label, examples) {
      for (var example in examples) {
        double dist = _euclideanDistance(currentFingerprint, example);
        if (dist < minDistance) {
          minDistance = dist;
          bestLabel = label;
        }
      }
    });

    double confidence = (1.0 - (minDistance / 10.0)).clamp(0.0, 1.0);
    return {'label': bestLabel, 'confidence': confidence};
  }

  double _euclideanDistance(List<double> a, List<double> b) {
    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      sum += pow((a[i] - b[i]), 2);
    }
    return sqrt(sum);
  }

  int getCount(String label) => _memory[label]?.length ?? 0;
}