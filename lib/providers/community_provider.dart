// Run in Supabase SQL Editor:
// CREATE TABLE public.community_posts (
//   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
//   user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
//   username TEXT NOT NULL DEFAULT '',
//   content TEXT NOT NULL,
//   category TEXT NOT NULL DEFAULT 'general' CHECK (category IN ('flood','aqi','roads','general')),
//   city TEXT NOT NULL DEFAULT '',
//   liked_by TEXT[] NOT NULL DEFAULT '{}',
//   image_url TEXT,
//   created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
// );
// ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
// CREATE POLICY "read_all" ON community_posts FOR SELECT USING (true);
// CREATE POLICY "insert_own" ON community_posts FOR INSERT WITH CHECK (auth.uid() = user_id);
// CREATE POLICY "update_likes" ON community_posts FOR UPDATE USING (true);
// CREATE POLICY "delete_own" ON community_posts FOR DELETE USING (auth.uid() = user_id);

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
  });

  final String id;
  final String userId;
  final String username;
  final String content;
  final String city;
  final String category; // 'flood', 'aqi', 'roads', 'general'
  final DateTime createdAt;
  final int likes;
  final bool isLikedByMe;
  final String? imageUrl;

  factory CommunityPost.fromMap(Map<String, dynamic> map, {String? myUid}) {
    final likedBy = (map['liked_by'] as List?)?.cast<String>() ?? [];
    return CommunityPost(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      username: map['username'] as String? ?? 'Anonymous',
      content: map['content'] as String? ?? '',
      city: map['city'] as String? ?? '',
      category: map['category'] as String? ?? 'general',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      likes: likedBy.length,
      isLikedByMe: myUid != null && likedBy.contains(myUid),
      imageUrl: map['image_url'] as String?,
    );
  }
}

class CommunityProvider extends ChangeNotifier {
  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'all';

  List<CommunityPost> get posts {
    if (_selectedCategory == 'all') return _posts;
    return _posts.where((p) => p.category == _selectedCategory).toList();
  }
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final client = Supabase.instance.client;
      final myUid = client.auth.currentUser?.id;
      final data = await client
          .from('community_posts')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      _posts = (data as List)
          .map((m) => CommunityPost.fromMap(Map<String, dynamic>.from(m), myUid: myUid))
          .toList();
    } catch (e) {
      _errorMessage = 'Could not load posts.';
      debugPrint('[Community] $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPost({
    required String content,
    required String category,
    required String city,
  }) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return false;
      // Fetch username from profiles
      final profile = await client
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle();
      final username = profile?['username'] as String? ?? 'Anonymous';
      await client.from('community_posts').insert({
        'user_id': user.id,
        'username': username,
        'content': content,
        'category': category,
        'city': city,
        'liked_by': <String>[],
        'created_at': DateTime.now().toIso8601String(),
      });
      await loadPosts();
      return true;
    } catch (e) {
      debugPrint('[Community] addPost error: $e');
      return false;
    }
  }

  Future<void> toggleLike(String postId) async {
    try {
      final client = Supabase.instance.client;
      final myUid = client.auth.currentUser?.id;
      if (myUid == null) return;
      final idx = _posts.indexWhere((p) => p.id == postId);
      if (idx == -1) return;
      final post = _posts[idx];
      // Fetch current liked_by
      final row = await client
          .from('community_posts')
          .select('liked_by')
          .eq('id', postId)
          .single();
      final current = (row['liked_by'] as List?)?.cast<String>() ?? [];
      final updated = post.isLikedByMe
          ? current.where((uid) => uid != myUid).toList()
          : [...current, myUid];
      await client
          .from('community_posts')
          .update({'liked_by': updated})
          .eq('id', postId);
      await loadPosts();
    } catch (e) {
      debugPrint('[Community] toggleLike error: $e');
    }
  }
}
