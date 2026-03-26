import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f2323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f2323),
        foregroundColor: Colors.white,
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _Card(
            child: Text(
              'Demo policy summary\n\n'
              '• EcoAlert stores demo profile preferences locally on the device.\n'
              '• Location is used to show map context and geo-warnings (Premium demo).\n'
              '• No backend is connected in this demo build.\n\n'
              'In a production build, this page would include a full privacy policy with data retention, sharing, and user rights.',
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
