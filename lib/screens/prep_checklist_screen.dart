import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrepChecklistScreen extends StatefulWidget {
  const PrepChecklistScreen({super.key});

  @override
  State<PrepChecklistScreen> createState() => _PrepChecklistScreenState();
}

class _PrepChecklistScreenState extends State<PrepChecklistScreen> {
  // ── Checklist data ────────────────────────────────────────────────────────

  static const _kItems = [
    'Emergency supply kit (water, food, first aid)',
    'Flashlight and extra batteries',
    'Battery-powered or hand-crank radio',
    'Important documents in waterproof container',
    'Cash and credit cards',
    'Prescription medications and glasses',
    'Phone charger and backup battery',
    'Local maps and evacuation routes',
  ];

  late List<bool> _checked;

  // ── Computed helpers ──────────────────────────────────────────────────────

  int get _completedCount => _checked.where((c) => c).length;
  int get _totalCount => _kItems.length;
  double get _progress =>
      _totalCount == 0 ? 0 : _completedCount / _totalCount;
  bool get _allDone => _completedCount == _totalCount;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _checked = List.filled(_kItems.length, false);
    _loadChecked();
  }

  Future<void> _loadChecked() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = List<bool>.generate(
      _kItems.length,
      (i) => prefs.getBool('checklist_item_$i') ?? false,
    );
    if (mounted) setState(() => _checked = loaded);
  }

  Future<void> _toggle(int index) async {
    final next = !_checked[index];
    setState(() => _checked[index] = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('checklist_item_$index', next);
  }

  Future<void> _resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (var i = 0; i < _kItems.length; i++) {
      await prefs.remove('checklist_item_$i');
    }
    if (mounted) setState(() => _checked = List.filled(_kItems.length, false));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0f2323),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // ── Drag handle ─────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 12),

          // ── Top progress bar ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_completedCount / $_totalCount items ready',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Color(0xFF0df2f2),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 5,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _allDone
                          ? const Color(0xFF0df2f2)
                          : const Color(0xFF0df2f2).withOpacity(0.75),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0df2f2).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.checklist_rtl,
                    color: Color(0xFF0df2f2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Preparedness',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Stay ready for any situation',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Reset All button (top-right action) ─────────────────
                IconButton(
                  onPressed: _resetAll,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: Colors.white.withOpacity(0.6),
                    size: 22,
                  ),
                  tooltip: 'Reset all',
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: Colors.white.withOpacity(0.6),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── AI tip ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Based on current weather, ensure you have adequate supplies',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Checklist ───────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (var i = 0; i < _kItems.length; i++)
                  _buildChecklistItem(i),
                // Congratulations card — shown at bottom when all done
                if (_allDone) _buildCongratsCard(),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Bottom actions ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF102222),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Share checklist — placeholder
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                          color: Colors.white.withOpacity(0.3)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _resetAll,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Checklist item ────────────────────────────────────────────────────────

  Widget _buildChecklistItem(int index) {
    final text = _kItems[index];
    final checked = _checked[index];

    return GestureDetector(
      onTap: () => _toggle(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: checked
              ? const Color(0xFF0df2f2).withOpacity(0.08)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: checked
                ? const Color(0xFF0df2f2).withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: checked ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: checked
                    ? const Color(0xFF0df2f2)
                    : Colors.transparent,
                border: Border.all(
                  color: checked
                      ? const Color(0xFF0df2f2)
                      : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: checked
                  ? const Icon(Icons.check, color: Colors.black, size: 16)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: checked
                      ? Colors.white
                      : Colors.white.withOpacity(0.85),
                  fontSize: 15,
                  fontWeight:
                      checked ? FontWeight.w600 : FontWeight.w400,
                  decoration:
                      checked ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Congratulations card ──────────────────────────────────────────────────

  Widget _buildCongratsCard() {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0d3a2a), Color(0xFF0f2323)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0df2f2).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF0df2f2).withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0df2f2).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFF0df2f2),
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'You\'re Fully Prepared!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'All $_totalCount items are checked off. Share your preparedness with family and stay safe.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0df2f2).withOpacity(0.12),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                  color: const Color(0xFF0df2f2).withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Color(0xFF0df2f2), size: 15),
                SizedBox(width: 6),
                Text(
                  'Emergency kit complete',
                  style: TextStyle(
                    color: Color(0xFF0df2f2),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper — show as bottom sheet ─────────────────────────────────────────────

void showPrepChecklist(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const PrepChecklistScreen(),
  );
}
