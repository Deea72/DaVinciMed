class Option {
  final String ro, en;
  final double weight; // added to log-odds of a severe/3rd-degree burn
  const Option(this.ro, this.en, [this.weight = 0.0]);
  String l(String lang) => lang == 'ro' ? ro : en;
}

class Question {
  final String ro, en;
  final String? hintRo, hintEn;
  final List<Option> options;
  const Question(this.ro, this.en, this.options, {this.hintRo, this.hintEn});
  String q(String lang) => lang == 'ro' ? ro : en;
  String? hint(String lang) => lang == 'ro' ? hintRo : hintEn;
}

const questions = <Question>[
  Question(
    'Selectați gradul de durere resimțit la nivelul arsurii?',
    'Select the level of pain felt in the burn area?',
    [
      Option('0–2 (fără durere / disconfort)', '0–2 (no pain / numbness / discomfort)', 1.2),
      Option('3–4 (durere ușoară)', '3–4 (mild pain)', -0.5),
      Option('5–6 (durere moderată)', '5–6 (moderate pain)', 0.0),
      Option('7–8 (durere puternică)', '7–8 (severe pain)', 0.3),
      Option('9–10 (durere insuportabilă)', '9–10 (unbearable pain)', 0.6),
    ],
    hintRo: 'Amorțeala sau lipsa durerii poate indica o arsură profundă (nervi afectați).',
    hintEn: 'Numbness or lack of pain may indicate a deep burn (damaged nerves).',
  ),
  Question(
    'Este arsura într-o zonă periculoasă/sensibilă (palme, tălpi, față, zona genitală)?',
    'Is the burn in a dangerous/sensitive area (palms, soles, face, genitals)?',
    [
      Option('Da', 'Yes', 1.5),
      Option('Nu', 'No', -0.5),
    ],
    hintRo: 'Arsurile pe zone critice necesită consult medical urgent indiferent de grad.',
    hintEn: 'Burns in critical areas require urgent medical attention regardless of grade.',
  ),
  Question(
    'Care este cauza arsurii?',
    'What caused the burn?',
    [
      Option('Termică (opărire, flacără, atingere suprafață fierbinte)', 'Thermal (scalding, flame, hot surface)', 0.0),
      Option('Chimică (acizi, sodă caustică, înălbitori concentrați / detergenți industriali)', 'Chemical (acids, caustic soda, industrial cleaners)', 1.5),
      Option('Electrică (electrocutare)', 'Electrical (electrocution)', 1.8),
      Option('Radiații (expunere raze UV/X)', 'Radiation (UV / X-ray exposure)', 0.2),
      Option('Altele (frecare, la căzături)', 'Other (friction, falling)', -0.2),
    ],
  ),
  Question(
    'Suprafața arsurii este mai mare de o palmă?',
    'Is the burn area larger than one palm?',
    [
      Option('Da', 'Yes', 1.0),
      Option('Nu', 'No', -0.5),
    ],
    hintRo: 'Palma persoanei (fără degete) reprezintă aproximativ 1% din suprafața corpului.',
    hintEn: "The person's palm represents roughly 1% of total body surface area.",
  ),
  Question(
    'Există vezicule (bășici) mari?',
    'Are there large blisters present?',
    [
      Option('Da', 'Yes', 0.8),
      Option('Nu', 'No', -0.2),
    ],
    hintRo: 'Veziculele indică de regulă o arsură de gradul 2 (grosime parțială).',
    hintEn: 'Blisters usually indicate a second-degree burn (partial thickness).',
  ),
];
