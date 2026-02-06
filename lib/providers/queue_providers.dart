import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/processing_queue.dart';
import '../services/connectivity/connectivity_service.dart';
import '../services/processing/queue_manager.dart';
import 'processing_providers.dart';

export '../services/connectivity/connectivity_service.dart'
    show ConnectivityStatus;

/// Provider for ConnectivityService.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for ConnectivityStatus stream.
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.statusStream;
});

/// Provider for current connectivity status.
final currentConnectivityProvider = Provider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.currentStatus;
});

/// Provider for whether the device is online.
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(currentConnectivityProvider);
  return status == ConnectivityStatus.online;
});

/// Provider for QueueManager.
final queueManagerProvider = Provider<QueueManager>((ref) {
  final queueRepo = ref.watch(processingQueueRepositoryProvider);
  final processor = ref.watch(sessionProcessorProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  final manager = QueueManager(
    queueRepo: queueRepo,
    processor: processor,
    connectivity: connectivity,
  );

  ref.onDispose(() => manager.dispose());
  return manager;
});

/// Provider for QueueState stream.
final queueStateProvider = StreamProvider<QueueState>((ref) {
  final manager = ref.watch(queueManagerProvider);
  return manager.stateStream;
});

/// Provider for current queue state.
final currentQueueStateProvider = Provider<QueueState>((ref) {
  final manager = ref.watch(queueManagerProvider);
  return manager.state;
});

/// Provider for pending queue count.
final pendingQueueCountProvider = Provider<int>((ref) {
  final state = ref.watch(currentQueueStateProvider);
  return state.pendingCount;
});

/// Provider for whether queue is currently processing.
final isQueueProcessingProvider = Provider<bool>((ref) {
  final state = ref.watch(currentQueueStateProvider);
  return state.isProcessing;
});

/// Provider for pending queue items.
final pendingQueueItemsProvider = FutureProvider<List<ProcessingQueueItem>>((
  ref,
) async {
  final manager = ref.watch(queueManagerProvider);
  return await manager.getPendingItems();
});

/// Provider for queue item by session ID.
final queueItemBySessionProvider =
    FutureProvider.family<ProcessingQueueItem?, String>((ref, sessionId) async {
      final manager = ref.watch(queueManagerProvider);
      return await manager.getItemForSession(sessionId);
    });

/// Notifier for managing queue initialization and actions.
class QueueNotifier extends StateNotifier<QueueState> {
  QueueNotifier(this._manager, this._connectivity) : super(const QueueState()) {
    _initialize();
  }

  final QueueManager _manager;
  final ConnectivityService _connectivity;

  Future<void> _initialize() async {
    // Initialize connectivity first
    await _connectivity.initialize();

    // Start queue manager
    await _manager.start();

    // Listen to state changes
    _manager.stateStream.listen((newState) {
      state = newState;
    });
  }

  /// Manually trigger queue processing.
  Future<void> processNow() async {
    await _manager.processNow();
  }

  /// Add a session to the queue.
  Future<ProcessingQueueItem> enqueue(String sessionId) async {
    return await _manager.enqueue(sessionId);
  }

  /// Retry a failed item.
  Future<void> retryItem(String itemId) async {
    await _manager.retryItem(itemId);
  }

  /// Clear error state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for queue notifier with state management.
final queueNotifierProvider = StateNotifierProvider<QueueNotifier, QueueState>((
  ref,
) {
  final manager = ref.watch(queueManagerProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return QueueNotifier(manager, connectivity);
});

/// Provider for processing progress for a specific session.
final sessionProcessingProgressProvider = Provider.family<double?, String>((
  ref,
  sessionId,
) {
  final state = ref.watch(queueNotifierProvider);
  if (state.currentItem?.sessionId == sessionId) {
    return state.progress;
  }
  return null;
});

/// Provider for whether a specific session is currently being processed.
final isSessionProcessingProvider = Provider.family<bool, String>((
  ref,
  sessionId,
) {
  final state = ref.watch(queueNotifierProvider);
  return state.currentItem?.sessionId == sessionId;
});
