import 'dart:math';

import 'questions.dart';

class BurnAssessment {
  final List<double> modelProbs; // image model only [g1, g2, g3]
  final List<double> finalProbs; // final decision [g1, g2, g3]
  final double questionnaireScore;
  final bool urgent;
  final String source; // 'jev' or 'local'
  const BurnAssessment(this.modelProbs, this.finalProbs, this.questionnaireScore, this.urgent,
      {this.source = 'local'});

  int get predictedDegree => finalProbs.indexOf(finalProbs.reduce(max)) + 1;
  double get confidence => finalProbs[predictedDegree - 1];
}

/// Emergency flags that never depend on an external service (question order in
/// questions.dart): Q2 = dangerous area (0 = Yes), Q3 = cause (1 chemical, 2 electrical).
bool urgentFlags(List<int> answers, double grade3Prob) =>
    answers[1] == 0 || answers[2] == 1 || answers[2] == 2 || grade3Prob >= 0.5;

/// Result decided by the Jev model.
BurnAssessment fromJev(List<double> modelProbs, List<double> jevProbs, List<int> answers) =>
    BurnAssessment(modelProbs, jevProbs, 0, urgentFlags(answers, jevProbs[2]), source: 'jev');

/// LOCAL FALLBACK (used when Jev is unreachable): answer weights from questions.dart are
/// summed and added to the log-odds of grade 3, then softmax. Placeholder weights.
BurnAssessment combine(List<double> modelProbs, List<int> answers) {
  var score = 0.0;
  for (var i = 0; i < questions.length; i++) {
    score += questions[i].options[answers[i]].weight;
  }
  final logits = [for (final p in modelProbs) log(p.clamp(1e-6, 1.0))];
  logits[2] += score;
  final m = logits.reduce(max);
  final exps = [for (final l in logits) exp(l - m)];
  final sum = exps.reduce((a, b) => a + b);
  final finalProbs = [for (final e in exps) e / sum];
  return BurnAssessment(modelProbs, finalProbs, score, urgentFlags(answers, finalProbs[2]));
}
