import 'package:flutter/material.dart';

class PrepChecklistScreen extends StatefulWidget {
  const PrepChecklistScreen({super.key});

  @override
  State<PrepChecklistScreen> createState() => _PrepChecklistScreenState();
}

class _PrepChecklistScreenState extends State<PrepChecklistScreen> {
  final Map<String, bool> _checklistItems = {
    'Emergency supply kit (water, food, first aid)': false,
    'Flashlight and extra batteries': false,
    'Battery-powered or hand-crank radio': false,
    'Important documents in waterproof container': false,
    'Cash and credit cards': false,
    'Prescription medications and glasses': false,
    'Phone charger and backup battery': false,
    'Local maps and evacuation routes': false,
  };

  int get _completedCount =>
      _checklistItems.values.where((checked) => checked).length;
  int get _totalCount => _checklistItems.length;
  double get _progress => _completedCount / _totalCount;

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
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
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
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Stay ready for any situation',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Progress Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0df2f2).withOpacity(0.15),
                    const Color(0xFF007f80).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0df2f2).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$_completedCount / $_totalCount',
                        style: const TextStyle(
                          color: Color(0xFF0df2f2),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF0df2f2),
                      ),
                    ),
                  ),
                  if (_completedCount == _totalCount) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0df2f2).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.celebration,
                            color: Color(0xFF0df2f2),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Great job! You\'re fully prepared!',
                              style: TextStyle(
                                color: Color(0xFF0df2f2),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // AI Recommendation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology,
                    color: Colors.orange,
                    size: 20,
                  ),
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

          const SizedBox(height: 20),

          // Checklist Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: _checklistItems.entries.map((entry) {
                return _buildChecklistItem(
                  entry.key,
                  entry.value,
                  () {
                    setState(() {
                      _checklistItems[entry.key] = !entry.value;
                    });
                  },
                );
              }).toList(),
            ),
          ),

          // Bottom buttons
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
                      // Share checklist
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Reset checklist
                      setState(() {
                        _checklistItems.updateAll((key, value) => false);
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildChecklistItem(String text, bool checked, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
                  ? const Icon(
                      Icons.check,
                      color: Colors.black,
                      size: 16,
                    )
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
                  fontWeight: checked ? FontWeight.w600 : FontWeight.w400,
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
}

// Helper function to show as bottom sheet
void showPrepChecklist(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const PrepChecklistScreen(),
  );
}
