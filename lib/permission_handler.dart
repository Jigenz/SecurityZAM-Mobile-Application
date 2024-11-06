// lib/permission_handler.dart

import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionHandlerUtil {
  /// Requests all necessary permissions for root detection based on Android version.
  static Future<bool> requestPermissions() async {
    int sdkInt = await _getAndroidSdkInt();

    if (sdkInt >= 30) {
      // Android 11 and above
      // If you need to request MANAGE_EXTERNAL_STORAGE, ensure it's declared in AndroidManifest.xml
      // Uncomment the following lines if necessary
      /*
      PermissionStatus manageStorageStatus = await Permission.manageExternalStorage.request();
      if (!manageStorageStatus.isGranted) {
        return false;
      }
      */
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      // Add other permissions if needed
    ].request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
    });

    return allGranted;
  }

  /// Retrieves the Android SDK version.
  static Future<int> _getAndroidSdkInt() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    }
    // Return a default value or handle other platforms as needed
    return 0;
  }
}
