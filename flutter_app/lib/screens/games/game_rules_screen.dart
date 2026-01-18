import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class GameRulesScreen extends StatelessWidget {
  const GameRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎮 Game Rules'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRuleCard(
              '🍾 Bottle Spin Game',
              'The classic Truth or Dare game with a dating twist!',
              [
                '• Tap "Spin Bottle" to start the game',
                '• The bottle will spin and point to a random player',
                '• Selected player chooses Truth or Dare',
                '• Complete the challenge to earn points',
                '• Have fun and get to know each other!',
              ],
            ),
            const SizedBox(height: 16),
            _buildRuleCard(
              '💭 Truth Questions',
              'Personal questions to spark conversations',
              [
                '• Answer honestly and openly',
                '• Questions are dating-focused',
                '• Share your thoughts and experiences',
                '• No judgment zone - be respectful',
                '• Skip if too personal (but try to participate!)',
              ],
            ),
            const SizedBox(height: 16),
            _buildRuleCard(
              '🎯 Dare Challenges',
              'Fun activities to break the ice',
              [
                '• Complete the challenge within time limit',
                '• Be creative and have fun',
                '• Challenges are safe and appropriate',
                '• Take photos/videos if asked',
                '• Everyone cheers for participation!',
              ],
            ),
            const SizedBox(height: 16),
            _buildRuleCard(
              '👥 Zone Rules',
              'Guidelines for a great experience',
              [
                '• Maximum 6 players per zone',
                '• Only admin can invite new members',
                '• Be respectful to all participants',
                '• No inappropriate content or behavior',
                '• Have fun and make connections!',
              ],
            ),
            const SizedBox(height: 16),
            _buildRuleCard(
              '🏆 Scoring System',
              'How points are calculated',
              [
                '• Truth answered: +10 points',
                '• Dare completed: +15 points',
                '• Creative responses: Bonus points',
                '• Participation matters more than winning',
                '• Everyone\'s a winner in friendship!',
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Remember: This is about making connections!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Be kind, be yourself, and have fun! 💕',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard(String title, String subtitle, List<String> rules) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            ...rules.map((rule) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                rule,
                style: const TextStyle(fontSize: 14),
              ),
            )),
          ],
        ),
      ),
    );
  }
}