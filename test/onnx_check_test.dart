import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/classifier.dart';

void main() {
  test('OnnxBurnClassifierService instantiation test', () {
    final service = OnnxBurnClassifierService();
    expect(service, isNotNull);
  });
}
