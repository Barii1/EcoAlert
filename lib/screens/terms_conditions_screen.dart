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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  'Disclaimer',
                  'EcoAlert provides environmental hazard predictions and alerts to help users stay informed and safe. '
                  'Our alerts are AI-generated predictions based on available data and are NOT official government warnings. '
                  'Always follow instructions from Pakistan Meteorological Department (PMD), National Disaster Management Authority (NDMA), '
                  'and local emergency services. EcoAlert is not liable for any loss, injury, or damage resulting from actions taken or not taken based on our alerts.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'Data Collection',
                  'EcoAlert collects your location data to provide location-specific hazard alerts. '
                  'We collect your email for account recovery. Your CNIC (National ID) is hashed and never stored in plain text. '
                  'Phone number is used for future SMS alert features. Data is stored securely on Firebase and is never sold to third parties.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'Acceptable Use',
                  '• You may not use EcoAlert to harass, threaten, or harm others.\n'
                  '• You may not submit false or misleading hazard reports.\n'
                  '• You may not reverse-engineer, decompile, or attempt to access our proprietary systems.\n'
                  '• You may not use automated tools to scrape our app or servers.\n'
                  '• You may not resell or republish EcoAlert content without permission.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'User Responsibilities',
                  '• You are responsible for maintaining the confidentiality of your account credentials.\n'
                  '• You agree to provide accurate and complete information during signup.\n'
                  '• You are responsible for all activities that occur under your account.\n'
                  '• You agree to keep your contact information up to date.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'Limitation of Liability',
                  'EcoAlert is provided on an "AS-IS" basis. We make no warranties that our app will be error-free, uninterrupted, or fit for your specific purposes. '
                  'To the maximum extent permitted by Pakistani law, EcoAlert and its creators shall not be liable for any indirect, incidental, special, consequential, or punitive damages.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'Changes to Terms',
                  'We reserve the right to modify these Terms and Conditions at any time. Your continued use of EcoAlert constitutes acceptance of updated terms. '
                  'Material changes will be notified to users via in-app notification or email.',
                ),
                const SizedBox(height: 16),
                Text(
                  'Last updated: April 2026',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
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
