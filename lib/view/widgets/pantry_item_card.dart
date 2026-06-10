import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../model/pantry_item.dart';
import '../../model/enums.dart';

class PantryItemCard extends StatelessWidget {
  final PantryItem item;
  final bool compact;
  final bool showMenu;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const PantryItemCard({
    super.key,
    required this.item,
    this.compact = false,
    this.showMenu = false,
    this.onTap,
    this.onFavoriteToggle,
  });

  Color get _statusColor {
    if (item.isFinished) return Colors.grey;
    switch (item.expiryStatus) {
      case ExpiryStatus.expired: return AppColors.danger;
      case ExpiryStatus.soon:    return AppColors.warning;
      case ExpiryStatus.safe:    return AppColors.safe;
    }
  }

  @override
  Widget build(BuildContext context) {
    final greyed = item.isFinished;
    return Opacity(
      opacity: greyed ? 0.55 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: _statusColor, width: 5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _itemImage(context),
              const SizedBox(width: 12),
              Expanded(child: _itemBody(context)),
              if (onFavoriteToggle != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    item.favorite ? Icons.favorite : Icons.favorite_border,
                    color: item.favorite
                        ? AppColors.danger
                        : AppColors.textMut(context),
                    size: 22,
                  ),
                  onPressed: onFavoriteToggle,
                ),
              if (showMenu)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child:
                      Icon(Icons.more_vert, color: AppColors.textSec(context)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 60,
        height: 60,
        color: AppColors.chipBg(context),
        child: item.imageAsset != null
            ? Image.asset(
                item.imageAsset!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text('img',
                      style: TextStyle(
                          color: AppColors.textMut(context), fontSize: 12)),
                ),
              )
            : Center(
                child: Icon(Icons.image_not_supported_outlined,
                    color: AppColors.textMut(context), size: 24),
              ),
      ),
    );
  }

  Widget _itemBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPri(context),
                  decoration: item.isFinished
                      ? TextDecoration.lineThrough
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (compact)
              Text(
                _daysLabel(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _statusColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        if (!compact)
          Text(
            '${item.category} • ${item.quantityLabel}',
            style:
                TextStyle(fontSize: 12, color: AppColors.textSec(context)),
          ),
        const SizedBox(height: 4),
        if (!compact)
          Row(
            children: [
              Icon(
                item.isFinished
                    ? Icons.check_circle
                    : item.expiryStatus == ExpiryStatus.expired
                        ? Icons.error_outline
                        : item.expiryStatus == ExpiryStatus.soon
                            ? Icons.calendar_today
                            : Icons.check_circle_outline,
                color: _statusColor,
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.isFinished ? 'Finished' : item.expiryLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          )
        else
          Text(
            item.expiryLabel,
            style:
                TextStyle(fontSize: 12, color: AppColors.textSec(context)),
          ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: item.progress,
            minHeight: 6,
            backgroundColor: AppColors.chipBg(context),
            valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
          ),
        ),
      ],
    );
  }

  String _daysLabel() {
    if (item.isFinished) return 'Done';
    final d = item.daysUntilExpiry;
    if (d < 0) return 'Expired';
    if (d == 0) return 'Today';
    if (d == 1) return '1 Day';
    return '$d Days';
  }
}
