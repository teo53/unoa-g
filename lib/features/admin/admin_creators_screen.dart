import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/demo_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Admin Creators Management Screen
/// 크리에이터 목록, 활동도, 구독자 현황 관리
class AdminCreatorsScreen extends ConsumerStatefulWidget {
  const AdminCreatorsScreen({super.key});

  @override
  ConsumerState<AdminCreatorsScreen> createState() =>
      _AdminCreatorsScreenState();
}

class _AdminCreatorsScreenState extends ConsumerState<AdminCreatorsScreen> {
  String _searchQuery = '';
  String _sortBy = 'revenue'; // revenue, subscribers, activity

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredCreators = _mockCreators.where((c) {
      if (_searchQuery.isEmpty) return true;
      final name = (c['name'] as String).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort
    filteredCreators.sort((a, b) {
      switch (_sortBy) {
        case 'subscribers':
          return (b['subscribers'] as int).compareTo(a['subscribers'] as int);
        case 'activity':
          return (b['activityScore'] as int)
              .compareTo(a['activityScore'] as int);
        default: // revenue
          return (b['monthlyRevenue'] as int)
              .compareTo(a['monthlyRevenue'] as int);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('크리에이터 관리'),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search + Sort
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: '크리에이터 검색...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.mdBR,
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort_rounded),
                  onSelected: (v) => setState(() => _sortBy = v),
                  itemBuilder: (context) => [
                    _sortMenuItem('revenue', '수익순'),
                    _sortMenuItem('subscribers', '구독자순'),
                    _sortMenuItem('activity', '활동도순'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Creator List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredCreators.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final creator = filteredCreators[index];
                return _CreatorCard(creator: creator, isDark: isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _sortMenuItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (_sortBy == value)
            const Icon(Icons.check, size: 16, color: Colors.indigo)
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _CreatorCard extends StatelessWidget {
  final Map<String, dynamic> creator;
  final bool isDark;

  const _CreatorCard({required this.creator, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activityLevel = creator['activityLevel'] as String;
    final status = creator['status'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: AppRadius.lgBR,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[300],
                backgroundImage: NetworkImage(
                  DemoConfig.avatarUrl(creator['avatarSeed'] as String),
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
                          creator['name'] as String,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      creator['category'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                  ],
                ),
              ),
              _activityBadge(activityLevel),
            ],
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.group_rounded,
                label: '구독자',
                value: '${creator['subscribers']}',
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.payments_rounded,
                label: '월수익',
                value: _formatKrw(creator['monthlyRevenue'] as int),
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.chat_bubble_outline,
                label: '메시지',
                value: '${creator['messagesThisMonth']}',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showCreatorDetail(context, creator);
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('상세'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    side: const BorderSide(color: Colors.indigo),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('경고 발송 기능 (데모)')),
                    );
                  },
                  icon: const Icon(Icons.warning_amber_rounded, size: 16),
                  label: const Text('경고'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('정지 처리 기능 (데모)')),
                    );
                  },
                  icon: const Icon(Icons.block_rounded, size: 16),
                  label: const Text('정지'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'active':
        color = Colors.green;
        label = '활성';
      case 'inactive':
        color = Colors.grey;
        label = '비활성';
      case 'suspended':
        color = Colors.red;
        label = '정지';
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _activityBadge(String level) {
    Color color;
    String label;
    switch (level) {
      case 'high':
        color = Colors.green;
        label = '활발';
      case 'medium':
        color = Colors.orange;
        label = '보통';
      default:
        color = Colors.red;
        label = '저조';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.smBR,
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  String _formatKrw(int amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(1)}만';
    }
    return '${(amount / 1000).toStringAsFixed(0)}천';
  }

  void _showCreatorDetail(BuildContext context, Map<String, dynamic> creator) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return _CreatorDetailSheet(
            creator: creator,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[50],
          borderRadius: AppRadius.smBR,
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: Colors.grey[500]),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorDetailSheet extends StatelessWidget {
  final Map<String, dynamic> creator;
  final ScrollController scrollController;

  const _CreatorDetailSheet({
    required this.creator,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chatLog =
        creator['recentMessages'] as List<Map<String, String>>? ?? [];
    final monthlyRevenue =
        creator['monthlyHistory'] as List<Map<String, dynamic>>? ?? [];

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Profile header
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(
                DemoConfig.avatarUrl(creator['avatarSeed'] as String),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    creator['name'] as String,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${creator['category']} | 가입: ${creator['joinDate']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Subscription breakdown
        Text('구독 현황',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _subscriptionRow('BASIC', creator['basicSubs'] as int, 4900, isDark),
        _subscriptionRow(
            'STANDARD', creator['standardSubs'] as int, 9900, isDark),
        _subscriptionRow('VIP', creator['vipSubs'] as int, 19900, isDark),
        const Divider(height: 24),

        // Monthly Revenue History
        Text('월별 수익 (최근 6개월)',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...monthlyRevenue.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(m['month'] as String, style: theme.textTheme.bodySmall),
                  Text(
                    _formatFullKrw(m['total'] as int),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )),
        const Divider(height: 24),

        // Recent Chat Log
        Text('최근 채팅 로그',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...chatLog.map((msg) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      msg['time'] ?? '',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: msg['type'] == 'broadcast'
                          ? Colors.indigo.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      msg['type'] == 'broadcast' ? '브로드캐스트' : '팬 답장',
                      style: TextStyle(
                        fontSize: 9,
                        color: msg['type'] == 'broadcast'
                            ? Colors.indigo
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      msg['content'] ?? '',
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _subscriptionRow(String tier, int count, int price, bool isDark) {
    final total = count * price;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              tier,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text('$count명', style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text(
            _formatFullKrw(total),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatFullKrw(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return '₩$buffer';
  }
}

// Mock data for creators list
final List<Map<String, dynamic>> _mockCreators = [
  {
    'id': 'creator_001',
    'name': '하늘달',
    'category': 'VTuber',
    'avatarSeed': 'vtuber1',
    'subscribers': 1234,
    'basicSubs': 800,
    'standardSubs': 320,
    'vipSubs': 114,
    'monthlyRevenue': 1250000,
    'messagesThisMonth': 45,
    'activityScore': 65,
    'activityLevel': 'high',
    'status': 'active',
    'joinDate': '2024-06-15',
    'lastBroadcast': '2시간 전',
    'monthlyHistory': [
      {'month': '2026-01', 'total': 1250000},
      {'month': '2025-12', 'total': 1180000},
      {'month': '2025-11', 'total': 980000},
      {'month': '2025-10', 'total': 1050000},
      {'month': '2025-09', 'total': 890000},
      {'month': '2025-08', 'total': 760000},
    ],
    'recentMessages': [
      {
        'time': '14:32',
        'type': 'broadcast',
        'content': '오늘 방송 준비 중이에요! 잠시 후에 만나요~'
      },
      {'time': '14:35', 'type': 'reply', 'content': '기다리고 있었어요! 오늘도 화이팅!'},
      {'time': '14:36', 'type': 'reply', 'content': '방송 언제 시작해요?'},
      {'time': '15:00', 'type': 'broadcast', 'content': '방송 시작합니다! 많이 와주세요'},
    ],
  },
  {
    'id': 'creator_002',
    'name': '별빛',
    'category': 'VTuber',
    'avatarSeed': 'vtuber2',
    'subscribers': 856,
    'basicSubs': 550,
    'standardSubs': 220,
    'vipSubs': 86,
    'monthlyRevenue': 890000,
    'messagesThisMonth': 28,
    'activityScore': 35,
    'activityLevel': 'medium',
    'status': 'active',
    'joinDate': '2024-09-20',
    'lastBroadcast': '1일 전',
    'monthlyHistory': [
      {'month': '2026-01', 'total': 890000},
      {'month': '2025-12', 'total': 920000},
      {'month': '2025-11', 'total': 750000},
      {'month': '2025-10', 'total': 680000},
      {'month': '2025-09', 'total': 720000},
      {'month': '2025-08', 'total': 600000},
    ],
    'recentMessages': [
      {'time': '10:15', 'type': 'broadcast', 'content': '좋은 아침이에요~ 오늘 날씨가 좋네요'},
      {
        'time': '10:20',
        'type': 'reply',
        'content': '좋은 아침이에요! 오늘도 행복한 하루 보내세요'
      },
    ],
  },
  {
    'id': 'creator_003',
    'name': '민서',
    'category': 'K-POP',
    'avatarSeed': 'kpop1',
    'subscribers': 2150,
    'basicSubs': 1400,
    'standardSubs': 520,
    'vipSubs': 230,
    'monthlyRevenue': 2350000,
    'messagesThisMonth': 62,
    'activityScore': 85,
    'activityLevel': 'high',
    'status': 'active',
    'joinDate': '2024-03-10',
    'lastBroadcast': '30분 전',
    'monthlyHistory': [
      {'month': '2026-01', 'total': 2350000},
      {'month': '2025-12', 'total': 2100000},
      {'month': '2025-11', 'total': 1950000},
      {'month': '2025-10', 'total': 1800000},
      {'month': '2025-09', 'total': 1650000},
      {'month': '2025-08', 'total': 1500000},
    ],
    'recentMessages': [
      {'time': '16:00', 'type': 'broadcast', 'content': '새 앨범 작업 중인 사진 공유해요!'},
      {'time': '16:05', 'type': 'reply', 'content': '와 너무 기대돼요!!'},
      {'time': '16:06', 'type': 'reply', 'content': '앨범 언제 나와요? 빨리 듣고 싶어요'},
      {
        'time': '16:10',
        'type': 'broadcast',
        'content': '3월에 발매 예정이에요 조금만 기다려주세요'
      },
    ],
  },
  {
    'id': 'creator_004',
    'name': '루나',
    'category': 'K-POP',
    'avatarSeed': 'kpop2',
    'subscribers': 450,
    'basicSubs': 350,
    'standardSubs': 80,
    'vipSubs': 20,
    'monthlyRevenue': 380000,
    'messagesThisMonth': 5,
    'activityScore': 12,
    'activityLevel': 'low',
    'status': 'inactive',
    'joinDate': '2025-01-05',
    'lastBroadcast': '2주 전',
    'monthlyHistory': [
      {'month': '2026-01', 'total': 380000},
      {'month': '2025-12', 'total': 520000},
      {'month': '2025-11', 'total': 480000},
      {'month': '2025-10', 'total': 450000},
      {'month': '2025-09', 'total': 400000},
      {'month': '2025-08', 'total': 350000},
    ],
    'recentMessages': [
      {
        'time': '09:00',
        'type': 'broadcast',
        'content': '오랜만이에요 여러분... 건강 회복 중이에요'
      },
    ],
  },
];
