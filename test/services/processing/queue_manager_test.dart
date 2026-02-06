import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_tracker/services/processing/queue_manager.dart';

void main() {
  group('QueueConfig', () {
    test('default values are correct', () {
      const config = QueueConfig();
      expect(config.maxAttempts, equals(3));
      expect(config.initialBackoffMs, equals(1000));
      expect(config.maxBackoffMs, equals(30000));
      expect(config.pollIntervalMs, equals(5000));
    });

    test('custom values can be set', () {
      const config = QueueConfig(
        maxAttempts: 5,
        initialBackoffMs: 2000,
        maxBackoffMs: 60000,
        pollIntervalMs: 10000,
      );
      expect(config.maxAttempts, equals(5));
      expect(config.initialBackoffMs, equals(2000));
      expect(config.maxBackoffMs, equals(60000));
      expect(config.pollIntervalMs, equals(10000));
    });
  });

  group('QueueState', () {
    test('default values are correct', () {
      const state = QueueState();
      expect(state.isProcessing, isFalse);
      expect(state.currentItem, isNull);
      expect(state.currentStep, isNull);
      expect(state.progress, equals(0.0));
      expect(state.pendingCount, equals(0));
      expect(state.error, isNull);
    });

    test('copyWith updates values correctly', () {
      const state = QueueState();
      final updated = state.copyWith(
        isProcessing: true,
        progress: 0.5,
        pendingCount: 3,
      );

      expect(updated.isProcessing, isTrue);
      expect(updated.progress, equals(0.5));
      expect(updated.pendingCount, equals(3));
      expect(updated.currentItem, isNull);
    });

    test('copyWith with clearError removes error', () {
      final state = const QueueState(error: 'Some error');
      final updated = state.copyWith(clearError: true);

      expect(updated.error, isNull);
    });

    test('stepDescription returns empty for null step', () {
      const state = QueueState();
      expect(state.stepDescription, equals(''));
    });
  });
}
