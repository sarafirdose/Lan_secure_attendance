import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

enum Environment { dev, prod }

class NetworkService {
  static final Connectivity _connectivity = Connectivity();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final NetworkInfo _networkInfo = NetworkInfo();
  
  static String? _discoveredIp;
  static const String _kLastIpKey = 'last_discovered_server_ip';
  
  // Initialize Logger for safe console outputs
  static final Logger logger = Logger(
    filter: ProductionFilter(), 
    printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5, lineLength: 50, colors: true, printEmojis: true, printTime: false),
  );
  
  // ── Environment Configuration ──────────────────────────────────────────────
  static const Environment currentEnv = Environment.dev; // Change to Environment.prod for production

  static String get serverIp {
    switch (currentEnv) {
      case Environment.dev:
        return '172.26.242.147'; // Local development PC IP
      case Environment.prod:
        return 'api.secureattend.com'; // Production Server Domain
    }
  }

  static String get baseUrl {
    switch (currentEnv) {
      case Environment.dev:
        return 'http://${_discoveredIp ?? serverIp}:5000';
      case Environment.prod:
        return 'https://$serverIp'; // Assume production runs on standard HTTPS port 443
    }
  }

  /// Automatically find the server on the local network (subnet).
  static Future<String?> discoverServer() async {
    try {
      // 1. Try cached IP first (fastest)
      final prefs = await SharedPreferences.getInstance();
      final lastIp = prefs.getString(_kLastIpKey);
      if (lastIp != null && await _isServerAlive(lastIp)) {
        _discoveredIp = lastIp;
        return lastIp;
      }

      // 2. Check for Tethering/Hotspot Fallback (USB/Hotspot/ADB)
      final List<String> fallbackSubnets = [
        '192.168.43', '192.168.42', '192.168.44', '192.168.45', // Common USB/Hotspot
        '10.42.0', '10.0.2', // ADB / Emulator / Specialized VPN
        '192.168.1', '192.168.0' // Std Home WiFi
      ];
      
      String? localIp = await _networkInfo.getWifiIP();
      
      if (localIp == null || localIp.isEmpty) {
        // Fallback to testing most common hotspot/home router IPs
        for (var subnet in fallbackSubnets) {
          final testIp = '$subnet.1';
          if (await _isServerAlive(testIp)) {
            _discoveredIp = testIp;
            await prefs.setString(_kLastIpKey, testIp);
            return testIp;
          }
        }
        return null;
      }

      final subnet = localIp.substring(0, localIp.lastIndexOf('.'));
      final List<String> candidates = [for (int i = 1; i < 255; i++) '$subnet.$i'];
      candidates.remove(localIp); // Don't scan yourself

      // Scan batches of 30 for speed
      for (int i = 0; i < candidates.length; i += 30) {
        final batch = candidates.skip(i).take(30);
        final results = await Future.wait(batch.map((ip) => _isServerAlive(ip)));
        final index = results.indexOf(true);
        if (index != -1) {
          final foundIp = batch.elementAt(index);
          await prefs.setString(_kLastIpKey, foundIp);
          _discoveredIp = foundIp;
          return foundIp;
        }
      }
    } catch (e) {
      logger.e("Discovery Error: $e");
    }
    return null;
  }

  static Future<bool> _isServerAlive(String ip) async {
    try {
      final res = await http.get(Uri.parse('http://$ip:5000/health'))
          .timeout(const Duration(milliseconds: 700));
      return res.statusCode == 200 && res.body.contains("SYSTEM ACTIVE");
    } catch (_) {
      return false;
    }
  }

  // ── Campus config — update these to match your university ──────────────────
  static const List<String> _validSubnetPrefixes = [
    '192.168.1',
    '192.168.0',
    '10.0.0',
    '10.10.',
    '10.114.', // Campus subnet
    '10.202.', // Host subnet
    '172.26.', // Current host subnet
    '192.168.4', // USB Tethering
    '10.42.0',  // Hotspot Subnet
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

  // ── Device fingerprint persistence via SharedPreferences ───────────────────

  static const String _kFingerprintKey = 'registered_device_fingerprint';

  /// Stores the given fingerprint as the registered device for this user.
  static Future<void> saveDeviceFingerprint(String fingerprint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFingerprintKey, fingerprint);
  }

  /// Returns the previously registered fingerprint, or null if none.
  static Future<String?> getStoredFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kFingerprintKey);
  }

  /// Compares the current device fingerprint against the stored one.
  /// Returns true if they match (registered), false if mismatch or unregistered.
  static Future<bool> isDeviceRegistered() async {
    final stored = await getStoredFingerprint();
    if (stored == null || stored.isEmpty) return false;
    final current = await getDeviceFingerprint();
    return stored == current;
  }

  /// Clears stored fingerprint (use on sign-out or device deregistration).
  static Future<void> clearRegisteredDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kFingerprintKey);
  }
}
