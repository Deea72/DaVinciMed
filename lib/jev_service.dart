import 'package:supabase_flutter/supabase_flutter.dart';

import 'questions.dart';

/// Sends the image-model probabilities + the questionnaire answers to the
/// "Jev" model through a Supabase Edge Function (the API key stays on the server).
/// Payload shape = test_with_jev.py. The question/answer text is always Romanian.
class JevService {
  double _r4(double v) => (v * 10000).round() / 10000;

  Future<List<double>> decide({
    required List<double> visionProbs,
    required double brightness,
    required List<int> answers,
  }) async {
    final payload = {
      'vision_output': {
        'status': 'ok',
        'probabilities': {
          'degree_1': _r4(visionProbs[0]),
          'degree_2': _r4(visionProbs[1]),
          'degree_3': _r4(visionProbs[2]),
        },
        'image_brightness': (brightness * 10).round() / 10,
      },
      'chestionar': [
        for (var i = 0; i < questions.length; i++)
          {
            'intrebare': '${i + 1}. ${questions[i].ro}',
            'raspuns': questions[i].options[answers[i]].ro,
          }
      ],
    };

    final res = await Supabase.instance.client.functions
        .invoke('burn-decision', body: payload)
        .timeout(const Duration(seconds: 25));

    final data = res.data as Map<String, dynamic>;
    final p = (data['answers']['final_burn_classification']['probabilities']) as Map;
    final probs = [
      (p['Grad I'] as num).toDouble(),
      (p['Grad II'] as num).toDouble(),
      (p['Grad III'] as num).toDouble(),
    ];
    final sum = probs.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) throw Exception('Jev returned empty probabilities');
    return [for (final v in probs) v / sum];
  }
}
