import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

/// Thrown when the image is too dark to classify reliably.
class PhotoTooDarkException implements Exception {
  final double brightness;
  const PhotoTooDarkException(this.brightness);

  @override
  String toString() => 'PhotoTooDarkException: brightness=$brightness';
}

/// Output of burn_classifier_v2_probs.onnx (already softmax).
/// Index 0 = grade 1, 1 = grade 2, 2 = grade 3.
/// [brightness] is the mean luminance of the resized image in [0, 255].
class BurnClassificationResult {
  final List<double> probabilities;
  final double brightness;

  const BurnClassificationResult(this.probabilities, this.brightness);

  int get predictedDegree {
    var best = 0;
    for (var i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > probabilities[best]) best = i;
    }
    return best + 1;
  }

  double get confidence => probabilities[predictedDegree - 1];
}

class OnnxBurnClassifierService {
  static const _asset = 'assets/models/burn_classifier_v2_probs.onnx';
  static const _size = 224;

  // ASSUMPTION: torchvision-style preprocessing (RGB, /255, ImageNet mean/std).
  // The ONNX graph has no normalization inside, so these MUST match the training
  // code. If your teammate trained differently, change only these two lines.
  static const _mean = [0.485, 0.456, 0.406];
  static const _std = [0.229, 0.224, 0.225];

  static OrtSession? _session;

  Future<OrtSession> _load() => OnnxRuntime().createSessionFromAsset(_asset);

  Future<BurnClassificationResult> classifyImageFile(File file) async {
    final session = _session ??= await _load();

    final decoded = img.decodeImage(await file.readAsBytes());
    if (decoded == null) throw Exception('Cannot decode image');
    final resized = img.copyResize(img.bakeOrientation(decoded),
        width: _size, height: _size, interpolation: img.Interpolation.linear);

    // Compute mean luminance (0–255) before normalisation.
    double lumSum = 0;
    const plane = _size * _size;
    for (var y = 0; y < _size; y++) {
      for (var x = 0; x < _size; x++) {
        final p = resized.getPixel(x, y);
        lumSum += 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      }
    }
    final brightness = lumSum / plane;

    // NCHW float32: [1, 3, 224, 224]
    final data = Float32List(3 * _size * _size);
    for (var y = 0; y < _size; y++) {
      for (var x = 0; x < _size; x++) {
        final p = resized.getPixel(x, y);
        final i = y * _size + x;
        data[i] = (p.r / 255.0 - _mean[0]) / _std[0];
        data[plane + i] = (p.g / 255.0 - _mean[1]) / _std[1];
        data[2 * plane + i] = (p.b / 255.0 - _mean[2]) / _std[2];
      }
    }

    final input = await OrtValue.fromList(data, [1, 3, _size, _size]);
    final outputs = await session.run({'image': input});
    final raw = await outputs['probabilities']!.asList();

    await input.dispose();
    for (final o in outputs.values) {
      await o.dispose();
    }

    return BurnClassificationResult(_flatten(raw), brightness);
  }

  // Output shape is [1, 3]; works whether the plugin returns nested or flat lists.
  List<double> _flatten(List<dynamic> v) => [
        for (final e in v)
          if (e is List) ..._flatten(e) else (e as num).toDouble()
      ];
}
