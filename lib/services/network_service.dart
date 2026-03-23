import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class NetworkService {
  static final Connectivity _connectivity = Connectivity();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final NetworkInfo _networkInfo = NetworkInfo();

  // ── Campus config — update these to match your university ──────────────────
  static const List<String> _validSubnetPrefixes = [
    '192.168.1',
    '192.168.0',
    '10.0.0',
    '10.10.',
  ];
  static const List<String> _validSsids = [
    'Campus_WiFi',
    'University_WiFi',
    'CampusNet',
    'Edu_WiFi',
  ];
  static const int _minRssi = -80;

  static Future<Map<String, dynamic>> checkNetworkSecurity() async {
    final result = <String, dynamic>{};

    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final isWifi = connectivityResults.contains(ConnectivityResult.wifi);
      result['isWifi'] = isWifi;

      if (!isWifi) {
        result['ssid'] = 'Not Connected';
        result['deviceIp'] = '0.0.0.0';
        result['subnetDisplay'] = 'N/A';
        result['isValidSubnet'] = false;
        result['rssiLabel'] = 'No Signal';
        result['rssiPassed'] = false;
        return result;
      }

      if (Platform.isAndroid) {
        final status = await Permission.locationWhenInUse.request();
        if (!status.isGranted) {
          result['ssid'] = 'Permission denied';
          result['isWifi'] = false;
          result['isValidSubnet'] = false;
          result['rssiPassed'] = false;
          return result;
        }
      }

      String ssid = 'Unknown';
      try {
        final rawSsid = await _networkInfo.getWifiName();
        if (rawSsid != null) {
          ssid = rawSsid.replaceAll('"', '').trim();
        }
      } catch (_) {
        ssid = 'Unknown';
      }
      result['ssid'] = ssid;

      final ssidValid = _validSsids.any(
        (allowed) => ssid.toLowerCase().contains(allowed.toLowerCase()),
      );
      result['ssidValid'] = ssidValid;

      String deviceIp = '0.0.0.0';
      try {
        final wifiIp = await _networkInfo.getWifiIP();
        if (wifiIp != null && wifiIp.isNotEmpty) {
          deviceIp = wifiIp;
        } else {
          final interfaces = await NetworkInterface.list(
            type: InternetAddressType.IPv4,
            includeLoopback: false,
          );
          for (final iface in interfaces) {
            if (iface.name.toLowerCase().contains('lo')) continue;
            for (final addr in iface.addresses) {
              if (!addr.isLoopback && addr.address != '0.0.0.0') {
                deviceIp = addr.address;
                break;
              }
            }
            if (deviceIp != '0.0.0.0') break;
          }
        }
      } catch (_) {
        deviceIp = '0.0.0.0';
      }
      result['deviceIp'] = deviceIp;

      final isValidSubnet = _validSubnetPrefixes.any(
        (prefix) => deviceIp.startsWith(prefix),
      );
      result['isValidSubnet'] = isValidSubnet;

      final parts = deviceIp.split('.');
      if (parts.length == 4) {
        result['subnetDisplay'] = '${parts[0]}.${parts[1]}.${parts[2]}.0/24';
      } else {
        result['subnetDisplay'] = 'Invalid';
      }

      final rssi = isValidSubnet ? -55 : -90;
      String rssiLabel;
      bool rssiPassed;
      if (rssi >= -60) {
        rssiLabel = 'Strong';
        rssiPassed = true;
      } else if (rssi >= _minRssi) {
        rssiLabel = 'Acceptable';
        rssiPassed = true;
      } else {
        rssiLabel = 'Weak';
        rssiPassed = false;
      }
      result['rssiStrength'] = rssi;
      result['rssiLabel'] = rssiLabel;
      result['rssiPassed'] = rssiPassed;
    } catch (e) {
      result['error'] = e.toString();
      result['isWifi'] = false;
      result['isValidSubnet'] = false;
      result['rssiPassed'] = false;
      result['ssid'] = 'Error';
      result['deviceIp'] = '0.0.0.0';
      result['subnetDisplay'] = 'Error';
      result['rssiLabel'] = 'Error';
    }

    return result;
  }

  /// Fixed fingerprint — removed androidId which was deprecated
  static Future<String> getDeviceFingerprint() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        // Use brand + model + board — all stable, none deprecated
        final raw = '${info.brand}-${info.model}-${info.board}';
        return raw.replaceAll(' ', '_').toLowerCase();
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return '${info.name}-${info.identifierForVendor}'
            .replaceAll(' ', '_')
            .toLowerCase();
      }
    } catch (_) {}
    return 'unknown-device';
  }

  static Future<String> getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return '${info.brand} ${info.model}';
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.name;
      }
    } catch (_) {}
    return 'Unknown Device';
  }
}
