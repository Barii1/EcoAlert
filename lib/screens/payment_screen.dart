import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';

// Benefits pulled directly from profile_screen.dart tier card and locked card text.
const _kBenefits = [
  (Icons.tune_rounded,          'Custom AQI thresholds matched to your health conditions'),
  (Icons.monitor_heart_rounded, 'Health calibration for personalised smog & heatwave alerts'),
  (Icons.my_location_rounded,   'Geo-alert radius — get alerts only within your zone'),
  (Icons.family_restroom_rounded,'Conservative thresholds for children, elderly & cardiac patients'),
];

enum _PayMethod { jazzCash, sadaPay }

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  _PayMethod _selected = _PayMethod.jazzCash;

  void _payNow() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Payment coming soon'),
        backgroundColor: AppColors.bgElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Back row ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Go Premium',
                    style: AppTextStyles.headline.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.p16, 4, AppSpacing.p16, AppSpacing.p24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero section ─────────────────────────────────────────
                    _HeroSection(),

                    const SizedBox(height: AppSpacing.p24),

                    // ── Plan card ─────────────────────────────────────────────
                    _PlanCard(),

                    const SizedBox(height: AppSpacing.p24),

                    // ── Payment method ────────────────────────────────────────
                    Text(
                      'PAYMENT METHOD',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.p10),
                    Row(
                      children: [
                        Expanded(
                          child: _MethodCard(
                            label: 'JazzCash',
                            icon: Icons.account_balance_wallet_rounded,
                            brandColor: const Color(0xFFE31E24),
                            selected: _selected == _PayMethod.jazzCash,
                            onTap: () =>
                                setState(() => _selected = _PayMethod.jazzCash),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.p10),
                        Expanded(
                          child: _MethodCard(
                            label: 'SadaPay',
                            icon: Icons.credit_card_rounded,
                            brandColor: const Color(0xFF00B9AE),
                            selected: _selected == _PayMethod.sadaPay,
                            onTap: () =>
                                setState(() => _selected = _PayMethod.sadaPay),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.p32),

                    // ── Footer ───────────────────────────────────────────────
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              size: 12, color: AppColors.textDisabled),
                          const SizedBox(width: 5),
                          Text(
                            'Secure payment · Cancel anytime',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textDisabled,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Pay Now button (fixed bottom) ─────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.p16, AppSpacing.p12, AppSpacing.p16, AppSpacing.p20),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                border: const Border(
                    top: BorderSide(color: AppColors.borderSubtle, width: 0.5)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: _payNow,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radius12),
                    ),
                    padding: EdgeInsets.zero,
                  ).copyWith(
                    overlayColor: WidgetStateProperty.all(
                        Colors.black.withOpacity(0.07)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded, size: 16, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(
                        'Pay Now  ·  PKR 499',
                        style: AppTextStyles.titleMed.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + tagline
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radius12),
                border: Border.all(color: AppColors.info.withOpacity(0.25)),
              ),
              child: const Icon(Icons.workspace_premium,
                  color: AppColors.info, size: 26),
            ),
            const SizedBox(width: AppSpacing.p14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock all features',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Everything your safety needs',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.p20),

        // Benefits list
        Container(
          padding: const EdgeInsets.all(AppSpacing.p16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppSpacing.radius16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: _kBenefits.map((b) {
              final isLast = b == _kBenefits.last;
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(b.$1,
                            color: AppColors.success, size: 16),
                      ),
                      const SizedBox(width: AppSpacing.p12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            b.$2,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: const Icon(Icons.check_rounded,
                            size: 15, color: AppColors.success),
                      ),
                    ],
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: AppSpacing.p10),
                    const Divider(
                        height: 1, color: AppColors.borderSubtle),
                    const SizedBox(height: AppSpacing.p10),
                  ],
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Plan card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radius16),
        border: Border.all(color: AppColors.success, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'MONTHLY',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.success,
                          fontSize: 9,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SELECTED',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.info,
                          fontSize: 9,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.p8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'PKR 499',
                        style: AppTextStyles.displayMed.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' / month',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Billed monthly · No contract',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 16, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

// ── Payment method card ───────────────────────────────────────────────────────

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.label,
    required this.icon,
    required this.brandColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color brandColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.p16, horizontal: AppSpacing.p12),
        decoration: BoxDecoration(
          color: selected
              ? brandColor.withOpacity(0.08)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radius12),
          border: Border.all(
            color: selected ? brandColor : AppColors.borderSubtle,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 28,
                color: selected ? brandColor : AppColors.textSecondary),
            const SizedBox(height: AppSpacing.p8),
            Text(
              label,
              style: AppTextStyles.titleMed.copyWith(
                color: selected ? brandColor : AppColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
