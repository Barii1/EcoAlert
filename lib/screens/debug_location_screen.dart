import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../providers/aqi_provider.dart';
import '../providers/flood_provider.dart';
import '../providers/location_provider.dart';
import '../providers/weather_provider.dart';

// All 10 supported Pakistan cities with coordinates
const _kCities = [
  _City('Lahore',      31.5497, 74.3436),
  _City('Karachi',     24.8607, 67.0011),
  _City('Islamabad',   33.7294, 73.0931),
  _City('Rawalpindi',  33.6007, 73.0679),
  _City('Peshawar',    34.0151, 71.5249),
  _City('Multan',      30.1978, 71.4711),
  _City('Faisalabad',  31.4504, 73.1350),
  _City('Quetta',      30.1798, 66.9750),
  _City('Hyderabad',   25.3960, 68.3578),
  _City('Sukkur',      27.7052, 68.8574),
];

class _City {
  const _City(this.name, this.lat, this.lon);
  final String name;
  final double lat, lon;
}

class DebugLocationSheet extends StatefulWidget {
  const DebugLocationSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const DebugLocationSheet(),
      );

  @override
  State<DebugLocationSheet> createState() => _DebugLocationSheetState();
}

class _DebugLocationSheetState extends State<DebugLocationSheet> {
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();
  bool _customExpanded = false;

  @override
  void dispose() {
    _latCtrl.dispose();
    _lonCtrl.dispose();
    super.dispose();
  }

  void _applyCity(_City city) {
    _setLocation(city.lat, city.lon, city.name);
    Navigator.pop(context);
  }

  void _applyCustom() {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lon = double.tryParse(_lonCtrl.text.trim());
    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid lat/lon numbers')),
      );
      return;
    }
    if (lat < 20 || lat > 40 || lon < 60 || lon > 80) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordinates outside Pakistan bounds')),
      );
      return;
    }
    _setLocation(lat, lon, 'Custom (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})');
    Navigator.pop(context);
  }

  void _setLocation(double lat, double lon, String cityName) {
    final loc   = context.read<LocationProvider>();
    final flood = context.read<FloodProvider>();
    final aqi   = context.read<AqiProvider>();
    final wx    = context.read<WeatherProvider>();

    loc.setDebugLocation(lat, lon, cityName);
    final pos = loc.currentPosition!;

    flood.loadForLocation(latitude: lat, longitude: lon, city: cityName);
    aqi.loadForLocation(pos, cityLabel: cityName);
    wx.loadForLocation(pos, cityLabel: cityName);
  }

  void _clearLocation() {
    final loc = context.read<LocationProvider>();
    final auth = loc.currentCity; // save for reload
    loc.clearDebugLocation();

    // Reload with GPS position if available, else Lahore
    final pos = loc.currentPosition;
    final flood = context.read<FloodProvider>();
    final aqi   = context.read<AqiProvider>();
    final wx    = context.read<WeatherProvider>();

    if (pos != null) {
      flood.loadForLocation(latitude: pos.latitude, longitude: pos.longitude, city: auth);
      aqi.loadForLocation(pos, cityLabel: auth);
      wx.loadForLocation(pos, cityLabel: auth);
    } else {
      flood.loadForCity('Lahore');
      aqi.loadForCity('Lahore');
      wx.loadForCity('Lahore');
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc   = context.watch<LocationProvider>();
    final flood = context.watch<FloodProvider>();
    final isDebug = loc.isDebugMode;
    final activeCity = loc.currentCity;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D0D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 10),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.bug_report_rounded,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  const Text('Location Debug',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (isDebug)
                    GestureDetector(
                      onTap: _clearLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.danger.withOpacity(0.4)),
                        ),
                        child: const Text('Clear GPS',
                            style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Active location pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: isDebug ? AppColors.warning : AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isDebug
                          ? 'Override active: $activeCity'
                          : 'Using real GPS: $activeCity',
                      style: TextStyle(
                        color: isDebug
                            ? AppColors.warning
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFF1F1F1F)),

            // Force cloudburst toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.thunderstorm_rounded,
                      color: AppColors.danger, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Force Cloudburst Critical',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Text('Overrides model — fires local notification',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  Switch(
                    value: flood.debugForceHigh,
                    activeColor: AppColors.danger,
                    onChanged: (v) => flood.setDebugForceHigh(v),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFF1F1F1F)),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('PAKISTAN CITIES',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),

            // City grid
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.8,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _kCities.map((c) {
                      final isActive =
                          isDebug && activeCity == c.name;
                      return GestureDetector(
                        onTap: () => _applyCity(c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.warning.withOpacity(0.12)
                                : const Color(0xFF161616),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.warning.withOpacity(0.5)
                                  : const Color(0xFF1F1F1F),
                              width: isActive ? 1.5 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                isActive
                                    ? Icons.location_on
                                    : Icons.location_city_rounded,
                                color: isActive
                                    ? AppColors.warning
                                    : Colors.white38,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  c.name,
                                  style: TextStyle(
                                    color: isActive
                                        ? AppColors.warning
                                        : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Custom lat/lon expander
                  GestureDetector(
                    onTap: () =>
                        setState(() => _customExpanded = !_customExpanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: const Color(0xFF1F1F1F)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_location_alt_rounded,
                              color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          const Text('Custom coordinates',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const Spacer(),
                          Icon(
                            _customExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: Colors.white38,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_customExpanded) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _CoordField(
                              controller: _latCtrl,
                              label: 'Latitude',
                              hint: '31.5497'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CoordField(
                              controller: _lonCtrl,
                              label: 'Longitude',
                              hint: '74.3436'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                        ),
                        onPressed: _applyCustom,
                        child: const Text('Apply Custom Location',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordField extends StatelessWidget {
  const _CoordField(
      {required this.controller,
      required this.label,
      required this.hint});
  final TextEditingController controller;
  final String label, hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: true),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF161616),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1F1F1F)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1F1F1F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.6)),
        ),
      ),
    );
  }
}
