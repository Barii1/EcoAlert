// Hassaan/Bilal: ensure this table exists in Supabase:
// CREATE TABLE IF NOT EXISTS community_posts (
//   id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
//   user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
//   username text NOT NULL DEFAULT '',
//   content text NOT NULL,
//   category text NOT NULL DEFAULT 'general'
//     CHECK (category IN ('flood','aqi','roads','heatwave','general')),
//   city text NOT NULL DEFAULT '',
//   image_url text,
//   liked_by text[] NOT NULL DEFAULT '{}',
//   created_at timestamptz NOT NULL DEFAULT now()
// );
// ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
// CREATE POLICY "read_all"    ON community_posts FOR SELECT USING (true);
// CREATE POLICY "insert_own"  ON community_posts FOR INSERT WITH CHECK (auth.uid() = user_id);
// CREATE POLICY "update_likes" ON community_posts FOR UPDATE USING (true);
// CREATE POLICY "delete_own"  ON community_posts FOR DELETE USING (auth.uid() = user_id);
//
// Also create the Storage bucket  'community-images'  with public access.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    required this.city,
    required this.category,
    required this.createdAt,
    this.likes = 0,
    this.isLikedByMe = false,
    this.imageUrl,
    this.isReport = false,
    this.reportStatus,
  });

  final String id;
  final String userId;
  final String username;
  final String content;
  final String city;
  final String category;
  final DateTime createdAt;
  final int likes;
  final bool isLikedByMe;
  final String? imageUrl;

  // True when this entry came from the reports table (not community_posts)
  final bool isReport;
  final String? reportStatus; // 'approved', 'resolved', etc.

  factory CommunityPost.fromMap(Map<String, dynamic> map, {String? myUid}) {
    final likedBy = (map['liked_by'] as List?)?.cast<String>() ?? [];
    return CommunityPost(
      id:        map['id'] as String,
      userId:    map['user_id'] as String? ?? '',
      username:  map['username'] as String? ?? 'Anonymous',
      content:   map['content'] as String? ?? '',
      city:      map['city'] as String? ?? '',
      category:  map['category'] as String? ?? 'general',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      likes:        likedBy.length,
      isLikedByMe:  myUid != null && likedBy.contains(myUid),
      imageUrl:     map['image_url'] as String?,
    );
  }

  /// Build a community-feed entry from an approved hazard report row.
  factory CommunityPost.fromReport(Map<String, dynamic> r) {
    final images = (r['image_urls'] as List?)?.cast<String>() ?? [];
    return CommunityPost(
      id:           'report_${r['id']}',
      userId:       r['reporter_uid'] as String? ?? '',
      username:     r['reporter_name'] as String? ?? 'Anonymous',
      content:      '${r['hazard_type'] ?? 'Hazard'}: ${r['details'] ?? ''}',
      city:         r['location_label'] as String? ?? '',
      category:     _hazardTypeToCategory(r['hazard_type'] as String?),
      createdAt:    DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
      imageUrl:     images.isNotEmpty ? images.first : null,
      isReport:     true,
      reportStatus: r['status'] as String?,
    );
  }

  static String _hazardTypeToCategory(String? type) {
    if (type == null) return 'general';
    final t = type.toLowerCase();
    if (t.contains('flood'))      return 'flood';
    if (t.contains('aqi') || t.contains('smog')) return 'aqi';
    if (t.contains('cloudburst') || t.contains('rain')) return 'flood';
    if (t.contains('heat'))       return 'heatwave';
    if (t.contains('road'))       return 'roads';
    return 'general';
  }
}

class CommunityProvider extends ChangeNotifier {
  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'all';
  RealtimeChannel? _realtimeChannel;

  List<CommunityPost> get posts {
    if (_selectedCategory == 'all') return _posts;
    return _posts.where((p) => p.category == _selectedCategory).toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  SupabaseClient get _db => Supabase.instance.client;

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> loadPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final myUid = _db.auth.currentUser?.id;

      // Fetch community posts and approved hazard reports in parallel
      final results = await Future.wait([
        _db
            .from('community_posts')
            .select()
            .order('created_at', ascending: false)
            .limit(50),
        _db
            .from('reports')
            .select('id, reporter_uid, reporter_name, hazard_type, details, location_label, image_urls, status, created_at')
            .eq('status', 'approved')
            .order('created_at', ascending: false)
            .limit(50),
      ]);

      final communityPosts = (results[0] as List)
          .map((m) => CommunityPost.fromMap(Map<String, dynamic>.from(m), myUid: myUid))
          .toList();

      final reportPosts = (results[1] as List)
          .map((r) => CommunityPost.fromReport(Map<String, dynamic>.from(r)))
          .toList();

      // Merge and sort by date descending
      final merged = [...communityPosts, ...reportPosts]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _posts = merged;
    } catch (e) {
      _errorMessage = 'Could not load posts.';
      debugPrint('[Community] loadPosts error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Real-time ──────────────────────────────────────────────────────────────

  void startRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = _db
        .channel('community_feed_rt')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_posts',
          callback: (_) => loadPosts(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'reports',
          callback: (_) => loadPosts(), // reload when admin approves/rejects
        )
        .subscribe();
  }

  // ── Add post ───────────────────────────────────────────────────────────────

  /// Returns true on success.
  /// If [image] is provided it is uploaded to the 'community-images' bucket
  /// first and the public URL is stored in image_url.
  Future<bool> addPost({
    required String content,
    required String category,
    required String city,
    File? image,
  }) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return false;

      // Fetch username from profiles table.
      final profile = await _db
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle();
      final username =
          profile?['username'] as String? ?? 'Anonymous';

      // Upload image if provided.
      String? imageUrl;
      if (image != null) {
        try {
          final ext = image.path.split('.').last.toLowerCase();
          final path =
              'community/${user.id}-${DateTime.now().millisecondsSinceEpoch}.$ext';
          await _db.storage.from('community-images').upload(path, image);
          imageUrl =
              _db.storage.from('community-images').getPublicUrl(path);
        } catch (e) {
          debugPrint('[Community] image upload error: $e');
          // Continue posting without image rather than failing.
        }
      }

      await _db.from('community_posts').insert({
        'user_id':    user.id,
        'username':   username,
        'content':    content,
        'category':   category,
        'city':       city,
        'liked_by':   <String>[],
        'image_url':  imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Realtime will trigger a reload; we also reload immediately so the
      // new post appears without waiting for the channel event.
      await loadPosts();
      return true;
    } catch (e) {
      debugPrint('[Community] addPost error: $e');
      return false;
    }
  }

  // ── Delete post ────────────────────────────────────────────────────────────

  /// Deletes [postId] from Supabase and removes it from the local list.
  /// Returns true on success.
  Future<bool> deletePost(String postId) async {
    try {
      await _db.from('community_posts').delete().eq('id', postId);
      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[Community] deletePost error: $e');
      return false;
    }
  }

  // ── Like ───────────────────────────────────────────────────────────────────

  Future<void> toggleLike(String postId) async {
    try {
      final myUid = _db.auth.currentUser?.id;
      if (myUid == null) return;
      final idx = _posts.indexWhere((p) => p.id == postId);
      if (idx == -1) return;
      final post = _posts[idx];
      final row = await _db
          .from('community_posts')
          .select('liked_by')
          .eq('id', postId)
          .single();
      final current = (row['liked_by'] as List?)?.cast<String>() ?? [];
      final updated = post.isLikedByMe
          ? current.where((uid) => uid != myUid).toList()
          : [...current, myUid];
      await _db
          .from('community_posts')
          .update({'liked_by': updated})
          .eq('id', postId);
      await loadPosts();
    } catch (e) {
      debugPrint('[Community] toggleLike error: $e');
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
