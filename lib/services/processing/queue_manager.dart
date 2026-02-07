import 'dart:async';
import 'dart:math';

import '../../data/models/processing_queue.dart';
import '../../data/repositories/processing_queue_repository.dart';
import '../connectivity/connectivity_service.dart';
import 'processing_types.dart';
import 'session_processor.dart';

/// Configuration for queue processing behavior.
class QueueConfig {
  const QueueConfig({
    this.maxAttempts = 3,
    this.initialBackoffMs = 1000,
    this.maxBackoffMs = 30000,
    this.pollIntervalMs = 5000,
  });

  /// Maximum number of retry attempts before marking as error.
  final int maxAttempts;

  /// Initial backoff delay in milliseconds.
  final int initialBackoffMs;

  /// Maximum backoff delay in milliseconds.
  final int maxBackoffMs;

  /// Interval between queue polling in milliseconds.
  final int pollIntervalMs;
}

/// State of queue processing.
class QueueState {
  const QueueState({
    this.isProcessing = false,
    this.currentItem,
    this.currentStep,
    this.progress = 0.0,
    this.pendingCount = 0,
    this.error,
  });

  final bool isProcessing;
  final ProcessingQueueItem? currentItem;
  final ProcessingStep? currentStep;
  final double progress;
  final int pendingCount;
  final String? error;

  QueueState copyWith({
    bool? isProcessing,
    ProcessingQueueItem? currentItem,
    ProcessingStep? currentStep,
    double? progress,
    int? pendingCount,
    String? error,
    bool clearCurrentItem = false,
    bool clearError = false,
  }) {
    return QueueState(
      isProcessing: isProcessing ?? this.isProcessing,
      currentItem: clearCurrentItem ? null : (currentItem ?? this.currentItem),
      currentStep: currentStep ?? this.currentStep,
      progress: progress ?? this.progress,
      pendingCount: pendingCount ?? this.pendingCount,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Get human-readable step description.
  String get stepDescription {
    switch (currentStep) {
      case ProcessingStep.loadingContext:
        return 'Loading session data...';
      case ProcessingStep.generatingSummary:
        return 'Generating summary...';
      case ProcessingStep.extractingScenes:
        return 'Identifying scenes...';
      case ProcessingStep.extractingEntities:
        return 'Extracting NPCs, locations, and items...';
      case ProcessingStep.extractingActionItems:
        return 'Finding action items...';
      case ProcessingStep.extractingPlayerMoments:
        return 'Capturing player moments...';
      case ProcessingStep.savingResults:
        return 'Saving results...';
      case ProcessingStep.complete:
        return 'Processing complete';
      case null:
        return '';
    }
  }
}

/// Callback when a queue item completes successfully.
typedef QueueItemCompleteCallback =
    Future<void> Function(String sessionId, ProcessingResult result);

/// Manages the processing queue for offline-first session processing.
/// Monitors the queue, checks connectivity, and processes items when online.
class QueueManager {
  QueueManager({
    required ProcessingQueueRepository queueRepo,
    required SessionProcessor processor,
    required ConnectivityService connectivity,
    QueueConfig config = const QueueConfig(),
    this.onItemComplete,
  }) : _queueRepo = queueRepo,
       _processor = processor,
       _connectivity = connectivity,
       _config = config;

  /// Called after a queue item is successfully processed.
  final QueueItemCompleteCallback? onItemComplete;

  final ProcessingQueueRepository _queueRepo;
  final SessionProcessor _processor;
  final ConnectivityService _connectivity;
  final QueueConfig _config;

  Timer? _pollTimer;
  bool _isRunning = false;
  final _stateController = StreamController<QueueState>.broadcast();
  QueueState _state = const QueueState();

  /// Stream of queue state changes.
  Stream<QueueState> get stateStream => _stateController.stream;

  /// Current queue state.
  QueueState get state => _state;

  /// Start the queue manager.
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    // Set up reconnect callback
    _connectivity.onReconnect = _onReconnect;

    // Update pending count
    await _updatePendingCount();

    // Start polling timer
    _pollTimer = Timer.periodic(
      Duration(milliseconds: _config.pollIntervalMs),
      (_) => _checkAndProcess(),
    );

    // Initial check
    await _checkAndProcess();
  }

  /// Stop the queue manager.
  void stop() {
    _isRunning = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _connectivity.onReconnect = null;
  }

  /// Manually trigger queue processing.
  Future<void> processNow() async {
    if (_state.isProcessing) return;
    await _checkAndProcess();
  }

  /// Add a session to the processing queue.
  Future<ProcessingQueueItem> enqueue(String sessionId) async {
    final item = await _queueRepo.enqueue(sessionId);
    await _updatePendingCount();

    // Try to process immediately if online
    if (_connectivity.isOnline && !_state.isProcessing) {
      _checkAndProcess();
    }

    return item;
  }

  void _onReconnect() {
    // When we come back online, start processing
    if (!_state.isProcessing) {
      _checkAndProcess();
    }
  }

  Future<void> _checkAndProcess() async {
    if (!_isRunning) return;
    if (_state.isProcessing) return;
    if (!_connectivity.isOnline) return;

    await _processNextItem();
  }

  Future<void> _processNextItem() async {
    final item = await _queueRepo.getNextPending();
    if (item == null) return;

    _updateState(
      _state.copyWith(
        isProcessing: true,
        currentItem: item,
        progress: 0.0,
        clearError: true,
      ),
    );

    try {
      await _queueRepo.markProcessing(item.id);

      final result = await _processor.processSession(
        item.sessionId,
        onProgress: (step, progress) {
          _updateState(_state.copyWith(currentStep: step, progress: progress));
        },
      );

      if (result.success) {
        await _queueRepo.markComplete(item.id);
        try {
          await onItemComplete?.call(item.sessionId, result);
        } catch (_) {
          // Notification failures should not affect queue processing.
        }
      } else {
        await _handleError(item, result.error ?? 'Unknown error');
      }
    } catch (e) {
      await _handleError(item, e.toString());
    }

    _updateState(
      _state.copyWith(
        isProcessing: false,
        clearCurrentItem: true,
        progress: 0.0,
      ),
    );

    await _updatePendingCount();

    // Continue processing if there are more items
    if (_isRunning && _connectivity.isOnline) {
      await _processNextItem();
    }
  }

  Future<void> _handleError(ProcessingQueueItem item, String error) async {
    final attempts = item.attempts + 1;

    if (attempts >= _config.maxAttempts) {
      // Max attempts reached, mark as permanent error
      await _queueRepo.markError(item.id, error);
      _updateState(_state.copyWith(error: error));
    } else {
      // Schedule retry with exponential backoff
      await _queueRepo.markError(item.id, error);

      final backoffMs = _calculateBackoff(attempts);
      await Future<void>.delayed(Duration(milliseconds: backoffMs));

      // Reset for retry
      await _queueRepo.resetForRetry(item.id);
    }
  }

  int _calculateBackoff(int attempts) {
    // Exponential backoff: initialBackoff * 2^(attempts-1)
    final backoff = _config.initialBackoffMs * pow(2, attempts - 1);
    return min(backoff.toInt(), _config.maxBackoffMs);
  }

  Future<void> _updatePendingCount() async {
    final count = await _queueRepo.getPendingCount();
    _updateState(_state.copyWith(pendingCount: count));
  }

  void _updateState(QueueState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Get all pending queue items.
  Future<List<ProcessingQueueItem>> getPendingItems() async {
    return await _queueRepo.getPendingItems();
  }

  /// Get queue item for a specific session.
  Future<ProcessingQueueItem?> getItemForSession(String sessionId) async {
    return await _queueRepo.getBySessionId(sessionId);
  }

  /// Retry a failed queue item.
  Future<void> retryItem(String itemId) async {
    await _queueRepo.resetForRetry(itemId);
    await _updatePendingCount();

    if (_connectivity.isOnline && !_state.isProcessing) {
      _checkAndProcess();
    }
  }

  /// Dispose of resources.
  void dispose() {
    stop();
    _stateController.close();
  }
}
