import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity status enum for simpler state management.
enum ConnectivityStatus { online, offline, unknown }

/// Service for monitoring network connectivity state.
/// Provides a stream of connectivity changes and triggers callbacks on reconnect.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _statusController = StreamController<ConnectivityStatus>.broadcast();
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  bool _wasOffline = false;

  /// Stream of connectivity status changes.
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Current connectivity status.
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Whether the device is currently online.
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Callback invoked when device reconnects after being offline.
  VoidCallback? onReconnect;

  /// Initialize the service and start monitoring connectivity.
  Future<void> initialize() async {
    // Get initial status
    final results = await _connectivity.checkConnectivity();
    _updateStatus(_resultsToStatus(results));

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_handleChange);
  }

  /// Check current connectivity status.
  Future<ConnectivityStatus> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return _resultsToStatus(results);
  }

  void _handleChange(List<ConnectivityResult> results) {
    final newStatus = _resultsToStatus(results);
    _updateStatus(newStatus);
  }

  void _updateStatus(ConnectivityStatus newStatus) {
    final wasOffline = _wasOffline;
    _wasOffline = newStatus == ConnectivityStatus.offline;

    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _statusController.add(newStatus);

      // Trigger reconnect callback if we just came back online
      if (wasOffline && newStatus == ConnectivityStatus.online) {
        onReconnect?.call();
      }
    }
  }

  ConnectivityStatus _resultsToStatus(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return ConnectivityStatus.unknown;
    }

    // Check if any connection type is available (not none)
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    return hasConnection
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;
  }

  /// Dispose of resources.
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}

/// Typedef for void callbacks.
typedef VoidCallback = void Function();
