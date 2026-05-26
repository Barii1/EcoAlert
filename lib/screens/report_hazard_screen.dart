import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../models/user_model.dart';
import '../providers/aqi_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/report_provider.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';

class ReportHazardScreen extends StatefulWidget {
  const ReportHazardScreen({super.key});

  @override
  State<ReportHazardScreen> createState() => _ReportHazardScreenState();
}

class _ReportHazardScreenState extends State<ReportHazardScreen> {
  String? _selectedHazard;
  final List<File> _images = [];
  final TextEditingController _detailsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _didPrefillFromRoute = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LocationProvider>().getCurrentLocation();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = context.read<AuthProvider>().currentRole;
      if (role != UserRole.general) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Guest users can’t report hazards. Please sign in to continue.',
          ),
        ),
      );

      Navigator.of(context).maybePop();
    });
  }

  final Map<String, IconData> _hazardTypes = {
    'Flood': Icons.flood,
    'Smog / AQI': Icons.air,
    'Cloudburst': Icons.thunderstorm,
    'Heatwave': Icons.thermostat,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefillFromRoute) return;
    _didPrefillFromRoute = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map<String, dynamic>) return;

    final rawType = (args['type'] as String?)?.toLowerCase();
    if (rawType == 'air_quality') {
      _selectedHazard = 'Smog / AQI';
    } else if (rawType == 'flood') {
      _selectedHazard = 'Flood';
    } else if (rawType == 'heatwave') {
      _selectedHazard = 'Heatwave';
    } else if (rawType == 'cloudburst') {
      _selectedHazard = 'Cloudburst';
    }

    final details = args['description'] as String?;
    if (details != null && details.isNotEmpty) {
      _detailsController.text = details;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _images.add(File(image.path));
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF162e2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF06e0e0)),
              title:
                  const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFF06e0e0)),
              title:
                  const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_selectedHazard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a hazard type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_isSubmitting) return;

    final auth = context.read<AuthProvider>();
    final reading = context.read<AqiProvider>().current;
    int? reportAqi;
    String? reportPollutant;
    double? reportConfidence;
    if (_selectedHazard == 'Smog / AQI' && reading != null) {
      reportAqi = reading.aqi;
      reportPollutant = reading.dominantPollutantLabel;
      reportConfidence = null;
    }

    setState(() => _isSubmitting = true);
    final location = context.read<LocationProvider>();
    final locationLabel = location.currentArea.isNotEmpty
      ? location.currentArea
      : (auth.currentUser?.city ?? 'Unknown');
    final pos = location.currentPosition;
    final coords = pos == null
      ? null
      : '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
    final ok = await context.read<ReportProvider>().addReport(
          hazardType: _selectedHazard!,
          details: _detailsController.text,
          imageCount: _images.length,
        locationLabel: coords == null ? locationLabel : '$locationLabel ($coords)',
          reporterUid: auth.currentUser?.id ?? '',
          reporterName: auth.currentUser?.username ?? 'Anonymous',
          images: _images.isNotEmpty ? _images : null,
          aqi: reportAqi,
          mainPollutant: reportPollutant,
          confidence: reportConfidence,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!ok) {
      final error = context.read<ReportProvider>().errorMessage ??
          'Could not submit report. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/report-confirmation',
      arguments: {
        'hazardType': _selectedHazard,
        'details': _detailsController.text,
        'imageCount': _images.length,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();
    final locationLabel = location.currentArea.isNotEmpty
        ? location.currentArea
        : 'Location unavailable';
    final pos = location.currentPosition;
    final coordLabel = pos == null
        ? 'Tap refresh to update'
        : '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Report Hazard',
                        style: AppTextStyles.headlinePrimary
                            .copyWith(fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppColors.warning, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Ensure your safety before reporting. Do not put yourself in danger to capture evidence.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('What is happening?',
                          style: AppTextStyles.titleMedPrimary
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.25,
                        ),
                        itemCount: _hazardTypes.length,
                        itemBuilder: (context, index) {
                          final hazard = _hazardTypes.keys.elementAt(index);
                          final icon = _hazardTypes[hazard]!;
                          final isSelected = _selectedHazard == hazard;

                          return InkWell(
                            onTap: () => setState(() => _selectedHazard = hazard),
                            child: AppCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: AnimatedOpacity(
                                      opacity: isSelected ? 1 : 0,
                                      duration: const Duration(milliseconds: 150),
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Icon(icon,
                                      size: 30,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondary),
                                  const SizedBox(height: 8),
                                  Text(
                                    hazard,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isSelected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Evidence',
                              style: AppTextStyles.titleMedPrimary
                                  .copyWith(fontWeight: FontWeight.w700)),
                          Text('Optional',
                              style: AppTextStyles.labelSecondary.copyWith(
                                  letterSpacing: 0.6, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _showImageSourceDialog,
                        child: AppCard(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            height: 120,
                            child: _images.isEmpty
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _iconTile(Icons.camera_alt, 'Camera'),
                                      const SizedBox(width: 24),
                                      _iconTile(Icons.image, 'Gallery'),
                                    ],
                                  )
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.all(6),
                                    itemCount: _images.length + 1,
                                    itemBuilder: (context, index) {
                                      if (index == _images.length) {
                                        return Container(
                                          width: 80,
                                          margin: const EdgeInsets.only(left: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppColors.borderSubtle,
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: AppColors.textSecondary,
                                          ),
                                        );
                                      }
                                      return Container(
                                        width: 80,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          image: DecorationImage(
                                            image: FileImage(_images[index]),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Location',
                              style: AppTextStyles.titleMedPrimary
                                  .copyWith(fontWeight: FontWeight.w700)),
                          TextButton.icon(
                            onPressed: location.isLoading
                                ? null
                                : () => location.getCurrentLocation(),
                            icon: const Icon(Icons.my_location, size: 16),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.near_me,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(locationLabel,
                                      style: AppTextStyles.bodyPrimary.copyWith(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                    coordLabel,
                                    style: AppTextStyles.bodySmallSecondary,
                                  ),
                                ],
                              ),
                            ),
                            if (location.isLoading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Details',
                          style: AppTextStyles.titleMedPrimary
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _detailsController,
                        maxLines: 5,
                        style: AppTextStyles.bodyPrimary,
                        decoration: InputDecoration(
                          hintText: 'Describe the severity or impact…',
                          hintStyle: AppTextStyles.bodySmallSecondary,
                          filled: true,
                          fillColor: AppColors.bgCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.borderSubtle,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.borderSubtle,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          onPressed: _isSubmitting ? null : _submitReport,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSubmitting) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
              ] else ...[
                const Icon(Icons.send, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                _isSubmitting ? 'Submitting...' : 'Submit Report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _iconTile(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Icon(icon, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            )),
      ],
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }
}
