import 'package:flutter/material.dart';
import '../../services/markets_service.dart';

// Leaderboard accent color (purple for competitive feel)
const _leaderboardAccent = Color(0xFF6366F1);

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  LeaderboardData? _leaderboardData;
  Map<String, dynamic>? _myRank;
  bool _isLoading = true;
  String _sortBy = 'totalReturn';
  late AnimationController _animController;

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'totalReturn', 'label': 'Returns %', 'icon': Icons.trending_up},
    {'value': 'portfolioValue', 'label': 'Portfolio Value', 'icon': Icons.account_balance_wallet},
    {'value': 'winRate', 'label': 'Win Rate', 'icon': Icons.emoji_events},
    {'value': 'totalTrades', 'label': 'Total Trades', 'icon': Icons.swap_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final results = await Future.wait([
      MarketsService.getLeaderboard(sortBy: _sortBy),
      MarketsService.getMyRank(),
    ]);
    
    setState(() {
      _leaderboardData = results[0] as LeaderboardData?;
      _myRank = results[1] as Map<String, dynamic>?;
      _isLoading = false;
    });
    
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E17) : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Gradient App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0A0E17) : _leaderboardAccent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _leaderboardAccent,
                      _leaderboardAccent.withOpacity(0.8),
                      isDark ? const Color(0xFF1A1F2E) : Colors.deepPurple[300]!,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.leaderboard_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Global Leaderboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Compete with traders worldwide',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Stats Cards
          if (_leaderboardData != null)
            SliverToBoxAdapter(
              child: _buildStatsSection(),
            ),

          // My Rank Card
          if (_myRank != null && _myRank!['userRank'] != null)
            SliverToBoxAdapter(
              child: _buildMyRankCard(),
            ),

          // Sort Options
          SliverToBoxAdapter(
            child: _buildSortOptions(),
          ),

          // Leaderboard List
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_leaderboardData == null || _leaderboardData!.leaderboard.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = _leaderboardData!.leaderboard[index];
                  return _buildLeaderboardItem(entry, index);
                },
                childCount: _leaderboardData!.leaderboard.length,
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = _leaderboardData!.stats;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              '${stats.totalTraders}',
              'Active Traders',
              Icons.people,
              Colors.blue,
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              '${stats.topReturn.toStringAsFixed(1)}%',
              'Top Return',
              Icons.emoji_events,
              Colors.amber,
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              '${stats.averageReturn.toStringAsFixed(1)}%',
              'Avg Return',
              Icons.analytics,
              Colors.green,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankCard() {
    final userRank = _myRank!['userRank'];
    final totalParticipants = _myRank!['totalParticipants'] ?? 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _leaderboardAccent.withOpacity(0.2),
            _leaderboardAccent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _leaderboardAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _leaderboardAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#${userRank['rank']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Ranking',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  '${userRank['username']}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Top ${((userRank['rank'] / totalParticipants) * 100).toStringAsFixed(1)}% of traders',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _leaderboardAccent,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${userRank['totalReturn'] >= 0 ? '+' : ''}${userRank['totalReturn'].toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: userRank['totalReturn'] >= 0 ? Colors.green : Colors.red,
                ),
              ),
              Text(
                '₹${_formatNumber(userRank['portfolioValue'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort By',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _sortOptions.map((option) {
                final isSelected = _sortBy == option['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          option['icon'],
                          size: 16,
                          color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        const SizedBox(width: 4),
                        Text(option['label']),
                      ],
                    ),
                    selectedColor: _leaderboardAccent,
                    backgroundColor: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _sortBy = option['value']);
                        _loadData();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTopThree = entry.rank <= 3;

    Color? medalColor;
    IconData? medalIcon;
    if (entry.rank == 1) {
      medalColor = const Color(0xFFFFD700);
      medalIcon = Icons.emoji_events;
    } else if (entry.rank == 2) {
      medalColor = const Color(0xFFC0C0C0);
      medalIcon = Icons.emoji_events;
    } else if (entry.rank == 3) {
      medalColor = const Color(0xFFCD7F32);
      medalIcon = Icons.emoji_events;
    }

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final delay = index * 0.1;
        final clampedProgress = ((_animController.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final animValue = Curves.easeOut.transform(clampedProgress);

        return Transform.translate(
          offset: Offset(50 * (1 - animValue), 0),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isTopThree
              ? Border.all(color: medalColor!.withOpacity(0.5), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isTopThree
                  ? medalColor!.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isTopThree ? 12 : 8,
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 50,
              child: isTopThree
                  ? Icon(medalIcon, color: medalColor, size: 32)
                  : Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '#${entry.rank}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
            ),

            // Avatar & Name
            CircleAvatar(
              radius: 20,
              backgroundColor: _leaderboardAccent.withOpacity(0.2),
              child: Text(
                entry.username[0].toUpperCase(),
                style: const TextStyle(
                  color: _leaderboardAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.username,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.streak > 3) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department, size: 12, color: Colors.orange),
                              Text(
                                '${entry.streak}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildMiniStat('Trades', '${entry.totalTrades}', isDark),
                      const SizedBox(width: 12),
                      _buildMiniStat('Win Rate', '${entry.winRate.toStringAsFixed(0)}%', isDark),
                    ],
                  ),
                ],
              ),
            ),

            // Returns
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.totalReturn >= 0 ? '+' : ''}${entry.totalReturn.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: entry.totalReturn >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  '₹${_formatNumber(entry.portfolioValue)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, bool isDark) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No traders yet!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to join the leaderboard\nby making your first trade',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(2)}Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}
