class GuideSection {
  const GuideSection({required this.heading, required this.steps});

  final String heading;
  final List<String> steps;
}

class GuideContent {
  const GuideContent({required this.title, required this.sections});

  final String title;
  final List<GuideSection> sections;
}
