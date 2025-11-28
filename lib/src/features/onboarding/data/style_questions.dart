/// Style preference questions data
class StyleQuestion {
  final int id;
  final String question;
  final List<String> choices;

  const StyleQuestion({
    required this.id,
    required this.question,
    required this.choices,
  });
}

const List<StyleQuestion> styleQuestions = [
  StyleQuestion(
    id: 1,
    question: "What's your preferred daily style?",
    choices: [
      'Casual',
      'Streetwear',
      'Classic/Formal',
      'Sporty/Athleisure',
      'Trendy/Fashion-forward',
    ],
  ),
  StyleQuestion(
    id: 2,
    question: 'What colors do you like most?',
    choices: [
      'Neutrals',
      'Earthy',
      'Bold',
      'Pastels',
      'Dark tones',
    ],
  ),
  StyleQuestion(
    id: 3,
    question: "What's your usual environment?",
    choices: [
      'Work/Office',
      'University',
      'Gym',
      'Casual daily outings',
      'Nightlife/Events',
    ],
  ),
  StyleQuestion(
    id: 4,
    question: 'How important is comfort in your outfits?',
    choices: [
      'Extremely important',
      'Mostly important',
      'Balanced',
      'More style than comfort',
      'No preference',
    ],
  ),
  StyleQuestion(
    id: 5,
    question: "What's your budget per outfit?",
    choices: [
      'Low',
      'Low-Mid',
      'Mid',
      'Mid-High',
      'High-end',
    ],
  ),
];
