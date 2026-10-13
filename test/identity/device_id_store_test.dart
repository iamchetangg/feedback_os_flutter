import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feedback_os_flutter/src/identity/device_id_store.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('InMemoryDeviceIdStore', () {
    test('generates a lowercase UUID on first call and caches it', () async {
      final store = InMemoryDeviceIdStore();
      final id1 = await store.getOrCreateDeviceId();

      expect(id1, isNotEmpty);
      expect(id1, equals(id1.toLowerCase()));
      expect(RegExp(r'^[0-9a-f\-]{36}$').hasMatch(id1), isTrue);

      final id2 = await store.getOrCreateDeviceId();
      expect(id2, equals(id1));
    });

    test('lowercases initial device id', () async {
      final store = InMemoryDeviceIdStore(
        initialDeviceId: 'ABCD-1234-EFGH-5678',
      );
      final id = await store.getOrCreateDeviceId();
      expect(id, equals('abcd-1234-efgh-5678'));
    });

    test('clear removes cached device id', () async {
      final store = InMemoryDeviceIdStore(initialDeviceId: 'existing-id');
      await store.clear();
      expect(await store.getExistingDeviceId(), isNull);
    });
  });

  group('SecureDeviceIdStore', () {
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
    });

    test('returns existing device id in lowercase if present in storage',
        () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890');

      final store = SecureDeviceIdStore(storage: mockStorage);
      final id = await store.getOrCreateDeviceId();

      expect(id, equals('a1b2c3d4-e5f6-7890-abcd-ef1234567890'));
      verify(() => mockStorage.read(key: 'fos_device_id_v1')).called(1);

      // Subsequent call uses memory cache and does not read storage again
      final idAgain = await store.getOrCreateDeviceId();
      expect(idAgain, equals(id));
      verifyNoMoreInteractions(mockStorage);
    });

    test(
        'generates, persists, and returns lowercase UUIDv4 when storage is empty',
        () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async {});

      final store = SecureDeviceIdStore(storage: mockStorage);
      final id = await store.getOrCreateDeviceId();

      expect(id, isNotEmpty);
      expect(id, equals(id.toLowerCase()));
      expect(RegExp(r'^[0-9a-f\-]{36}$').hasMatch(id), isTrue);

      verify(() => mockStorage.read(key: 'fos_device_id_v1')).called(1);
      verify(() => mockStorage.write(key: 'fos_device_id_v1', value: id))
          .called(1);
    });

    test('clear calls storage delete and clears in-memory cache', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      final store = SecureDeviceIdStore(storage: mockStorage);
      await store.clear();

      verify(() => mockStorage.delete(key: 'fos_device_id_v1')).called(1);
    });
  });
}
