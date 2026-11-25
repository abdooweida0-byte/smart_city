import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationProvider extends ChangeNotifier {
  LatLng? position;
  String? error;
  bool loading = false;

  Future<LatLng?> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'فعّل خدمة الموقع (GPS) من إعدادات الجهاز';
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw 'صلاحية الموقع مرفوضة، فعّلها من إعدادات التطبيق';
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      position = LatLng(p.latitude, p.longitude);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
    return position;
  }
}
