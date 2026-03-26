import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f2323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f2323),
        foregroundColor: Colors.white,
        title: const Text('Terms & Conditions'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _Card(
            child: Text(
              'Demo terms summary\n\n'
              '• This app is a demo prototype for showcasing UI and flows.\n'
              '• Alerts and AI analysis are simulated and must not be treated as real emergency guidance.\n'
              '• Always follow official government and emergency services instructions.\n\n'
              'In a production build, this page would include full terms, disclaimers, and liability limits.',
              style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

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
      child: child,
    );
  }
}
