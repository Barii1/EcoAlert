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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  'Information We Collect',
                  '• Email Address: Used for account creation, password recovery, and notifications.\n'
                  '• Phone Number: Collected for future SMS alert features and account verification.\n'
                  '• Location Data: GPS coordinates are collected to provide location-specific hazard predictions.\n'
                  '• CNIC / National ID: Hashed and encrypted. Raw value is never stored.\n'
                  '• App Usage Data: We collect anonymized data about how you use EcoAlert to improve the service.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'How We Use Your Information',
                  '• Location data is used to fetch hazard predictions for your area.\n'
                  '• Email is used to send you important account notifications and password reset links.\n'
                  '• Phone number will be used to send SMS alerts when major hazards are predicted.\n'
                  '• Usage data helps us improve alert accuracy and app performance.\n'
                  '• We do NOT use your data for marketing or advertising purposes.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'Data Security',
                  'Your data is stored on Google Firebase with enterprise-grade encryption. '
                  'CNIC numbers are hashed using SHA-256 and cannot be reversed. '
                  'All communications between your device and our servers use HTTPS encryption. '
                  'We implement strict access controls and regularly audit our systems.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'Data Retention',
                  'Your account data is retained as long as your account is active. '
                  'If you delete your account, all personal data will be permanently removed within 30 days, '
                  'except where required by Pakistani law or court orders.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'Third-Party Services',
                  'EcoAlert uses Google Firebase (Google Cloud), Google Maps, and Mapbox services. '
                  'These services have their own privacy policies. We do not sell or share your personal data with other third parties. '
                  'We do not use tracking pixels, cookies, or any cross-app tracking.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'Your Rights',
                  '• You have the right to access your personal data at any time.\n'
                  '• You can request correction of inaccurate data.\n'
                  '• You can request deletion of your account and associated data.\n'
                  '• You can opt out of SMS alerts in your account settings.\n'
                  '• You have the right to file a complaint with Pakistan\'s privacy authorities.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'Contact Us',
                  'If you have questions about this privacy policy or your data, please contact us at privacy@ecoalert.app. '
                  'We will respond to privacy inquiries within 15 business days.',
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
