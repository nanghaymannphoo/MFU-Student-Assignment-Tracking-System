
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/core/utils/status_helpers.dart';

void main() {
  group('formatStatus', () {
    test('returns Completed for DONE status', () {
      expect(formatStatus('DONE'), 'Completed');
    });

    test('returns In Progress for IN_PROGRESS status', () {
      expect(formatStatus('IN_PROGRESS'), 'In Progress');
    });

    test('returns To Do for TODO status', () {
      expect(formatStatus('TODO'), 'To Do');
    });

    test('handles lowercase status', () {
      expect(formatStatus('done'), 'Completed');
    });

    test('returns To Do for unknown status', () {
      expect(formatStatus('UNKNOWN'), 'To Do');
    });
  });

  group('formatRole', () {
    test('returns PC for PC role', () {
      expect(formatRole('PC'), 'PC');
    });

    test('returns Member for MEMBER role', () {
      expect(formatRole('MEMBER'), 'Member');
    });

    test('handles lowercase role', () {
      expect(formatRole('member'), 'Member');
    });

    test('handles lowercase PC role', () {
      expect(formatRole('pc'), 'PC');
    });

    test('returns Member for unknown role', () {
      expect(formatRole('UNKNOWN'), 'Member');
    });
  });

  group('getStatusIcon', () {
    test('returns check circle icon for DONE', () {
      expect(getStatusIcon('DONE'), Icons.check_circle_rounded);
    });

    test('returns hourglass icon for IN_PROGRESS', () {
      expect(getStatusIcon('IN_PROGRESS'), Icons.hourglass_top_rounded);
    });

    test('returns radio button icon for TODO', () {
      expect(
        getStatusIcon('TODO'),
        Icons.radio_button_unchecked_rounded,
      );
    });

    test('returns default icon for unknown status', () {
      expect(
        getStatusIcon('UNKNOWN'),
        Icons.radio_button_unchecked_rounded,
      );
    });
  });
}
