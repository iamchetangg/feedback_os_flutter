import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../features/feedback/domain/entities/feedback_device_info.dart';

/// Contract for gathering device and application environment information.
abstract interface class DeviceInfoProvider {
  Future<FeedbackDeviceInfo> getDeviceInfo();
}

/// Production implementation using device_info_plus and package_info_plus.
class DefaultDeviceInfoProvider implements DeviceInfoProvider {
  final DeviceInfoPlugin _deviceInfoPlugin;

  DefaultDeviceInfoProvider({DeviceInfoPlugin? deviceInfoPlugin})
      : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  FeedbackDeviceInfo? _cached;

  @override
  Future<FeedbackDeviceInfo> getDeviceInfo() async {
    if (_cached != null) return _cached!;

    String osVersion = 'unknown';
    String deviceModel = 'Generic Device';
    String appVersion = '1.0.0';
    String? build;
    String? locale;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion =
          packageInfo.version.isNotEmpty ? packageInfo.version : '1.0.0';
      build =
          packageInfo.buildNumber.isNotEmpty ? packageInfo.buildNumber : null;
    } catch (_) {
      // Fallback defaults on test or unexpected platform failure
    }

    try {
      if (!kIsWeb) {
        locale = Platform.localeName.replaceAll('_', '-');

        if (Platform.isAndroid) {
          final android = await _deviceInfoPlugin.androidInfo;
          osVersion = 'Android ${android.version.release}';
          deviceModel = '${android.manufacturer} ${android.model}';
        } else if (Platform.isIOS) {
          final ios = await _deviceInfoPlugin.iosInfo;
          osVersion = 'iOS ${ios.systemVersion}';
          deviceModel =
              ios.utsname.machine.isNotEmpty ? ios.utsname.machine : ios.model;
        } else if (Platform.isMacOS) {
          final mac = await _deviceInfoPlugin.macOsInfo;
          osVersion = 'macOS ${mac.osRelease}';
          deviceModel = mac.model;
        } else if (Platform.isLinux) {
          final linux = await _deviceInfoPlugin.linuxInfo;
          osVersion = linux.versionId ?? 'Linux';
          deviceModel = linux.prettyName;
        } else if (Platform.isWindows) {
          final win = await _deviceInfoPlugin.windowsInfo;
          osVersion = win.productName;
          deviceModel = 'Windows PC';
        }
      }
    } catch (_) {
      // Keep sensible fallbacks
    }

    final info = FeedbackDeviceInfo(
      osVersion: osVersion,
      appVersion: appVersion,
      build: build,
      deviceModel: deviceModel,
      locale: locale,
    ).sanitized();

    _cached = info;
    return info;
  }
}

/// Static provider used for unit testing.
class StaticDeviceInfoProvider implements DeviceInfoProvider {
  final FeedbackDeviceInfo deviceInfo;

  const StaticDeviceInfoProvider({
    this.deviceInfo = const FeedbackDeviceInfo(
      osVersion: 'iOS 17.5',
      appVersion: '1.2.0',
      build: '42',
      deviceModel: 'iPhone14,2',
      locale: 'en-US',
    ),
  });

  @override
  Future<FeedbackDeviceInfo> getDeviceInfo() async => deviceInfo.sanitized();
}
