import 'package:flutter/material.dart';

class GuideDetailScreen extends StatelessWidget {
  const GuideDetailScreen({
    super.key,
    required this.title,
    required this.category,
    required this.readTimeLabel,
  });

  final String title;
  final String category;
  final String readTimeLabel;

  @override
  Widget build(BuildContext context) {
    final content = _contentFor(title: title, category: category);

    return Scaffold(
      backgroundColor: const Color(0xFF0f2323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f2323),
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF162e2e),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.access_time, size: 16, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(
                readTimeLabel,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Summary',
            child: Text(
              content.summary,
              style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          ...content.sections.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SectionCard(
                title: s.title,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final step in s.steps)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06e0e0).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF06e0e0).withOpacity(0.25)),
                              ),
                              child: const Icon(Icons.check, size: 14, color: Color(0xFF06e0e0)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                step,
                                style: TextStyle(color: Colors.white.withOpacity(0.82), height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF162e2e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _GuideContent {
  const _GuideContent({required this.summary, required this.sections});

  final String summary;
  final List<_GuideSection> sections;
}

class _GuideSection {
  const _GuideSection({required this.title, required this.steps});

  final String title;
  final List<String> steps;
}

_GuideContent _contentFor({required String title, required String category}) {
  if (category == 'Flood') {
    return const _GuideContent(
      summary:
          'Flood risk can change quickly after heavy rain or a cloudburst. Use this step-by-step guide to prepare early, stay safe during flooding, and recover after water recedes.',
      sections: [
        _GuideSection(
          title: 'Before (Preparation)',
          steps: [
            'Save emergency numbers and share a meetup point with family.',
            'Prepare a go-bag: water, snacks, torch, power bank, meds, copies of IDs.',
            'Move valuables and electrical items above floor level.',
            'Know 2 safe routes to higher ground; avoid underpasses and canals.',
          ],
        ),
        _GuideSection(
          title: 'During (Response)',
          steps: [
            'Do not walk or drive through flood water. Turn around if the road is flooded.',
            'If water enters your home, switch off electricity only if safe to reach the main switch.',
            'Move to higher floors/roof access if needed and call for help early.',
            'Keep children away from drains; fast water can pull them in.',
          ],
        ),
        _GuideSection(
          title: 'After (Recovery)',
          steps: [
            'Avoid contaminated water; wear gloves/boots while cleaning.',
            'Do not turn power back on until wiring is dry and checked.',
            'Discard food that touched flood water; boil drinking water if unsure.',
            'Document damage with photos for records and repairs.',
          ],
        ),
      ],
    );
  }

  if (category == 'Smog/AQI') {
    return const _GuideContent(
      summary:
          'Poor air quality increases breathing and heart risks. Use these steps to reduce exposure and protect vulnerable family members.',
      sections: [
        _GuideSection(
          title: 'Reduce Exposure',
          steps: [
            'Check AQI before going out; avoid outdoor exercise when AQI is high.',
            'Wear a well-fitted N95/KN95 mask when outside.',
            'Keep windows closed during peak smog; ventilate when AQI improves.',
          ],
        ),
        _GuideSection(
          title: 'Home Protection',
          steps: [
            'Use a fan with a clean filter or air purifier if available.',
            'Wet-mop floors and wipe surfaces to reduce indoor dust.',
            'Keep children and elderly indoors when visibility is low.',
          ],
        ),
      ],
    );
  }

  if (category == 'Heatwave') {
    return const _GuideContent(
      summary:
          'Heatwaves can cause dehydration and heatstroke quickly. Follow these steps to stay cool and recognize danger signs early.',
      sections: [
        _GuideSection(
          title: 'Stay Cool',
          steps: [
            'Drink water regularly even if you are not thirsty.',
            'Avoid outdoor work during noon; take breaks in shade.',
            'Wear light clothing; use a damp cloth to cool the skin.',
          ],
        ),
        _GuideSection(
          title: 'Watch for Heatstroke',
          steps: [
            'Danger signs: confusion, fainting, very hot skin, rapid pulse.',
            'Move the person to shade, cool them with water/fan, and seek medical help.',
          ],
        ),
      ],
    );
  }

  // Cloudburst or default
  return const _GuideContent(
    summary:
        'Sudden heavy rainfall can flood streets in minutes. Use this quick guide to avoid high-risk routes and stay safe.',
    sections: [
      _GuideSection(
        title: 'Immediate Actions',
        steps: [
          'Avoid underpasses, bridges, and roads near drains/canals.',
          'Delay travel if possible; if you must travel, take main roads and move slowly.',
          'Keep your phone charged and share your location with family.',
        ],
      ),
      _GuideSection(
        title: 'If You’re Stuck',
        steps: [
          'Stay in a safe high place; call emergency services early.',
          'Do not enter moving water; it can sweep you away.',
        ],
      ),
    ],
  );
}
