import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../providers/aqi_provider.dart';
import '../providers/flood_provider.dart';
import '../providers/location_provider.dart';
import '../providers/weather_provider.dart';
import '../services/daily_brief_service.dart';
import '../config/app_colors.dart' show AppColors;

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

  final List<ChatMessage> _history  = [];
  final List<_Bubble>     _bubbles  = [];
  bool   _sending = false;
  final _msgCtrl  = TextEditingController();
  final _scroll   = ScrollController();

  @override
  void initState() {
    super.initState();
    _brief = widget.initialBrief;
    // Use addPostFrameCallback so context.read<>() is safe
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

  // ── Helpers ────────────────────────────────────────────────────────────────
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

  Future<void> _fetchBrief() async {
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
      );
      if (mounted) setState(() { _brief = brief; _loadingBrief = false; });
    } catch (e) {
      if (mounted) setState(() { _briefError = e.toString(); _loadingBrief = false; });
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
        message:        text,
        city:           d['city'] as String,
        history:        List.from(_history)..removeLast(),
        aqi:            d['aqi'] as int?,
        aqiCategory:    d['aqiCategory'] as String?,
        floodRisk:      d['floodRisk'] as String?,
        temperature:    d['temperature'] as double?,
        weatherDesc:    d['weatherDesc'] as String?,
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
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  children: [
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

  Widget _buildBriefSection() {
    if (_loadingBrief) {
      return _shimmerCard(height: 120);
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
              const Icon(Icons.wb_sunny_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text("Today's Overview", style: AppTextStyles.titleMed.copyWith(color: AppColors.primary)),
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
          MediaQuery.of(context).viewInsets.bottom + 10),
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

  Widget _shimmerCard({double height = 100}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
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
          Text('Could not load brief', style: AppTextStyles.body
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
