import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  String _currentCity = 'Lahore';
  String _currentArea = 'Lahore';
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasRequestedPermission = false;
  bool _hasPermission = false;

  Position? get currentPosition => _currentPosition;
  String get currentCity => _currentCity;
  String get currentArea => _currentArea;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasRequestedPermission => _hasRequestedPermission;
  bool get hasPermission => _hasPermission;

  Future<void> getCurrentLocation() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        _hasRequestedPermission = true;
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permissions are denied';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _hasRequestedPermission = true;
        _errorMessage = 'Location permissions are permanently denied';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _hasPermission = true;

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get city name from coordinates
      await _getCityFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    } catch (e) {
      _errorMessage = 'Error getting location: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _getCityFromCoordinates(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final mark = placemarks.first;
        final subLocality = (mark.subLocality ?? '').trim();
        final locality = (mark.locality ?? '').trim();
        final admin = (mark.administrativeArea ?? '').trim();

        _currentCity = locality.isNotEmpty
            ? locality
            : admin.isNotEmpty
                ? admin
                : 'Unknown';

        if (subLocality.isNotEmpty && locality.isNotEmpty) {
          _currentArea = '$subLocality, $locality';
        } else if (subLocality.isNotEmpty) {
          _currentArea = subLocality;
        } else if (locality.isNotEmpty && admin.isNotEmpty && locality != admin) {
          _currentArea = '$locality, $admin';
        } else if (locality.isNotEmpty) {
          _currentArea = locality;
        } else if (admin.isNotEmpty) {
          _currentArea = admin;
        } else {
          _currentArea = 'Unknown';
        }
      }
    } catch (e) {
      // Keep default city if geocoding fails
      _currentCity = 'Lahore';
      _currentArea = 'Lahore';
    }
  }
}
