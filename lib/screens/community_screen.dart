import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../utils/snackbar_helper.dart';

class CommunityPost {
  final String userName;
  final String timeAgo;
  final String location;
  final String severity;
  final Color severityColor;
  final String content;
  final String? imageUrl;
  final int verified;
  final int comments;
  final bool isVerified;

  CommunityPost({
    required this.userName,
    required this.timeAgo,
    required this.location,
    required this.severity,
    required this.severityColor,
    required this.content,
    this.imageUrl,
    required this.verified,
    required this.comments,
    required this.isVerified,
  });
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['Nearby', 'Floods', 'Smog/AQI', 'Roads'];

  final List<CommunityPost> _posts = [
    CommunityPost(
      userName: 'Ali Khan',
      timeAgo: '12m ago',
      location: 'Johar Town, Lahore',
      severity: 'Critical',
      severityColor: AppColors.danger,
      content:
          'Main boulevard completely blocked by water near the Emporium Mall signal. Water levels are rising fast. Avoid this route if you have a sedan.',
      imageUrl:
          'https://via.placeholder.com/300x200?text=Flood+Scene',
      verified: 45,
      comments: 12,
      isVerified: true,
    ),
    CommunityPost(
      userName: 'Sarah M.',
      timeAgo: '1h ago',
      location: 'Liberty Market',
      severity: 'AQI Alert',
      severityColor: AppColors.warning,
      content:
          'AQI feels terrible today. Visibility is very low near the market area. Everyone is coughing, please wear masks!',
      imageUrl:
          'https://via.placeholder.com/300x200?text=Smog+Scene',
      verified: 12,
      comments: 3,
      isVerified: false,
    ),
    CommunityPost(
      userName: 'Traffic Bot',
      timeAgo: '2h ago',
      location: 'Canal Road',
      severity: 'Update',
      severityColor: AppColors.textSecondary,
      content:
          'Traffic moving slowly due to construction near the underpass. Expect delays of 15-20 minutes.',
      imageUrl: null,
      verified: 89,
      comments: 0,
      isVerified: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Column(
        children: [
          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  // Top Bar with Title and Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Community Watch',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search, color: AppColors.textPrimary),
                            onPressed: () => showComingSoon(context, 'Search'),
                          ),
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications,
                                    color: AppColors.textPrimary),
                                onPressed: () => Navigator.pushNamed(context, '/alerts'),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        _filters.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              _filters[index],
                              style: TextStyle(
                                color: _selectedFilter == index
                                    ? AppColors.textInverse
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: _selectedFilter == index,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = index;
                              });
                            },
                            backgroundColor: AppColors.bgCard,
                            selectedColor: AppColors.primary,
                            side: BorderSide(
                              color: _selectedFilter == index
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Posts Feed
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                return _buildPostCard(_posts[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/report-hazard'),
        backgroundColor: AppColors.primary,
        label: Text(
          'Report',
          style: AppTextStyles.label.copyWith(color: AppColors.textInverse),
        ),
        icon: const Icon(Icons.add_alert, color: AppColors.textInverse),
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    return Card(
      color: AppColors.bgCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Severity Indicator
          if (post.severity.isNotEmpty)
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: post.severityColor,
                borderRadius:
                    const BorderRadius.only(topLeft: Radius.circular(12)),
              ),
            ),
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.border,
                      ),
                        child: Center(
                        child: Text(
                          post.userName[0],
                          style: AppTextStyles.titleMed.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                post.userName,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (post.isVerified)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: AppColors.success,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                            Row(
                            children: [
                              Text(
                                post.timeAgo,
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '•',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.location_on,
                                size: 10,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  post.location,
                                  style: AppTextStyles.label.copyWith(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: post.severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: post.severityColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        post.severity,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: post.severityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              post.content,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (post.imageUrl != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    post.severityColor.withOpacity(0.15),
                    AppColors.bgElevated,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  color: AppColors.textDisabled,
                  size: 36,
                ),
              ),
            ),
          if (post.imageUrl != null) const SizedBox(height: 12),
          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.thumb_up,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.verified} Agrees',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.comments}',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.share,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
