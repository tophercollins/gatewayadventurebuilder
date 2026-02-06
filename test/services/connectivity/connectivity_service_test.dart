import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_tracker/services/connectivity/connectivity_service.dart';

void main() {
  group('ConnectivityService', () {
    late ConnectivityService service;

    setUp(() {
      service = ConnectivityService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initial status is unknown', () {
      expect(service.currentStatus, equals(ConnectivityStatus.unknown));
    });

    test('isOnline returns false when status is unknown', () {
      expect(service.isOnline, isFalse);
    });

    test('statusStream is broadcast stream', () {
      expect(service.statusStream, isA<Stream<ConnectivityStatus>>());
    });
  });

  group('ConnectivityStatus', () {
    test('enum values exist', () {
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.online));
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.offline));
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.unknown));
    });

    test('enum has correct count', () {
      expect(ConnectivityStatus.values.length, equals(3));
    });
  });
}
