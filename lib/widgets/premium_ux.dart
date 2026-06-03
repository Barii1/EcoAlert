import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

/// Shows a dialog only for guests (not logged in). Authenticated users —
/// registered or premium — are never blocked by this.
Future<void> showPremiumFeatureDialog(
  BuildContext context, {
  required String featureName,
}) async {
  final auth = context.read<AuthProvider>();
  if (auth.currentRole != UserRole.general) return; // authenticated — let through

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(
          'Sign in required',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Please sign in to access $featureName.\n\nAll registered users get full access to every feature.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Sign In'),
          ),
        ],
      );
    },
  );
}

Future<void> showPlanSelectionSheet(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome to EcoAlert',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 17)),
                    Text('Choose your plan to continue',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Both plans note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.success, size: 14),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'All users get full access — reports, AI models, maps, alerts & more.',
                      style: TextStyle(color: AppColors.success, fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Registered plan
            _PlanCard(
              title: 'Registered',
              price: 'Free',
              highlight: false,
              bullets: const [
                'Post hazard reports',
                'All AI prediction models',
                'Live AQI, weather & flood maps',
                'Real-time alerts & notifications',
                'AI daily brief & chat',
              ],
              onTap: () async {
                await auth.markPlanPromptSeen();
                if (context.mounted) Navigator.pop(context);
              },
              buttonLabel: 'Continue Free',
            ),
            const SizedBox(height: 12),

            // Premium plan
            _PlanCard(
              title: 'Premium',
              price: AppConfig.premiumPriceLabel,
              highlight: true,
              bullets: const [
                'Everything in Registered',
                'Personalised health calibration',
                'Custom AQI thresholds for your conditions',
                'Geo-based alert radius (your zone only)',
                'Priority notifications',
              ],
              onTap: () async {
                await auth.upgradeToPremium();
                await auth.markPlanPromptSeen();
                if (context.mounted) Navigator.pop(context);
              },
              buttonLabel: 'Upgrade — ${AppConfig.premiumPriceLabel}',
            ),
          ],
        ),
      );
    },
  );
}

// ── Health conditions sheet ───────────────────────────────────────────────────

const _kAllConditions = [
  ('Asthma',          Icons.air_rounded,               'Respiratory'),
  ('COPD',            Icons.medical_services_rounded,    'Respiratory'),
  ('Heart Condition', Icons.favorite_rounded,            'Cardiac'),
  ('Hypertension',    Icons.monitor_heart_rounded,       'Cardiac'),
  ('Diabetes',        Icons.water_drop_rounded,          'Metabolic'),
  ('Elderly Care',    Icons.elderly_rounded,             'Sensitive Group'),
  ('Child Care',      Icons.child_care_rounded,          'Sensitive Group'),
  ('Allergies',       Icons.coronavirus_rounded,         'Immune'),
];

Future<void> showHealthConditionsSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => const _HealthConditionsSheet(),
  );
}

class _HealthConditionsSheet extends StatefulWidget {
  const _HealthConditionsSheet();

  @override
  State<_HealthConditionsSheet> createState() => _HealthConditionsSheetState();
}

class _HealthConditionsSheetState extends State<_HealthConditionsSheet> {
  final Set<String> _selected = {};
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    try {
      if (_selected.isNotEmpty) {
        await auth.updateHealthConditions(_selected.toList());
      }
      await auth.markHealthPromptSeen();
    } catch (_) {
      await auth.markHealthPromptSeen();
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _skip() async {
    final auth = context.read<AuthProvider>();
    await auth.markHealthPromptSeen();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.health_and_safety_rounded,
                    color: AppColors.info, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Health Profile',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 17)),
                    Text('Personalise your alerts',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Select any conditions you or your household are medically diagnosed with or sensitive to. This personalises your AQI and weather alerts.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 16),

          // Condition chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kAllConditions.map((c) {
              final label = c.$1;
              final icon  = c.$2;
              final sub   = c.$3;
              final selected = _selected.contains(label);
              return GestureDetector(
                onTap: () => setState(() {
                  selected ? _selected.remove(label) : _selected.add(label);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.info.withOpacity(0.12)
                        : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.info.withOpacity(0.5)
                          : AppColors.borderSubtle,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: 13,
                          color: selected ? AppColors.info : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: TextStyle(
                                  color: selected
                                      ? AppColors.info
                                      : AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal)),
                          Text(sub,
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 9)),
                        ],
                      ),
                      if (selected) ...[
                        const SizedBox(width: 5),
                        const Icon(Icons.check_circle_rounded,
                            size: 12, color: AppColors.info),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Note when something is selected
          if (_selected.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.info.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 12, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your AQI and weather alert thresholds will be calibrated to your profile.',
                      style: TextStyle(
                          color: AppColors.info, fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saving ? null : _skip,
                  child: const Text('Skip for now'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          _selected.isEmpty
                              ? 'None apply — Continue'
                              : 'Save ${_selected.length} condition${_selected.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.bullets,
    required this.highlight,
    required this.onTap,
    required this.buttonLabel,
  });

  final String title;
  final String price;
  final List<String> bullets;
  final bool highlight;
  final VoidCallback onTap;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final borderColor = highlight ? AppColors.primary : AppColors.borderSubtle;
    final accentColor = highlight ? AppColors.primary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withOpacity(0.05)
            : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: highlight ? borderColor : borderColor.withOpacity(0.5),
            width: highlight ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (highlight)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.workspace_premium_rounded,
                          color: AppColors.primary, size: 15),
                    ),
                  Text(title,
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(price,
                    style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 13,
                        color: highlight ? AppColors.primary : AppColors.success),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(b,
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.3)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    highlight ? AppColors.primary : AppColors.bgPrimary,
                foregroundColor:
                    highlight ? Colors.white : AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                side: highlight
                    ? null
                    : const BorderSide(color: AppColors.borderSubtle),
              ),
              onPressed: onTap,
              child: Text(buttonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
