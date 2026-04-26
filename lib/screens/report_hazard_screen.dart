import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';

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
    setState(() => _isSubmitting = true);
    final ok = await context.read<ReportProvider>().addReport(
          hazardType: _selectedHazard!,
          details: _detailsController.text,
          imageCount: _images.length,
          locationLabel: 'Gulberg III, Lahore',
          reporterUid: auth.currentUser?.id ?? '',
          reporterName: auth.currentUser?.username ?? 'Anonymous',
          images: _images.isNotEmpty ? _images : null,
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
    return Scaffold(
      backgroundColor: const Color(0xFF0f2323),
      body: Column(
        children: [
          // App Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Report Hazard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Safety Warning
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.orange.withOpacity(0.1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ensure your safety before reporting. Do not put yourself in danger to capture evidence.',
                            style: TextStyle(
                              color: Colors.orange[200],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hazard Selector
                        const Text(
                          'What is happening?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.3,
                          ),
                          itemCount: _hazardTypes.length,
                          itemBuilder: (context, index) {
                            final hazard = _hazardTypes.keys.elementAt(index);
                            final icon = _hazardTypes[hazard]!;
                            final isSelected = _selectedHazard == hazard;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedHazard = hazard;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF06e0e0).withOpacity(0.1)
                                      : const Color(0xFF162e2e),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF06e0e0)
                                        : Colors.white.withOpacity(0.1),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF06e0e0)
                                                .withOpacity(0.15),
                                            blurRadius: 15,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isSelected)
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF06e0e0),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            size: 10,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    Icon(
                                      icon,
                                      size: 32,
                                      color: isSelected
                                          ? const Color(0xFF06e0e0)
                                          : Colors.white.withOpacity(0.6),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      hazard,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Evidence Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Evidence',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06e0e0).withOpacity(0.1),
                                border: Border.all(
                                  color:
                                      const Color(0xFF06e0e0).withOpacity(0.2),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: Color(0xFF06e0e0),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'AI VERIFIED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF06e0e0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFF162e2e).withOpacity(0.5),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _images.isEmpty
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Camera',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white60,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 24),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                      const SizedBox(width: 24),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.image,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Gallery',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white60,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _images.length + 1,
                                    itemBuilder: (context, index) {
                                      if (index == _images.length) {
                                        return Container(
                                          width: 80,
                                          margin:
                                              const EdgeInsets.only(left: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white60,
                                          ),
                                        );
                                      }
                                      return Container(
                                        width: 80,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                        const SizedBox(height: 24),
                        // Location
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  color: Color(0xFF06e0e0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF162e2e),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  Icons.location_on,
                                  size: 36,
                                  color: const Color(0xFF06e0e0),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF162e2e)
                                        .withOpacity(0.9),
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.near_me,
                                        size: 20,
                                        color: Colors.white60,
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Near Gulberg III, Lahore',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'Lat: 31.5204, Long: 74.3587',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white60,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Details
                        const Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _detailsController,
                          maxLines: 5,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Describe the severity or impact...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF162e2e),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF06e0e0),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF06e0e0),
            foregroundColor: const Color(0xFF0f2323),
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

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }
}
