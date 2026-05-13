import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../config/app_config.dart';
import '../config/app_text_styles.dart';
import '../providers/aqi_provider.dart';
import '../providers/flood_provider.dart';
import '../services/remote_predict_service.dart';
import '../models/flood_model.dart';
import '../widgets/app_background.dart';
import '../widgets/surface_card.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Model Status Screen
/// Shows live backend health, cloudburst ML model output, and AQI sensor data.
/// Accessible from Admin Dashboard → "Model Status" tile.
/// ─────────────────────────────────────────────────────────────────────────────
class ModelStatusScreen extends StatefulWidget {
  const ModelStatusScreen({super.key});

  @override
  State<ModelStatusScreen> createState() => _ModelStatusScreenState();
}

class _ModelStatusScreenState extends State<ModelStatusScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _loadingStatus = true;
  bool _loadingPrediction = false;

  Map<String, dynamic>? _statusData;   // /api/predict/status
  Map<String, dynamic>? _rawResponse;  // raw cloudburst prediction response
  FloodRisk? _prediction;
  String? _statusError;
  String? _predictionError;

  // Test city
  String _selectedCity = 'Lahore';
  static const Map<String, (double, double)> _cities = {
    'Lahore':     (31.5497, 74.3436),
    'Karachi':    (24.8607, 67.0011),
    'Islamabad':  (33.7294, 73.0931),
    'Peshawar':   (34.0151, 71.5249),
    'Multan':     (30.1978, 71.4711),
    'Faisalabad': (31.4504, 73.1350),
    'Quetta':     (30.1798, 66.9750),
  };

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  // ── API calls ──────────────────────────────────────────────────────────────

  Future<void> _fetchStatus() async {
    setState(() {
      _loadingStatus = true;
      _statusError = null;
    });
    try {
      final data = await RemotePredictService.instance.getModelStatus();
      setState(() => _statusData = data);
    } catch (e) {
      setState(() => _statusError = e.toString());
    } finally {
      setState(() => _loadingStatus = false);
    }
  }

  Future<void> _runPrediction() async {
    setState(() {
      _loadingPrediction = true;
      _predictionError = null;
      _rawResponse = null;
      _prediction = null;
    });

    final coords = _cities[_selectedCity] ?? (31.5497, 74.3436);

    try {
      // ── Direct HTTP call to Flask so we capture the full raw JSON ─────────
      // This bypasses RemotePredictService wrapper so we see every field
      // the model returns including features_used, using_model, probability.
      final uri = Uri.parse(
        '${AppConfig.uploadApiBaseUrl}/api/predict/cloudburst',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude':  coords.$1,
          'longitude': coords.$2,
          'city':      _selectedCity,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Flask returned ${response.statusCode}: ${response.body}');
      }

      final raw = jsonDecode(response.body) as Map<String, dynamic>;

      // Build a FloodRisk from the raw response for the summary card
      final dummyRainfall = RainfallData(
        mm24h: 0, mm48h: 0, mmPerHour: 0,
        temperature: (raw['features_used']?['temperature'] as num?)?.toDouble() ?? 0,
        humidity: (raw['features_used']?['humidity'] as num?)?.toDouble() ?? 0,
        timestamp: DateTime.now(),
      );
      final result = await RemotePredictService.instance.predictCloudburst(
        latitude: coords.$1,
        longitude: coords.$2,
        city: _selectedCity,
        rainfall: dummyRainfall,
      );

      setState(() {
        _rawResponse = raw;
        _prediction = result;
      });
    } catch (e) {
      setState(() => _predictionError = e.toString());
    } finally {
      setState(() => _loadingPrediction = false);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: () async {
                    await _fetchStatus();
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    children: [
                      _buildSectionLabel('BACKEND HEALTH'),
                      const SizedBox(height: 8),
                      _buildStatusCard(),
                      const SizedBox(height: 24),

                      _buildSectionLabel('CLOUDBURST MODEL — LIVE TEST'),
                      const SizedBox(height: 8),
                      _buildPredictionCard(),
                      const SizedBox(height: 24),

                      _buildSectionLabel('AQI SENSOR DATA'),
                      const SizedBox(height: 8),
                      _buildAqiCard(),
                      const SizedBox(height: 24),

                      _buildSectionLabel('FLOOD RISK SUMMARY'),
                      const SizedBox(height: 8),
                      _buildFloodSummaryCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Model Status', style: AppTextStyles.headline.copyWith(color: AppColors.textPrimary)),
                Text('Live backend & ML diagnostics',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: _fetchStatus,
            tooltip: 'Refresh status',
          ),
        ],
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(
          color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text, style: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary, letterSpacing: 1.2)),
      ],
    );
  }

  // ── Backend status card ────────────────────────────────────────────────────

  Widget _buildStatusCard() {
    if (_loadingStatus) {
      return _loadingCard();
    }

    if (_statusError != null) {
      return _errorCard(
        icon: Icons.wifi_off_rounded,
        title: 'Flask server unreachable',
        subtitle: 'Make sure you ran: python app.py in backend/ecoalert-backend',
        detail: _statusError!,
        color: AppColors.danger,
      );
    }

    final modelLoaded = _statusData?['cloudburst_model_loaded'] as bool? ?? false;
    final modelPath   = _statusData?['model_path'] as String? ?? 'unknown';
    final features    = (_statusData?['feature_cols'] as List?)?.cast<String>() ?? [];
    final thresholds  = _statusData?['thresholds'] as Map<String, dynamic>? ?? {};

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Server online row
          _statusRow(
            icon: Icons.dns_rounded,
            label: 'Flask Server',
            value: 'Online',
            valueColor: AppColors.success,
          ),
          _divider(),

          // Model loaded
          _statusRow(
            icon: Icons.psychology_rounded,
            label: 'Cloudburst Model',
            value: modelLoaded ? 'Loaded ✓' : 'NOT LOADED ✗',
            valueColor: modelLoaded ? AppColors.success : AppColors.danger,
          ),

          if (!modelLoaded) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger.withOpacity(0.2)),
              ),
              child: Text(
                'Run this in your venv:\npip install scikit-learn==1.8.0 joblib==1.4.2 numpy==1.26.4 pandas==2.2.2',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.danger, fontFamily: 'monospace'),
              ),
            ),
          ],

          if (modelLoaded) ...[
            _divider(),
            // Model path (shortened)
            _infoRow('Model file', modelPath.split(r'\').last.split('/').last),
            _divider(),

            // Features
            _infoRow('Features', features.join(', ')),
            _divider(),

            // Thresholds
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thresholds',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: thresholds.entries.map((e) => Text(
                    '${e.key}: ${e.value}',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: _thresholdColor(e.key), fontWeight: FontWeight.w600),
                  )).toList(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Prediction card ────────────────────────────────────────────────────────

  Widget _buildPredictionCard() {
    return Column(
      children: [
        // City picker + run button
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Test City', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedCity,
                        isExpanded: true,
                        dropdownColor: AppColors.bgCard,
                        underline: const SizedBox.shrink(),
                        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                        items: _cities.keys.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedCity = v!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _loadingPrediction ? null : _runPrediction,
                    icon: _loadingPrediction
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textInverse))
                        : const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(_loadingPrediction ? 'Running...' : 'Run'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textInverse,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Sends lat/lon to Flask → Open-Meteo weather fetch → LogisticRegression model → returns risk',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled, height: 1.4),
              ),
            ],
          ),
        ),

        if (_predictionError != null) ...[
          const SizedBox(height: 12),
          _errorCard(
            icon: Icons.model_training,
            title: 'Prediction failed',
            subtitle: 'Check Flask terminal for traceback',
            detail: _predictionError!,
            color: AppColors.warning,
          ),
        ],

        if (_prediction != null && _rawResponse != null) ...[
          const SizedBox(height: 12),
          _buildPredictionResult(),
        ],
      ],
    );
  }

  Widget _buildPredictionResult() {
    final p = _prediction!;
    final raw = _rawResponse!;

    final prob    = (raw['cloudburst_probability'] as num?)?.toDouble() ?? 0.0;
    final probPct = '${(prob * 100).toStringAsFixed(1)}%';
    final usingModel = raw['using_model'] as bool? ?? false;
    final features = raw['features_used'] as Map<String, dynamic>? ?? {};

    final riskColor = p.level == FloodRiskLevel.critical ? AppColors.danger
        : p.level == FloodRiskLevel.high ? AppColors.warning
        : AppColors.success;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: riskColor.withOpacity(0.3)),
                ),
                child: Text(
                  p.level.name.toUpperCase(),
                  style: AppTextStyles.label.copyWith(color: riskColor, letterSpacing: 1.2),
                ),
              ),
              const SizedBox(width: 12),
              Text('Probability: $probPct',
                  style: AppTextStyles.titleMed.copyWith(color: AppColors.textPrimary)),
              const Spacer(),
              // Model vs rule-based badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: usingModel
                      ? AppColors.info.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: usingModel
                      ? AppColors.info.withOpacity(0.3)
                      : AppColors.warning.withOpacity(0.3)),
                ),
                child: Text(
                  usingModel ? '🤖 ML Model' : '📐 Rule-based',
                  style: AppTextStyles.label.copyWith(
                    color: usingModel ? AppColors.info : AppColors.warning,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Probability bar
          Text('Probability', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prob,
              backgroundColor: AppColors.bgElevated,
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          _divider(),

          // Features used
          Text('Weather Features Used by Model',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          ...features.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(_featureLabel(e.key),
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                const Spacer(),
                Text(
                  _formatFeatureValue(e.key, e.value),
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )),

          _divider(),

          // Explanation from model
          Text(p.explanation,
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary, height: 1.5)),

          const SizedBox(height: 12),

          // Copy raw JSON button
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(
                text: const JsonEncoder.withIndent('  ').convert(raw),
              ));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Raw JSON copied to clipboard'),
                duration: Duration(seconds: 2),
              ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('Copy raw JSON response',
                      style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AQI card ───────────────────────────────────────────────────────────────

  Widget _buildAqiCard() {
    return Consumer<AqiProvider>(
      builder: (context, aqi, _) {
        if (aqi.isLoading && aqi.current == null) return _loadingCard(height: 120);
        if (aqi.hasError || aqi.current == null) {
          return _errorCard(
            icon: Icons.air,
            title: 'AQI data unavailable',
            subtitle: 'Check WAQI token in ApiKeys',
            detail: aqi.errorMessage ?? 'No data',
            color: AppColors.warning,
          );
        }
        final r = aqi.current!;
        final catColor = r.color;

        return SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _statusRow(
                    icon: Icons.sensors_rounded,
                    label: 'Data Source',
                    value: 'WAQI API (live sensor)',
                    valueColor: AppColors.success,
                    expand: false,
                  ),
                ],
              ),
              _divider(),
              Row(
                children: [
                  // Big AQI number
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r.aqi}', style: AppTextStyles.displayLarge.copyWith(color: catColor)),
                      Text(r.categoryLabel,
                          style: AppTextStyles.label.copyWith(color: catColor, letterSpacing: 0.8)),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        _pollutantRow('PM2.5', r.pm25, 'µg/m³'),
                        _pollutantRow('PM10',  r.pm10,  'µg/m³'),
                        _pollutantRow('O₃',    r.o3,    'ppb'),
                        _pollutantRow('NO₂',   r.no2,   'ppb'),
                        _pollutantRow('CO',    r.co,    'ppm'),
                      ],
                    ),
                  ),
                ],
              ),
              _divider(),
              Text(r.healthAdvice,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary, height: 1.4)),
              const SizedBox(height: 4),
              Text('City: ${r.city}  ·  Updated: ${_timeAgo(r.timestamp)}',
                  style: AppTextStyles.label.copyWith(color: AppColors.textDisabled)),
            ],
          ),
        );
      },
    );
  }

  // ── Flood / cloudburst summary ─────────────────────────────────────────────

  Widget _buildFloodSummaryCard() {
    return Consumer<FloodProvider>(
      builder: (context, flood, _) {
        if (flood.isLoading && flood.risk == null) return _loadingCard(height: 100);
        if (flood.hasError || flood.risk == null) {
          return _errorCard(
            icon: Icons.water_rounded,
            title: 'Cloudburst data unavailable',
            subtitle: flood.errorMessage ?? 'Flask may be unreachable',
            detail: 'FloodProvider falls back to local rule-based calculator when Flask is down.',
            color: AppColors.info,
          );
        }
        final r = flood.risk!;
        final isFromModel = !flood.isFromCache;
        final riskColor = r.level == FloodRiskLevel.critical ? AppColors.danger
            : r.level == FloodRiskLevel.high ? AppColors.warning
            : AppColors.success;

        return SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Cloudburst / Flood Risk',
                      style: AppTextStyles.titleMed.copyWith(color: AppColors.textPrimary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: riskColor.withOpacity(0.3)),
                    ),
                    child: Text(r.level.name.toUpperCase(),
                        style: AppTextStyles.label.copyWith(color: riskColor)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Score bar
              Row(
                children: [
                  Text('Risk Score',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  Text('${r.riskScore}/100',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: r.riskScore / 100,
                  backgroundColor: AppColors.bgElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              _divider(),
              _infoRow('City', r.city),
              _divider(),
              _infoRow('Source', isFromModel ? 'Flask ML + Open-Meteo' : 'Cached / rule-based'),
              _divider(),
              Text(r.explanation,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary, height: 1.5)),
              if (r.affectedAreas.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('At-risk areas: ${r.affectedAreas.join(', ')}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled)),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Reusable widgets ───────────────────────────────────────────────────────

  Widget _loadingCard({double height = 80}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  Widget _errorCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String detail,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMed.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(detail,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textDisabled, fontFamily: 'monospace'),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    bool expand = true,
  }) {
    final row = Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: valueColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(value,
            style: AppTextStyles.bodySmall.copyWith(
                color: valueColor, fontWeight: FontWeight.w600)),
      ],
    );
    return expand ? row : row;
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _pollutantRow(String name, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Text(name,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text('${value.toStringAsFixed(1)} $unit',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(color: AppColors.borderSubtle, height: 1),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _thresholdColor(String key) {
    switch (key) {
      case 'low':      return AppColors.success;
      case 'moderate': return AppColors.warning;
      case 'high':     return AppColors.danger;
      default:         return AppColors.textSecondary;
    }
  }

  String _featureLabel(String key) {
    const labels = {
      'temperature': 'Temperature',
      'humidity':    'Humidity',
      'pressure':    'Pressure',
      'cloud_cover': 'Cloud Cover (0–8)',
      'wind_speed':  'Wind Speed',
      'dew_point':   'Dew Point',
    };
    return labels[key] ?? key;
  }

  String _formatFeatureValue(String key, dynamic value) {
    if (value == null) return '--';
    final v = (value as num).toDouble();
    switch (key) {
      case 'temperature':
      case 'dew_point':  return '${v.toStringAsFixed(1)} °C';
      case 'humidity':   return '${v.toStringAsFixed(0)} %';
      case 'pressure':   return '${v.toStringAsFixed(0)} hPa';
      case 'wind_speed': return '${v.toStringAsFixed(1)} km/h';
      case 'cloud_cover':return '${v.toStringAsFixed(2)} / 8';
      default:           return v.toStringAsFixed(2);
    }
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
