import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Contract for persistent device identifier storage.
abstract interface class DeviceIdStore {
  /// Retrieves existing device ID or generates, persists, and returns a new lowercase UUIDv4.
  Future<String> getOrCreateDeviceId();

  /// Reads existing device ID if already persisted, without generating a new one.
  Future<String?> getExistingDeviceId();

  /// Clears stored device ID (primarily for testing).
  Future<void> clear();
}

/// Secure-storage backed implementation using Keychain (iOS) and Keystore (Android).
class SecureDeviceIdStore implements DeviceIdStore {
  static const String _storageKey = 'fos_device_id_v1';
  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  String? _cachedDeviceId;

  SecureDeviceIdStore({
    FlutterSecureStorage? storage,
    Uuid? uuid,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            ),
        _uuid = uuid ?? const Uuid();

  @override
  Future<String> getOrCreateDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      final existing = await _storage.read(key: _storageKey);
      if (existing != null && existing.trim().isNotEmpty) {
        final sanitized = existing.trim().toLowerCase();
        _cachedDeviceId = sanitized;
        return sanitized;
      }

      final newDeviceId = _uuid.v4().toLowerCase();
      await _storage.write(key: _storageKey, value: newDeviceId);
      _cachedDeviceId = newDeviceId;
      return newDeviceId;
    } catch (e) {
      // In case secure storage fails temporarily, return cached or generate ephemeral fallback
      if (_cachedDeviceId != null) return _cachedDeviceId!;
      final fallback = _uuid.v4().toLowerCase();
      _cachedDeviceId = fallback;
      return fallback;
    }
  }

  @override
  Future<String?> getExistingDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId;
    }
    try {
      final existing = await _storage.read(key: _storageKey);
      if (existing != null && existing.trim().isNotEmpty) {
        _cachedDeviceId = existing.trim().toLowerCase();
        return _cachedDeviceId;
      }
      return null;
    } catch (_) {
      return _cachedDeviceId;
    }
  }

  @override
  Future<void> clear() async {
    _cachedDeviceId = null;
    await _storage.delete(key: _storageKey);
  }
}

/// In-memory implementation of DeviceIdStore for unit testing.
class InMemoryDeviceIdStore implements DeviceIdStore {
  String? _deviceId;
  final Uuid _uuid;

  InMemoryDeviceIdStore({String? initialDeviceId, Uuid? uuid})
      : _deviceId = initialDeviceId?.toLowerCase(),
        _uuid = uuid ?? const Uuid();

  @override
  Future<String> getOrCreateDeviceId() async {
    if (_deviceId != null && _deviceId!.isNotEmpty) {
      return _deviceId!;
    }
    _deviceId = _uuid.v4().toLowerCase();
    return _deviceId!;
  }

  @override
  Future<String?> getExistingDeviceId() async => _deviceId;

  @override
  Future<void> clear() async {
    _deviceId = null;
  }
}
