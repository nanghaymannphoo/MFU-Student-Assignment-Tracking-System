import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../models/task_item.dart';

/// Calculates whether a task is overdue based on local time.
/// - Unfinished tasks become overdue after their due date ends in local time (23:59:59).
/// - Completed tasks (DONE) never show as overdue.
/// - Missing or invalid dates are handled safely.
bool isTaskOverdue(TaskItem task) {
  if (task.status.toUpperCase() == 'DONE') return false;
  final dateText = task.dueDate.trim();
  if (dateText.isEmpty) return false;

  final parsed = DateTime.tryParse(dateText);
  if (parsed == null) return false;

  // Due date ends at 23:59:59.999 in local time on that calendar day
  final dueEndOfDay = DateTime(
    parsed.year,
    parsed.month,
    parsed.day,
    23,
    59,
    59,
    999,
  );
  return DateTime.now().isAfter(dueEndOfDay);
}

/// Checks if a task is due today in local time.
bool isTaskDueToday(TaskItem task) {
  if (task.status.toUpperCase() == 'DONE') return false;
  final parsed = DateTime.tryParse(task.dueDate.trim());
  if (parsed == null) return false;
  final now = DateTime.now();
  return parsed.year == now.year && parsed.month == now.month && parsed.day == now.day;
}

/// Returns a human-friendly relative deadline label:
/// e.g. "Due today", "Due tomorrow", "2 days overdue", "Due in 3 days".
String getDeadlineRelativeLabel(String dueDateStr, {String status = 'TODO'}) {
  if (status.toUpperCase() == 'DONE') return 'Completed';
  final trimmed = dueDateStr.trim();
  if (trimmed.isEmpty) return 'No deadline';

  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return 'Invalid date';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(parsed.year, parsed.month, parsed.day);
  final diffDays = dueDay.difference(today).inDays;

  if (diffDays < 0) {
    final daysOverdue = -diffDays;
    return daysOverdue == 1 ? '1 day overdue' : '$daysOverdue days overdue';
  } else if (diffDays == 0) {
    return 'Due today';
  } else if (diffDays == 1) {
    return 'Due tomorrow';
  } else {
    return 'Due in $diffDays days';
  }
}

/// Builds a high-contrast semantic red Overdue badge.
Widget buildOverdueBadge({bool compact = false}) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 6 : 8,
      vertical: compact ? 2 : 4,
    ),
    decoration: BoxDecoration(
      color: AppColors.dangerLight,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: compact ? 11 : 13,
          color: AppColors.danger,
        ),
        const SizedBox(width: 3),
        Text(
          'Overdue',
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.bold,
            color: AppColors.danger,
          ),
        ),
      ],
    ),
  );
}
