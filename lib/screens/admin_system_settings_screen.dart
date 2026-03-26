import 'package:flutter/material.dart';

class AdminSystemSettingsScreen extends StatefulWidget {
  const AdminSystemSettingsScreen({super.key});

  @override
  State<AdminSystemSettingsScreen> createState() =>
      _AdminSystemSettingsScreenState();
}

class _AdminSystemSettingsScreenState extends State<AdminSystemSettingsScreen> {
  double _aqiThreshold = 150.0;
  String _floodSensitivity = 'Med';
  bool _autoApproveLowRisk = true;
  bool _debugLogging = false;
  bool _openWeatherEnabled = true;
  bool _localSensorEnabled = false;
  String _syncInterval = '30 mins';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f2323),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0f2323).withOpacity(0.95),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Console',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          'System Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF06e0e0).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF06e0e0).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF06e0e0),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alert Thresholds
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF162e2e),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.tune,
                                color: Color(0xFF06e0e0),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Alert Thresholds',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Global AQI Trigger',
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF06e0e0).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_aqiThreshold.toInt()}+',
                                  style: const TextStyle(
                                    color: Color(0xFF06e0e0),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _aqiThreshold,
                            min: 0,
                            max: 500,
                            activeColor: const Color(0xFF06e0e0),
                            inactiveColor: Colors.grey[700],
                            onChanged: (value) {
                              setState(() {
                                _aqiThreshold = value;
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '0',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '250',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '500',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 1,
                            color: Colors.white.withOpacity(0.05),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Flood Risk Sensitivity',
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Model trigger variance',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    _buildSensitivityButton('Low', 'Low'),
                                    _buildSensitivityButton('Med', 'Med'),
                                    _buildSensitivityButton('High', 'High'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Data Sources
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF162e2e),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.hub,
                                color: Color(0xFF06e0e0),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Data Sources',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDataSourceTile(
                            'OpenWeather API',
                            'Status: Active',
                            Colors.blue,
                            Icons.cloud,
                            _openWeatherEnabled,
                            (value) {
                              setState(() {
                                _openWeatherEnabled = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDataSourceTile(
                            'Local Sensor Net',
                            'Status: Idle',
                            Colors.orange,
                            Icons.sensors,
                            _localSensorEnabled,
                            (value) {
                              setState(() {
                                _localSensorEnabled = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 1,
                            color: Colors.white.withOpacity(0.05),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sync Interval',
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  value: _syncInterval,
                                  dropdownColor: const Color(0xFF162e2e),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  underline: Container(),
                                  items: ['15 mins', '30 mins', '1 hour', '6 hours']
                                      .map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _syncInterval = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // AI Configuration
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0f2323), Color(0xFF1a3838)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF06e0e0).withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.psychology,
                                    color: Color(0xFF06e0e0),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'AI Configuration',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF06e0e0).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF06e0e0).withOpacity(0.2),
                                  ),
                                ),
                                child: const Text(
                                  'v2.4.0',
                                  style: TextStyle(
                                    color: Color(0xFF06e0e0),
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildAISettingTile(
                            'Auto-Approve Low Risk',
                            'Bypass manual review for < 20% risk',
                            _autoApproveLowRisk,
                            (value) {
                              setState(() {
                                _autoApproveLowRisk = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildAISettingTile(
                            'Debug Logging',
                            'Store raw inference data',
                            _debugLogging,
                            (value) {
                              setState(() {
                                _debugLogging = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Settings saved (Demo)'),
                              backgroundColor: Color(0xFF06e0e0),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06e0e0),
                          foregroundColor: const Color(0xFF0f2323),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF06e0e0).withOpacity(0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0f2323).withOpacity(0.95),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                  top: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.dashboard, 'Home', false, () {
                      Navigator.pop(context);
                    }),
                    _buildNavItem(Icons.map, 'Map', false, () {}),
                    _buildNavItem(Icons.assignment, 'Reports', false, () {}, hasNotification: true),
                    _buildNavItem(Icons.settings, 'Settings', true, () {}),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensitivityButton(String label, String value) {
    final isSelected = _floodSensitivity == value;
    return InkWell(
      onTap: () {
        setState(() {
          _floodSensitivity = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.black
                : Colors.grey[400],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDataSourceTile(
    String title,
    String subtitle,
    Color iconColor,
    IconData icon,
    bool enabled,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: enabled ? Colors.green : Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: enabled,
          onChanged: onChanged,
          activeColor: const Color(0xFF06e0e0),
        ),
      ],
    );
  }

  Widget _buildAISettingTile(
    String title,
    String subtitle,
    bool enabled,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: enabled,
          onChanged: onChanged,
          activeColor: const Color(0xFF06e0e0),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap, {
    bool hasNotification = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF06e0e0) : Colors.grey[400],
                  size: 24,
                ),
                if (hasNotification && !isSelected)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF06e0e0) : Colors.grey[400],
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
