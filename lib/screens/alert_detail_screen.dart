import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';
import 'alerts_screen.dart' show AlertItem;

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final alert = args is AlertItem ? args : _fallbackAlert();

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: AppColors.bgPrimary),
          ),
          // Foreground content
          SafeArea(
            child: Column(
              children: [
                _TopBar(),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _AlertCard(alert: alert),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AlertItem _fallbackAlert() {
    return AlertItem(
      title: 'Flash Flood Warning',
      subtitle: 'Water levels rising faster than predicted due to sudden cloudburst.',
      location: 'Johar Town, Block G',
      timeLabel: 'Live',
      severityLabel: 'Critical Alert',
      severityColor: AppColors.danger,
      icon: Icons.warning,
      iconColor: AppColors.danger,
      gradientColor: AppColors.danger,
      category: 'Flood',
      description: 'Seek higher ground immediately. Avoid basement areas.',
      extraStat: '45mm/hr',
      aqiLabel: '180 Unhealthy',
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'EcoAlert Live Monitor',
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: AppColors.danger),
              const SizedBox(width: 6),
              Text('LIVE FEED', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final AlertItem alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radius16),
        border: Border(
          top: BorderSide(color: alert.severityColor, width: 4),
          left: BorderSide(color: AppColors.borderSubtle),
          right: BorderSide(color: AppColors.borderSubtle),
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: alert.severityColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _BadgeRow(alert: alert),
                const SizedBox(height: 12),
                _TitleBlock(alert: alert),
                const SizedBox(height: 12),
                _AnalysisBox(text: alert.description),
                const SizedBox(height: 12),
                _StatsGrid(alert: alert),
                const SizedBox(height: 12),
                Text(
                  'Seek higher ground immediately. Avoid basement areas.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                _PrimaryButton(
                  label: 'View Safe Routes',
                  icon: Icons.map,
                  onPressed: () => Navigator.pushNamed(context, '/route-info'),
                ),
                const SizedBox(height: 10),
                _GhostButton(
                  label: 'Dismiss (I am safe)',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.alert});
  final AlertItem alert;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF2460D).withOpacity(0.15),
            border: Border.all(color: const Color(0xFFF2460D).withOpacity(0.3)),
          ),
          child: Icon(alert.icon, color: const Color(0xFFF2460D), size: 36),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF2460D).withOpacity(0.12),
            border: Border.all(color: const Color(0xFFF2460D).withOpacity(0.3)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.shield, color: Color(0xFFF2460D), size: 18),
              SizedBox(width: 6),
              Text(
                'Critical Alert',
                style: TextStyle(
                  color: Color(0xFFF2460D),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.alert});
  final AlertItem alert;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          alert.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, size: 16, color: Color(0xFFbaa39c)),
            const SizedBox(width: 6),
            Text(
              alert.location,
              style: const TextStyle(color: Color(0xFFbaa39c), fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnalysisBox extends StatelessWidget {
  const _AnalysisBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF221410),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF54413b)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.smart_toy, color: Color(0xFFF2460D), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Analysis',
                  style: TextStyle(color: Color(0xFFF2460D), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.alert});
  final AlertItem alert;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Rainfall',
            value: alert.extraStat ?? '—',
            accent: Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'AQI Level',
            value: alert.aqiLabel ?? '180',
            accent: Colors.orangeAccent,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.accent});
  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF221410),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF54413b)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFFbaa39c), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.8,
              child: Container(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF2460D),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        shadowColor: const Color(0xFFF2460D).withOpacity(0.4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFFbaa39c), fontWeight: FontWeight.w600),
      ),
    );
  }
}
