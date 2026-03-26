import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flood_model.dart';
import '../providers/flood_provider.dart';
import '../widgets/surface_card.dart';

class FloodDetailScreen extends StatelessWidget {
  const FloodDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    FloodRisk? risk;
    if (args is FloodRisk) {
      risk = args;
    } else {
      risk = context.read<FloodProvider>().risk;
    }
    if (risk == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flood Risk')),
        body: const Center(child: Text('No flood risk data')),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Flood Risk'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              risk.city,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 24),
            _buildRiskHero(context, risk),
            const SizedBox(height: 16),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explanation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(risk.explanation, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Updated ${_formatTime(risk.calculatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildRainfallCard(context, risk),
            if (risk.affectedAreas.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildAffectedAreas(context, risk),
            ],
            const SizedBox(height: 16),
            _buildSafetySteps(context, risk),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskHero(BuildContext context, FloodRisk risk) {
    return SurfaceCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${risk.riskScore}%',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: risk.color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                risk.levelLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: risk.color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: risk.riskScore / 100,
              backgroundColor: risk.color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(risk.color),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRainfallCard(BuildContext context, FloodRisk risk) {
    final r = risk.rainfall;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rainfall Data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _rainRow(context, Icons.water_drop, '24h total', '${r.mm24h.toStringAsFixed(1)} mm'),
          _rainRow(context, Icons.speed, 'Intensity', '${r.mmPerHour.toStringAsFixed(1)} mm/hr'),
          _rainRow(context, Icons.calendar_today, '48h total', '${r.mm48h.toStringAsFixed(1)} mm'),
        ],
      ),
    );
  }

  Widget _rainRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }

  Widget _buildAffectedAreas(BuildContext context, FloodRisk risk) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Affected Areas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...risk.affectedAreas.map((area) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text(area, style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSafetySteps(BuildContext context, FloodRisk risk) {
    final steps = <String>[];
    switch (risk.level) {
      case FloodRiskLevel.low:
        steps.addAll(['Monitor local news', 'Keep emergency contacts ready']);
        break;
      case FloodRiskLevel.moderate:
        steps.addAll(['Avoid low-lying areas', 'Prepare emergency kit']);
        break;
      case FloodRiskLevel.high:
        steps.addAll([
          'Avoid all flood-prone zones',
          'Move valuables to higher floors',
          'Keep car fuelled',
        ]);
        break;
      case FloodRiskLevel.critical:
        steps.addAll([
          'EVACUATE immediately if instructed',
          'Call 1122',
          'Do not walk or drive through floodwater',
        ]);
        break;
    }
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Text(
                'Safety Steps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(s, style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final d = now.difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
