import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestPermissions() async {
    try {
      print('Requesting location permissions...');

      // Step 1: Request basic location permission
      var locationStatus = await Permission.location.request();
      print('Location permission status: $locationStatus');

      if (locationStatus.isDenied) {
        print('Location permission denied');
        return false;
      }

      // Step 2: Request background location permission (Android 10+)
      if (await Permission.locationWhenInUse.isGranted) {
        var backgroundLocationStatus = await Permission.locationAlways
            .request();
        print(
          'Background location permission status: $backgroundLocationStatus',
        );

        if (backgroundLocationStatus.isDenied) {
          print(
            'Background location permission denied, but continuing with foreground tracking',
          );
          // Continue with foreground tracking only
        }
      }

      // Check if we have at least basic location permission
      final hasLocationPermission =
          await Permission.location.isGranted ||
              await Permission.locationWhenInUse.isGranted;

      if (hasLocationPermission) {
        print('Location permissions granted successfully');
        return true;
      } else {
        print('No location permissions granted');
        return false;
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }
}