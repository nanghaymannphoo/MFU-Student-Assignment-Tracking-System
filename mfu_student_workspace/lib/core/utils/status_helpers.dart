import 'package:flutter/material.dart';
export 'deadline_helpers.dart';

String formatStatus(String status) {
  switch (status.toUpperCase()) {
    case 'DONE':
      return 'Completed';
    case 'IN_PROGRESS':
      return 'In Progress';
    case 'TODO':
    default:
      return 'To Do';
  }
}

IconData getStatusIcon(String status) {
  switch (status.toUpperCase()) {
    case 'DONE':
      return Icons.check_circle_rounded;
    case 'IN_PROGRESS':
      return Icons.hourglass_top_rounded;
    case 'TODO':
    default:
      return Icons.radio_button_unchecked_rounded;
  }
}
