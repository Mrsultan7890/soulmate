import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/match_service.dart';
import '../../utils/theme.dart';
import '../../widgets/user_card.dart';
import '../../widgets/match_dialog.dart';
import '../settings/advanced_filter_screen.dart';
import '../nearby/nearby_users_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final CardSwiperController _controller = CardSwiperController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _applyAdvancedFilters(Map<String, dynamic> filters) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    
    if (authService.token != null) {
      // Call advanced discovery API with filters
      await userService.fetchAdvancedDiscoverUsers(
        authService.token!,
        filters: filters,
      );
    }
  }

  Future<void> _loadUsers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    
    if (authService.token != null) {
      await userService.fetchDiscoverUsers(authService.token!);
    }
  }

  bool _handleSwipe(int index, int? previousIndex, CardSwiperDirection direction) {
    if (index >= Provider.of<UserService>(context, listen: false).discoverUsers.length) return false;

    final swipedUser = Provider.of<UserService>(context, listen: false).discoverUsers[index];
    final isLike = direction == CardSwiperDirection.right;

    final authService = Provider.of<AuthService>(context, listen: false);
    final matchService = Provider.of<MatchService>(context, listen: false);

    if (authService.token != null) {
      matchService.swipe(
        token: authService.token!,
        swipedUserId: swipedUser.id,
        isLike: isLike,
      ).then((result) {
        if (result != null && result['is_match'] == true && mounted) {
          matchService.fetchMatches(authService.token!).then((_) {
            if (matchService.matches.isNotEmpty && mounted) {
              showDialog(
                context: context,
                builder: (context) => MatchDialog(match: matchService.matches.first),
              );
            }
          });
        }
      });
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Consumer<UserService>(
                  builder: (context, userService, child) {
                    if (userService.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (userService.discoverUsers.isEmpty) {
                      return _buildEmptyState();
                    }

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: CardSwiper(
                        controller: _controller,
                        cardsCount: userService.discoverUsers.length,
                        onSwipe: _handleSwipe,
                        numberOfCardsDisplayed: 3,
                        backCardOffset: const Offset(0, 40),
                        padding: const EdgeInsets.all(0),
                        cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                          return UserCard(user: userService.discoverUsers[index]);
                        },
                      ),
                    );
                  },
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('HeartLink', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NearbyUsersScreen()));
                },
                icon: const Icon(Icons.location_on, color: AppTheme.primaryColor),
              ),
              IconButton(
                onPressed: () async {
                  final filters = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdvancedFilterScreen()),
                  );
                  if (filters != null) {
                    await _applyAdvancedFilters(filters);
                  }
                },
                icon: const Icon(Icons.tune, color: AppTheme.primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off, size: 60, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text('No more users nearby', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Check back later for new matches', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.close, AppTheme.errorColor, () {
            _controller.swipeLeft();
          }),
          _buildActionButton(Icons.star, AppTheme.secondaryColor, () {
            // Super like functionality
            _controller.swipeUp();
          }),
          _buildActionButton(Icons.favorite, AppTheme.primaryColor, () {
            _controller.swipeRight();
          }),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: icon == Icons.favorite ? 70 : 60,
        height: icon == Icons.favorite ? 70 : 60,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Icon(icon, color: color, size: icon == Icons.favorite ? 32 : 28),
      ),
    );
  }
}
