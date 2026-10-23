import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';

/// Date-range presets used by history and reports.
enum RangePreset {
  thisMonth,
  lastMonth,
  last30Days,
  thisYear,
  allTime,
  custom;

  String get label => switch (this) {
        thisMonth => 'This month',
        lastMonth => 'Last month',
        last30Days => 'Last 30 days',
        thisYear => 'This year',
        allTime => 'All time',
        custom => 'Custom range…',
      };

  /// The range for a fixed preset (null for [allTime] and [custom]).
  DateRange? rangeAt(DateTime now) => switch (this) {
        thisMonth => AppDateUtils.monthOf(now),
        lastMonth => AppDateUtils.shiftMonth(AppDateUtils.monthOf(now), -1),
        last30Days => DateRange(
            DateTime(now.year, now.month, now.day - 29),
            AppDateUtils.dayOf(now).end,
          ),
        thisYear => DateRange(DateTime(now.year), DateTime(now.year + 1)),
        allTime || custom => null,
      };
}

/// The selection returned by [pickDateRange].
class RangeSelection {
  const RangeSelection(this.preset, this.range);
  final RangePreset preset;

  /// Null means "all time".
  final DateRange? range;

  String get label => preset == RangePreset.custom && range != null
      ? '${AppDateUtils.formatShortDay(range!.start)} – '
          '${AppDateUtils.formatShortDay(range!.end.subtract(const Duration(days: 1)))}'
      : preset.label;
}

/// Shows the preset sheet (and the date-range picker for "Custom").
/// Returns null when the user cancels.
Future<RangeSelection?> pickDateRange(
  BuildContext context, {
  required RangePreset current,
  bool allowAllTime = true,
}) async {
  final preset = await showModalBottomSheet<RangePreset>(
    context: context,
    backgroundColor: AppColors.background,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final p in RangePreset.values)
            if (allowAllTime || p != RangePreset.allTime)
              ListTile(
                title: Text(p.label),
                trailing: p == current
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(p),
              ),
        ],
      ),
    ),
  );
  if (preset == null || !context.mounted) return null;

  final now = DateTime.now();
  if (preset != RangePreset.custom) {
    return RangeSelection(preset, preset.rangeAt(now));
  }
  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2000),
    lastDate: DateTime(now.year + 1, 12, 31),
  );
  if (picked == null) return null;
  return RangeSelection(
    preset,
    DateRange(
      AppDateUtils.dayOf(picked.start).start,
      AppDateUtils.dayOf(picked.end).end,
    ),
  );
}
