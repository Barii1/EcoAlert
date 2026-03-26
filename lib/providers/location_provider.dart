import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  String _currentCity = 'Lahore';
  bool _isLoading = false;
  String? _errorMessage;

  Position? get currentPosition => _currentPosition;
  String get currentCity => _currentCity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> getCurrentLocation() async {
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
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permissions are denied';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permissions are permanently denied';
        _isLoading = false;
        notifyListeners();
        return;
      }

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
        _currentCity = placemarks.first.locality ?? 'Unknown';
      }
    } catch (e) {
      // Keep default city if geocoding fails
      _currentCity = 'Lahore';
    }
  }
}
