import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../providers/aqi_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/flood_provider.dart';
import '../providers/location_provider.dart';
import '../providers/weather_provider.dart';
import '../services/daily_brief_service.dart';

class DailyEnvironmentScreen extends StatefulWidget {
  const DailyEnvironmentScreen({super.key, this.initialBrief});
  final DailyBrief? initialBrief;

  @override
  State<DailyEnvironmentScreen> createState() => _DailyEnvironmentScreenState();
}

class _DailyEnvironmentScreenState extends State<DailyEnvironmentScreen> {
  DailyBrief? _brief;
  bool   _loadingBrief = false;
  String? _briefError;
  int    _briefRetries = 0;
  static const _maxRetries = 3;

  final List<ChatMessage> _history  = [];
  final List<_Bubble>     _bubbles  = [];
  bool   _sending = false;
  final _msgCtrl  = TextEditingController();
  final _scroll   = ScrollController();

  @override
  void initState() {
    super.initState();
    _brief = widget.initialBrief;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_brief == null && mounted) _fetchBrief();
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<String> _healthConditions(BuildContext ctx) =>
      ctx.read<AuthProvider>().currentUser?.healthConditions ?? [];

  Map<String, dynamic> _envData(BuildContext ctx) {
    final aqi   = ctx.read<AqiProvider>();
    final flood = ctx.read<FloodProvider>();
    final loc   = ctx.read<LocationProvider>();
    final wx    = ctx.read<WeatherProvider>();
    return {
      'city':             loc.currentCity.isNotEmpty ? loc.currentCity : 'Lahore',
      'aqi':              aqi.current?.aqi,
      'aqiCategory':      aqi.current?.categoryLabel,
      'floodRisk':        flood.risk?.levelLabel,
      'floodProbability': flood.risk != null ? flood.risk!.riskScore / 100.0 : null,
      'temperature':      wx.current?.temperature,
      'humidity':         wx.current?.humidity.toDouble(),
      'weatherDesc':      wx.current?.description,
    };
  }

  Future<void> _fetchBrief({bool isRetry = false}) async {
    if (!isRetry) _briefRetries = 0;
    setState(() { _loadingBrief = true; _briefError = null; });
    try {
      final d = _envData(context);
      final brief = await DailyBriefService.instance.fetchSummary(
        city:             d['city'] as String,
        aqi:              d['aqi'] as int?,
        aqiCategory:      d['aqiCategory'] as String?,
        floodRisk:        d['floodRisk'] as String?,
        floodProbability: d['floodProbability'] as double?,
        temperature:      d['temperature'] as double?,
        humidity:         d['humidity'] as double?,
        weatherDesc:      d['weatherDesc'] as String?,
        healthConditions: _healthConditions(context),
      );
      if (mounted) setState(() { _brief = brief; _loadingBrief = false; _briefRetries = 0; });
    } catch (e) {
      if (!mounted) return;
      if (_briefRetries < _maxRetries) {
        _briefRetries++;
        // Railway free-tier cold start can take 20-30s — wait then retry silently
        await Future.delayed(Duration(seconds: 12 * _briefRetries));
        if (mounted) _fetchBrief(isRetry: true);
      } else {
        setState(() { _briefError = e.toString(); _loadingBrief = false; });
      }
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    _msgCtrl.clear();
    setState(() {
      _bubbles.add(_Bubble(text: text, isUser: true));
      _history.add(ChatMessage(role: 'user', content: text));
      _sending = true;
    });
    _scrollDown();

    try {
      final d = _envData(context);
      final reply = await DailyBriefService.instance.sendMessage(
        message:          text,
        city:             d['city'] as String,
        history:          List.from(_history)..removeLast(),
        aqi:              d['aqi'] as int?,
        aqiCategory:      d['aqiCategory'] as String?,
        floodRisk:        d['floodRisk'] as String?,
        temperature:      d['temperature'] as double?,
        weatherDesc:      d['weatherDesc'] as String?,
        healthConditions: _healthConditions(context),
      );
      if (!mounted) return;
      setState(() {
        _bubbles.add(_Bubble(text: reply, isUser: false));
        _history.add(ChatMessage(role: 'assistant', content: reply));
        _sending = false;
      });
      _scrollDown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bubbles.add(_Bubble(text: 'Could not connect. Try again.', isUser: false, isError: true));
        _history.removeLast();
        _sending = false;
      });
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                children: [
                  // Live data — shown immediately from providers
                  _buildLiveDataRow(),
                  const SizedBox(height: 14),
                  // Health advisory based on AQI
                  _buildHealthAdvisory(),
                  const SizedBox(height: 14),
                  // Pollutants breakdown
                  _buildPollutantsSection(),
                  const SizedBox(height: 14),
                  // Weather details
                  _buildWeatherDetails(),
                  const SizedBox(height: 14),
                  // Rainfall & cloudburst
                  _buildRainfallSection(),
                  const SizedBox(height: 16),
                  // Hourly AQI chart
                  _buildAqiChart(),
                  const SizedBox(height: 20),
                  // AI brief section
                  _buildBriefSection(),
                  if (_brief != null) ...[
                    const SizedBox(height: 20),
                    _buildGuideSection(_brief!),
                    const SizedBox(height: 20),
                    _buildSafetyTip(_brief!.safetyTip),
                  ],
                  const SizedBox(height: 24),
                  _buildChatDivider(),
                  const SizedBox(height: 12),
                  ..._bubbles.map(_buildBubble),
                  if (_sending) _buildTypingIndicator(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily Environmental Brief', style: AppTextStyles.headlinePrimary),
              Consumer<LocationProvider>(
                builder: (_, loc, __) => Text(
                  loc.currentCity.isNotEmpty ? loc.currentCity : 'Your Location',
                  style: AppTextStyles.bodySmallSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (!_loadingBrief)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
              onPressed: _fetchBrief,
              tooltip: 'Refresh brief',
            ),
        ],
      ),
    );
  }

  // ── Live data tiles ────────────────────────────────────────────────────────

  Widget _buildLiveDataRow() {
    return Row(
      children: [
        Expanded(child: _buildAqiTile()),
        const SizedBox(width: 10),
        Expanded(child: _buildWeatherTile()),
        const SizedBox(width: 10),
        Expanded(child: _buildFloodTile()),
      ],
    );
  }

  Widget _buildAqiTile() {
    return Consumer<AqiProvider>(
      builder: (_, aqi, __) {
        final reading = aqi.current;
        final color = reading?.color ?? AppColors.textSecondary;
        return _dataTile(
          icon: Icons.air_rounded,
          iconColor: color,
          label: 'AQI',
          value: reading != null ? '${reading.aqi}' : '--',
          sub: reading?.categoryLabel ?? (aqi.isLoading ? 'Loading…' : 'No data'),
          valueColor: color,
        );
      },
    );
  }

  Widget _buildWeatherTile() {
    return Consumer<WeatherProvider>(
      builder: (_, wx, __) {
        final w = wx.current;
        return _dataTile(
          icon: Icons.thermostat_rounded,
          iconColor: const Color(0xFF42A5F5),
          label: 'Weather',
          value: w != null ? '${w.temperature.round()}°C' : '--',
          sub: w?.description ?? (wx.isLoading ? 'Loading…' : 'No data'),
          valueColor: AppColors.textPrimary,
        );
      },
    );
  }

  Widget _buildFloodTile() {
    return Consumer<FloodProvider>(
      builder: (_, flood, __) {
        final risk = flood.risk;
        Color riskColor;
        if (risk == null) {
          riskColor = AppColors.textSecondary;
        } else {
          switch (risk.level.name) {
            case 'critical': riskColor = AppColors.danger; break;
            case 'high':     riskColor = AppColors.warning; break;
            case 'moderate': riskColor = const Color(0xFFFFB300); break;
            default:         riskColor = AppColors.success;
          }
        }
        return _dataTile(
          icon: Icons.water_drop_rounded,
          iconColor: riskColor,
          label: 'Flood',
          value: risk?.levelLabel ?? '--',
          sub: risk != null ? '${risk.riskScore}% risk' : (flood.isLoading ? 'Loading…' : 'No data'),
          valueColor: riskColor,
        );
      },
    );
  }

  Widget _dataTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String sub,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 13),
              const SizedBox(width: 4),
              Text(label, style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.titleMed.copyWith(color: valueColor, fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(sub,
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ── Health advisory ───────────────────────────────────────────────────────

  Widget _buildHealthAdvisory() {
    return Consumer2<AqiProvider, AuthProvider>(
      builder: (_, aqi, auth, __) {
        final reading = aqi.current;
        if (reading == null) return const SizedBox.shrink();
        final color = reading.color;
        final conditions = auth.currentUser?.healthConditions ?? [];
        final advice = conditions.isNotEmpty
            ? _personalizedAdvice(reading.aqi, conditions)
            : reading.healthAdvice;
        final label = conditions.isNotEmpty
            ? 'Personalised Advisory'
            : 'Health Advisory';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.health_and_safety_outlined, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(label,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: color, fontWeight: FontWeight.w600, fontSize: 11)),
                      if (conditions.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('for you', style: AppTextStyles.bodySmall.copyWith(
                              color: color, fontSize: 9)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    Text(advice,
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary, height: 1.5)),
                    if (conditions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: conditions.map((c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color.withOpacity(0.25)),
                          ),
                          child: Text(c, style: AppTextStyles.bodySmall.copyWith(
                              color: color, fontSize: 10)),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _personalizedAdvice(int aqi, List<String> conditions) {
    final lc = conditions.map((c) => c.toLowerCase()).toList();
    final msgs = <String>[];

    final hasRespiratory = lc.any((c) => c.contains('asthma') || c.contains('copd'));
    final hasCardiac = lc.any((c) => c.contains('heart') || c.contains('hypertension'));
    final hasChildren = lc.any((c) => c.contains('child'));
    final hasElderly = lc.any((c) => c.contains('elderly'));
    final hasDiabetes = lc.any((c) => c.contains('diabetes'));
    final hasAllergies = lc.any((c) => c.contains('allerg'));

    if (hasRespiratory) {
      if (aqi > 50) {
        msgs.add('AQI $aqi is above your safe threshold — keep your inhaler ready and limit outdoor time.');
      } else {
        msgs.add('Air quality is within safe range for your respiratory condition today.');
      }
    }
    if (hasCardiac) {
      if (aqi > 100) {
        msgs.add('High AQI with your heart condition: avoid exertion outdoors and stay cool.');
      } else {
        msgs.add('Air quality poses low cardiac risk today. Stay hydrated.');
      }
    }
    if (hasChildren) {
      if (aqi > 100) {
        msgs.add('Keep children indoors — AQI $aqi is unsafe for young lungs.');
      } else {
        msgs.add('Air quality is acceptable for children. Limit outdoor play if AQI rises.');
      }
    }
    if (hasElderly) {
      if (aqi > 100) {
        msgs.add('Elderly household members should remain indoors with windows closed.');
      } else {
        msgs.add('Conditions are manageable for elderly members. Avoid peak-heat hours.');
      }
    }
    if (hasDiabetes) {
      msgs.add('Stay hydrated and avoid heat exposure — dehydration risk is elevated today.');
    }
    if (hasAllergies && aqi > 100) {
      msgs.add('High smog may trigger allergy symptoms. Consider antihistamines before going out.');
    }

    if (msgs.isEmpty) return conditions.map((c) => '$c: monitor conditions and take usual precautions.').join(' ');
    return msgs.join(' ');
  }

  // ── Pollutants breakdown ───────────────────────────────────────────────────

  Widget _buildPollutantsSection() {
    return Consumer<AqiProvider>(
      builder: (_, aqi, __) {
        final r = aqi.current;
        if (r == null) return const SizedBox.shrink();
        final pollutants = [
          ('PM2.5', r.pm25, 'μg/m³'),
          ('PM10',  r.pm10, 'μg/m³'),
          ('O₃',    r.o3,   'μg/m³'),
          ('NO₂',   r.no2,  'μg/m³'),
          ('SO₂',   r.so2,  'μg/m³'),
          ('CO',    r.co,   'mg/m³'),
        ];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.science_outlined, color: AppColors.textSecondary, size: 15),
                const SizedBox(width: 6),
                Text('Pollutants', style: AppTextStyles.titleMed.copyWith(
                    color: AppColors.textPrimary, fontSize: 13)),
                const Spacer(),
                Text('Dominant: ${r.dominantPollutantLabel}',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary, fontSize: 10)),
              ]),
              const SizedBox(height: 12),
              // Two rows of 3, each row shares equal width — no GridView overflow
              for (final indices in [ [0,1,2], [3,4,5] ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: indices.map((i) {
                      final p     = pollutants[i];
                      final label = p.$1;
                      final value = p.$2;
                      final unit  = p.$3;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(left: i % 3 == 0 ? 0 : 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.bgPrimary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label, style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary, fontSize: 9)),
                              const SizedBox(height: 3),
                              Text(value > 0 ? value.toStringAsFixed(1) : '--',
                                  style: AppTextStyles.titleMed.copyWith(
                                      color: AppColors.textPrimary, fontSize: 14)),
                              Text(unit, style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary, fontSize: 8)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Weather details ────────────────────────────────────────────────────────

  Widget _buildWeatherDetails() {
    return Consumer<WeatherProvider>(
      builder: (_, wx, __) {
        final w = wx.current;
        if (w == null) return const SizedBox.shrink();
        final details = [
          (Icons.thermostat_outlined,    'Feels Like',  '${w.feelsLike.round()}°C'),
          (Icons.water_drop_outlined,    'Humidity',    '${w.humidity}%'),
          (Icons.air_outlined,           'Wind',        '${w.windSpeed.round()} km/h ${w.windDirectionLabel}'),
          (Icons.compress_rounded,       'Pressure',    '${w.pressure.round()} hPa'),
          if (w.tempMin != null && w.tempMax != null)
            (Icons.keyboard_arrow_down_rounded, 'Low / High',
                '${w.tempMin!.round()}° / ${w.tempMax!.round()}°'),
          if (w.visibility > 0)
            (Icons.visibility_outlined,  'Visibility',  '${w.visibility.round()} km'),
        ];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.wb_cloudy_outlined,
                    color: Color(0xFF42A5F5), size: 15),
                const SizedBox(width: 6),
                Text('Weather Details', style: AppTextStyles.titleMed.copyWith(
                    color: AppColors.textPrimary, fontSize: 13)),
              ]),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: details.map((d) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(d.$1, color: const Color(0xFF42A5F5), size: 13),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.$2, style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary, fontSize: 9)),
                          Text(d.$3, style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Rainfall & cloudburst ─────────────────────────────────────────────────

  Widget _buildRainfallSection() {
    return Consumer<FloodProvider>(
      builder: (_, flood, __) {
        final risk = flood.risk;
        if (risk == null) return const SizedBox.shrink();
        final r = risk.rainfall;
        final cbProb = risk.cloudburstProbability;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.water_rounded, color: risk.color, size: 15),
                const SizedBox(width: 6),
                Text('Flood & Rainfall', style: AppTextStyles.titleMed.copyWith(
                    color: AppColors.textPrimary, fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: risk.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: risk.color.withOpacity(0.3)),
                  ),
                  child: Text(risk.levelLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: risk.color, fontWeight: FontWeight.w600, fontSize: 10)),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _rainStat('24h Rainfall', '${r.mm24h.toStringAsFixed(1)} mm')),
                const SizedBox(width: 8),
                Expanded(child: _rainStat('48h Rainfall', '${r.mm48h.toStringAsFixed(1)} mm')),
                const SizedBox(width: 8),
                Expanded(child: _rainStat('Intensity', '${r.mmPerHour.toStringAsFixed(1)} mm/h')),
              ]),
              if (cbProb != null) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.storm_rounded,
                      color: cbProb > 0.6 ? AppColors.danger : AppColors.warning,
                      size: 13),
                  const SizedBox(width: 6),
                  Text('Cloudburst probability: ',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary, fontSize: 11)),
                  Text('${(cbProb * 100).round()}%',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: cbProb > 0.6 ? AppColors.danger : AppColors.warning,
                          fontWeight: FontWeight.w700, fontSize: 11)),
                  if (risk.cloudburstUsingModel) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('ML', style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary, fontSize: 8,
                          fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
              ],
              if (risk.explanation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(risk.explanation,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary, height: 1.4, fontSize: 11)),
              ],
              if (risk.affectedAreas.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: risk.affectedAreas.map((area) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: risk.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: risk.color.withOpacity(0.2)),
                    ),
                    child: Text(area, style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary, fontSize: 10)),
                  )).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _rainStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.titleMed.copyWith(
              color: AppColors.textPrimary, fontSize: 13)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary, fontSize: 9),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Hourly AQI chart ───────────────────────────────────────────────────────

  Widget _buildAqiChart() {
    return Consumer<AqiProvider>(
      builder: (_, aqi, __) {
        final hourly = aqi.hourly;
        if (hourly.isEmpty) return const SizedBox.shrink();

        // Show next 24 hours from now
        final now = DateTime.now();
        final points = hourly
            .where((p) => p.hour.isAfter(now.subtract(const Duration(hours: 1))))
            .take(24)
            .toList();
        if (points.length < 2) return const SizedBox.shrink();

        final spots = points.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.aqi.toDouble()))
            .toList();

        final maxAqi = points.map((p) => p.aqi).reduce((a, b) => a > b ? a : b);
        final minAqi = points.map((p) => p.aqi).reduce((a, b) => a < b ? a : b);
        final yMax = (maxAqi + 30).toDouble();
        final yMin = ((minAqi - 20).clamp(0, double.infinity)).toDouble();

        // Colour the line based on current AQI
        final lineColor = aqi.current?.color ?? AppColors.primary;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart_rounded, color: lineColor, size: 16),
                  const SizedBox(width: 8),
                  Text('24-Hour AQI Forecast',
                      style: AppTextStyles.titleMed.copyWith(color: AppColors.textPrimary)),
                  const Spacer(),
                  Text('Now → ${DateFormat('ha').format(points.last.hour)}',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: LineChart(
                  LineChartData(
                    minY: yMin,
                    maxY: yMax,
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 50,
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 50,
                          getTitlesWidget: (v, _) => Text(
                            v.toInt().toString(),
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary, fontSize: 9),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 18,
                          interval: (points.length / 4).ceilToDouble(),
                          getTitlesWidget: (v, _) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                            return Text(
                              DateFormat('ha').format(points[idx].hour),
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary, fontSize: 9),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: lineColor,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: lineColor.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── AI Brief section ───────────────────────────────────────────────────────

  Widget _buildBriefSection() {
    if (_loadingBrief) {
      return _shimmerCard(
        height: 80,
        label: _briefRetries > 0
            ? 'Connecting to AI… (attempt ${_briefRetries + 1}/${ _maxRetries + 1})'
            : 'Loading AI brief…',
      );
    }
    if (_briefError != null) {
      return _errorCard(_briefError!, _fetchBrief);
    }
    if (_brief == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text("AI Overview", style: AppTextStyles.titleMed.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(_brief!.summary,
              style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary, height: 1.55)),
        ],
      ),
    );
  }

  Widget _buildGuideSection(DailyBrief brief) {
    if (brief.guideSteps.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(brief.guideTitle,
                    style: AppTextStyles.titleMed.copyWith(color: AppColors.success)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...brief.guideSteps.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${e.key + 1}',
                        style: TextStyle(
                            color: AppColors.success, fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(e.value,
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary, height: 1.4)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String tip) {
    if (tip.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_outlined,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(tip,
                style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary, height: 1.5)),
          ),
        ],
      ),
    );
  }

  // ── Chat ───────────────────────────────────────────────────────────────────

  Widget _buildChatDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderSubtle)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.textSecondary, size: 14),
              const SizedBox(width: 6),
              Text('Ask EcoAlert AI', style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderSubtle)),
      ],
    );
  }

  Widget _buildBubble(_Bubble b) {
    return Align(
      alignment: b.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: b.isUser
              ? AppColors.primary
              : b.isError
                  ? AppColors.danger.withOpacity(0.15)
                  : AppColors.bgCard,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: b.isUser ? const Radius.circular(4) : null,
            bottomLeft:  b.isUser ? null : const Radius.circular(4),
          ),
          border: b.isUser ? null
              : Border.all(color: b.isError
                  ? AppColors.danger.withOpacity(0.3)
                  : AppColors.borderSubtle),
        ),
        child: Text(b.text,
            style: AppTextStyles.body.copyWith(
                color: b.isUser ? Colors.white : AppColors.textPrimary,
                height: 1.45)),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16).copyWith(
              bottomLeft: const Radius.circular(4)),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0), const SizedBox(width: 4),
            _dot(1), const SizedBox(width: 4),
            _dot(2),
          ],
        ),
      ),
    );
  }

  Widget _dot(int i) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.4, end: 1.0),
    duration: Duration(milliseconds: 600 + i * 150),
    builder: (_, v, __) => Opacity(
      opacity: v,
      child: Container(
        width: 6, height: 6,
        decoration: BoxDecoration(
          color: AppColors.textSecondary,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12,
          MediaQuery.of(context).viewInsets.bottom +
          MediaQuery.of(context).padding.bottom + 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 0.5)),
        color: AppColors.bgPrimary,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Ask about air quality, floods, safety…',
                hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.bgCard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _sending ? AppColors.textSecondary : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerCard({double height = 100, String? label}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            if (label != null) ...[
              const SizedBox(height: 10),
              Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _errorCard(String msg, VoidCallback retry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text('Could not load AI brief', style: AppTextStyles.body
              .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: retry,
            child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _Bubble {
  const _Bubble({required this.text, required this.isUser, this.isError = false});
  final String text;
  final bool isUser;
  final bool isError;
}
