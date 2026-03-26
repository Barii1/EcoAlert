import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _cityController = TextEditingController();
  bool _useCurrentLocation = false;
  final Set<String> _selectedHealthConditions = {'Asthma'}; // Pre-select Asthma

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setBool('profile_setup_complete', true);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _toggleHealthCondition(String condition) {
    setState(() {
      if (_selectedHealthConditions.contains(condition)) {
        _selectedHealthConditions.remove(condition);
      } else {
        _selectedHealthConditions.add(condition);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f2323),
      body: Stack(
        children: [
          // Main scrollable content
          SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              padding: const EdgeInsets.only(bottom: 120), // Space for fixed footer
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Personalize Alerts',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: _completeSetup,
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: Color(0xFF007f80),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location section
                          const Text(
                            'Where should we monitor?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Get real-time updates for your area.',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // GPS button
                          InkWell(
                            onTap: () {
                              setState(() {
                                _useCurrentLocation = true;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF162e2e),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _useCurrentLocation
                                      ? const Color(0xFF007f80)
                                      : Colors.grey[800]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.my_location,
                                    color: Color(0xFF007f80),
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Use my current location',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // City search input
                          TextField(
                            controller: _cityController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search city (e.g. Lahore, Karachi)',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[600],
                              ),
                              filled: true,
                              fillColor: const Color(0xFF162e2e),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey[800]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey[800]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF007f80),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Health section
                          Row(
                            children: [
                              const Text(
                                'Health sensitivities ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '(Optional)',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'We\'ll prioritize smog & AQI alerts if you or your family have specific health concerns.',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Health chips grid
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildHealthChip('Asthma'),
                              _buildHealthChip('Heart Condition'),
                              _buildHealthChip('Pregnancy'),
                              _buildHealthChip('Elderly'),
                              _buildHealthChip('Pollen Allergy'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Fixed footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0f2323).withOpacity(0.95),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[900]!,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(24.0),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Privacy note
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Health data stays on your device',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Complete button
                    ElevatedButton(
                      onPressed: _completeSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007f80),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        shadowColor: const Color(0xFF007f80).withOpacity(0.25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Complete Setup',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthChip(String condition) {
    final isSelected = _selectedHealthConditions.contains(condition);

    return InkWell(
      onTap: () => _toggleHealthCondition(condition),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF007f80).withOpacity(0.1)
              : const Color(0xFF162e2e),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF007f80)
                : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              condition,
              style: TextStyle(
                color: isSelected ? const Color(0xFF007f80) : Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check,
                color: Color(0xFF007f80),
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
