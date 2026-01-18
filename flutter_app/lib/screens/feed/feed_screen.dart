import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../utils/api_constants.dart';
import '../../utils/theme.dart';
import '../user/user_profile_view_screen.dart';
import 'favorites_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<FeedPost> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFeedPosts();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadFeedPosts() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/feed/posts?page=1&limit=20'),
        headers: {'Authorization': 'Bearer ${authService.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _posts = data.map((json) => FeedPost.fromJson(json)).toList();
          _loading = false;
          _currentPage = 1;
        });
      }
    } catch (e) {
      print('Error loading feed: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_loadingMore) return;
    
    setState(() => _loadingMore = true);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/feed/posts?page=${_currentPage + 1}&limit=20'),
        headers: {'Authorization': 'Bearer ${authService.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final newPosts = data.map((json) => FeedPost.fromJson(json)).toList();
        
        setState(() {
          _posts.addAll(newPosts);
          _currentPage++;
          _loadingMore = false;
        });
      }
    } catch (e) {
      print('Error loading more posts: $e');
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _likePost(int postId, int index) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Optimistic update
    setState(() {
      _posts[index].isLiked = !_posts[index].isLiked;
      _posts[index].likesCount += _posts[index].isLiked ? 1 : -1;
    });

    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/feed/posts/$postId/like'),
        headers: {'Authorization': 'Bearer ${authService.token}'},
      );
    } catch (e) {
      // Revert on error
      setState(() {
        _posts[index].isLiked = !_posts[index].isLiked;
        _posts[index].likesCount += _posts[index].isLiked ? 1 : -1;
      });
    }
  }

  Future<void> _favoritePost(int postId, int index) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Optimistic update
    setState(() {
      _posts[index].isFavorited = !_posts[index].isFavorited;
    });

    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/feed/posts/$postId/favorite'),
        headers: {'Authorization': 'Bearer ${authService.token}'},
      );
    } catch (e) {
      // Revert on error
      setState(() {
        _posts[index].isFavorited = !_posts[index].isFavorited;
      });
    }
  }

  Future<void> _viewUserProfile(int postId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/feed/posts/$postId/user'),
        headers: {'Authorization': 'Bearer ${authService.token}'},
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileViewScreen(
              userId: userData['id'],
              userData: userData,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()),
              );
            },
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Favorites',
          ),
          IconButton(
            onPressed: _loadFeedPosts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFeedPosts,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _posts.length + (_loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _posts.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final post = _posts[index];
                  return FeedPostCard(
                    post: post,
                    onLike: () => _likePost(post.id, index),
                    onFavorite: () => _favoritePost(post.id, index),
                    onViewProfile: () => _viewUserProfile(post.id),
                  );
                },
              ),
            ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class FeedPostCard extends StatefulWidget {
  final FeedPost post;
  final VoidCallback onLike;
  final VoidCallback onFavorite;
  final VoidCallback onViewProfile;

  const FeedPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onFavorite,
    required this.onViewProfile,
  });

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  bool _showHeartAnimation = false;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.elasticOut),
    );
  }

  void _handleDoubleTap() {
    if (!widget.post.isLiked) {
      widget.onLike();
      setState(() => _showHeartAnimation = true);
      _likeAnimationController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _showHeartAnimation = false);
            _likeAnimationController.reset();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with double-tap and swipe up
          GestureDetector(
            onDoubleTap: _handleDoubleTap,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < -500) {
                // Swipe up detected
                widget.onViewProfile();
              }
            },
            child: Container(
              height: 400,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: DecorationImage(
                  image: NetworkImage(widget.post.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Swipe up indicator
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Swipe up for profile',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Heart animation
                  if (_showHeartAnimation)
                    Center(
                      child: AnimatedBuilder(
                        animation: _likeAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _likeAnimation.value,
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 100,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Post info and actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.post.userLocation ?? 'Unknown'}, ${widget.post.userAge ?? '?'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(widget.post.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Action buttons
                Row(
                  children: [
                    // Like button
                    GestureDetector(
                      onTap: widget.onLike,
                      child: Row(
                        children: [
                          Icon(
                            widget.post.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: widget.post.isLiked ? Colors.red : Colors.grey[600],
                            size: 24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.post.likesCount}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 24),
                    
                    // Favorite button
                    GestureDetector(
                      onTap: widget.onFavorite,
                      child: Icon(
                        widget.post.isFavorited ? Icons.bookmark : Icons.bookmark_border,
                        color: widget.post.isFavorited ? AppTheme.primaryColor : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // View profile button
                    ElevatedButton(
                      onPressed: widget.onViewProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'View Profile',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }
}

class FeedPost {
  final int id;
  final int userId;
  final String imageUrl;
  int likesCount;
  bool isLiked;
  bool isFavorited;
  final int? userAge;
  final String? userLocation;
  final String createdAt;

  FeedPost({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.likesCount,
    required this.isLiked,
    required this.isFavorited,
    this.userAge,
    this.userLocation,
    required this.createdAt,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: json['id'],
      userId: json['user_id'],
      imageUrl: json['image_url'],
      likesCount: json['likes_count'],
      isLiked: json['is_liked'],
      isFavorited: json['is_favorited'],
      userAge: json['user_age'],
      userLocation: json['user_location'],
      createdAt: json['created_at'],
    );
  }
}