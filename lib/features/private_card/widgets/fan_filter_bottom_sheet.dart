import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/fan_filter.dart';

/// Bottom sheet showing available fan filters
/// Based on UNO A app features: DT donations, reply tokens, questions, tiers
class FanFilterBottomSheet extends StatelessWidget {
  final Function(FanFilterType) onFilterSelected;

  const FanFilterBottomSheet({
    super.key,
    required this.onFilterSelected,
  });

  static Future<FanFilterType?> show({
    required BuildContext context,
  }) async {
    return showModalBottomSheet<FanFilterType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FanFilterBottomSheet(
        onFilterSelected: (filter) => Navigator.pop(context, filter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with title and close button
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white : AppColors.text,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '팬 필터 선택',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.text,
                  ),
                ),
              ],
            ),
          ),

          // Filter list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: FanFilterType.values.length,
              itemBuilder: (context, index) {
                final filter = FanFilterType.values[index];
                return _FilterItem(
                  filter: filter,
                  onTap: () => onFilterSelected(filter),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {
  final FanFilterType filter;
  final VoidCallback onTap;

  const _FilterItem({
    required this.filter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: '${filter.displayName} 필터',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(
                filter.icon,
                size: 20,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  filter.displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
