import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';
import '../services/aqi_image_service.dart';

class AqiImageClassifyScreen extends StatefulWidget {
  const AqiImageClassifyScreen({super.key});

  @override
  State<AqiImageClassifyScreen> createState() => _AqiImageClassifyScreenState();
}

class _AqiImageClassifyScreenState extends State<AqiImageClassifyScreen> {
  final _picker = ImagePicker();

  File? _image;
  bool _loading = false;
  AqiImagePrediction? _result;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (picked == null) return;
      setState(() {
        _image = File(picked.path);
        _result = null;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Could not pick image: $e');
    }
  }

  Future<void> _classify() async {
    if (_image == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final prediction = await AqiImageService.predictImage(_image!);
      setState(() {
        _result = prediction;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Color _colorForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('good')) return AppColors.success;
    if (l.contains('moderate')) return const Color(0xFFFFD700);
    if (l.contains('sensitive')) return AppColors.warning;
    if (l.contains('very')) return AppColors.danger;
    if (l.contains('severe')) return AppColors.critical;
    if (l.contains('unhealthy')) return const Color(0xFFFF6D00);
    return AppColors.primary;
  }

  IconData _iconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('good')) return Icons.check_circle_outline_rounded;
    if (l.contains('moderate')) return Icons.warning_amber_rounded;
    if (l.contains('sensitive')) return Icons.accessibility_new_rounded;
    if (l.contains('unhealthy') || l.contains('very') || l.contains('severe')) {
      return Icons.dangerous_rounded;
    }
    return Icons.air_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('AQI Image Scan'),
        backgroundColor: AppColors.bgPrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: AppColors.borderSubtle),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Description
            Container(
              padding: const EdgeInsets.all(AppSpacing.p16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppSpacing.radius16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.info,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Take or pick a sky/outdoor photo to classify air quality using the ML model.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.p20),

            // Image preview area
            GestureDetector(
              onTap: () => _showSourceSheet(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 260,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(AppSpacing.radius20),
                  border: Border.all(
                    color: _image != null
                        ? AppColors.primary.withOpacity(0.4)
                        : AppColors.borderSubtle,
                    width: _image != null ? 1.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _image == null
                    ? _buildEmptyImagePlaceholder()
                    : Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: AppSpacing.p16),

            // Source picker buttons
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_camera_rounded,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.p16),

            // Classify button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _image == null || _loading ? null : _classify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  disabledBackgroundColor: AppColors.bgElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.textInverse,
                        ),
                      )
                    : const Text(
                        'Classify Image',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),

            // Error
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.p16),
              _ErrorCard(message: _error!),
            ],

            // Result
            if (_result != null) ...[
              const SizedBox(height: AppSpacing.p24),
              _ResultCard(
                prediction: _result!,
                colorForLabel: _colorForLabel,
                iconForLabel: _iconForLabel,
              ),
            ],

            const SizedBox(height: AppSpacing.p32),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_a_photo_rounded,
            color: AppColors.textSecondary,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to select an image',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          'JPEG · PNG · WEBP  ·  Max 5MB',
          style: AppTextStyles.label.copyWith(
            color: AppColors.textDisabled,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded,
                    color: AppColors.textPrimary),
                title: Text('Camera',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.textPrimary),
                title: Text('Gallery',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────── SOURCE BUTTON ───────────────────
class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── ERROR CARD ───────────────────
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── RESULT CARD ───────────────────
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.prediction,
    required this.colorForLabel,
    required this.iconForLabel,
  });

  final AqiImagePrediction prediction;
  final Color Function(String) colorForLabel;
  final IconData Function(String) iconForLabel;

  @override
  Widget build(BuildContext context) {
    final color = colorForLabel(prediction.predictedLabel);
    final icon = iconForLabel(prediction.predictedLabel);
    final pct = (prediction.confidence * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'CLASSIFICATION RESULT',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Main result tile
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppSpacing.radius20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prediction.predictedLabel,
                          style: AppTextStyles.headline.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confidence: $pct%',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Confidence bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: prediction.confidence,
                  backgroundColor: AppColors.bgElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        if (prediction.topK.length > 1) ...[
          const SizedBox(height: 16),

          // Top-K breakdown header
          Text(
            'TOP PREDICTIONS',
            style: AppTextStyles.label.copyWith(
              color: AppColors.textDisabled,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: prediction.topK.asMap().entries.map((entry) {
                final idx = entry.key;
                final score = entry.value;
                final c = colorForLabel(score.label);
                final scorePct = (score.confidence * 100).toStringAsFixed(1);
                final isLast = idx == prediction.topK.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              score.label,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: idx == 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          Text(
                            '$scorePct%',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: c,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: score.confidence,
                                backgroundColor: AppColors.bgElevated,
                                valueColor: AlwaysStoppedAnimation<Color>(c),
                                minHeight: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Container(height: 0.5, color: AppColors.borderSubtle),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
