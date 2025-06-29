import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Cache for location to avoid repeated GPS calls
  Map<String, dynamic>? _cachedLocation;
  DateTime? _lastLocationUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  Future<String> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.locality}, ${place.administrativeArea}, ${place.country}';
      }

      return '${position.latitude}, ${position.longitude}';
    } catch (e) {
      print('Error getting location: $e');
      return 'Location unavailable';
    }
  }

  Future<Map<String, dynamic>> getCurrentLocationWithAddress() async {
    try {
      // Check if we have valid cached location
      if (_cachedLocation != null && 
          _lastLocationUpdate != null &&
          DateTime.now().difference(_lastLocationUpdate!) < _cacheValidDuration) {
        debugPrint('Using cached location');
        return _cachedLocation!;
      }

      await _requestLocationPermission();
      
      Position? position;
      
      // Try multiple location strategies
      try {
        // Strategy 1: High accuracy with timeout
        debugPrint('Attempting high accuracy location...');
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        );
      } catch (e) {
        debugPrint('High accuracy failed: $e');
        
        try {
          // Strategy 2: Medium accuracy with longer timeout
          debugPrint('Attempting medium accuracy location...');
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          );
        } catch (e) {
          debugPrint('Medium accuracy failed: $e');
          
          try {
            // Strategy 3: Get last known position
            debugPrint('Attempting last known position...');
            position = await Geolocator.getLastKnownPosition();
            
            if (position != null) {
              debugPrint('Using last known position from ${position.timestamp}');
            }
          } catch (e) {
            debugPrint('Last known position failed: $e');
          }
        }
      }
      
      // If we still don't have a position, use a fallback
      if (position == null) {
        debugPrint('All location strategies failed, using fallback');
        return _getFallbackLocation();
      }
      
      // Get address from coordinates
      String address = 'Unknown';
      String city = 'Unknown';
      String country = 'Unknown';
      
      try {
        debugPrint('Attempting reverse geocoding for: ${position.latitude}, ${position.longitude}');
        
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, 
          position.longitude,
        ).timeout(Duration(seconds: 8));
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          
          address = _buildDetailedAddress(place);
          city = _extractCity(place);
          country = _extractCountry(place);
          
          debugPrint('Successfully geocoded: $address, $city, $country');
        } else {
          debugPrint('No placemarks found');
          address = _formatCoordinates(position.latitude, position.longitude);
        }
      } catch (e) {
        debugPrint('Reverse geocoding failed: $e');
        address = _formatCoordinates(position.latitude, position.longitude);
        city = 'Location not available';
        country = 'Unknown';
      }
      
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'city': city,
        'country': country,
        'accuracy': position.accuracy,
        'timestamp': position.timestamp,
      };
      
      // Cache the result
      _cachedLocation = locationData;
      _lastLocationUpdate = DateTime.now();
      
      return locationData;
      
    } catch (e) {
      debugPrint('Location service error: $e');
      return _getFallbackLocation();
    }
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
  }

  Map<String, dynamic> _getFallbackLocation() {
    // Use a reasonable fallback location (Buea, Cameroon based on your location)
    return {
      'latitude': 4.1537,
      'longitude': 9.2993,
      'address': 'Buea, South-West Region',
      'city': 'Buea',
      'country': 'Cameroon',
      'accuracy': 0.0,
      'timestamp': DateTime.now(),
    };
  }

  String _formatCoordinates(double lat, double lng) {
    return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
  }

  String _buildDetailedAddress(Placemark place) {
    List<String> addressParts = [];
    
    if (place.name != null && place.name!.isNotEmpty && place.name != place.locality) {
      addressParts.add(place.name!);
    }
    
    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      addressParts.add(place.subLocality!);
    }
    
    if (place.locality != null && place.locality!.isNotEmpty) {
      bool alreadyIncluded = addressParts.any((part) => 
        part.toLowerCase().contains(place.locality!.toLowerCase()));
      if (!alreadyIncluded) {
        addressParts.add(place.locality!);
      }
    }
    
    if (place.subAdministrativeArea != null && 
        place.subAdministrativeArea!.isNotEmpty &&
        place.subAdministrativeArea != place.locality) {
      addressParts.add(place.subAdministrativeArea!);
    }
    
    String address = addressParts.isNotEmpty ? addressParts.join(', ') : '';
    
    if (address.isEmpty || address.length < 3) {
      List<String> fallbackParts = [];
      
      if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
        fallbackParts.add(place.thoroughfare!);
      }
      
      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        fallbackParts.add(place.administrativeArea!);
      }
      
      if (fallbackParts.isNotEmpty) {
        address = fallbackParts.join(', ');
      }
    }
    
    return address.isNotEmpty ? address : 'Address details not available';
  }

  String _extractCity(Placemark place) {
    if (place.locality != null && place.locality!.isNotEmpty) {
      return place.locality!;
    }
    
    if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
      return place.subAdministrativeArea!;
    }
    
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      return place.administrativeArea!;
    }
    
    return 'Unknown City';
  }

  String _extractCountry(Placemark place) {
    if (place.country != null && place.country!.isNotEmpty) {
      return place.country!;
    }
    
    if (place.isoCountryCode != null && place.isoCountryCode!.isNotEmpty) {
      return place.isoCountryCode!;
    }
    
    return 'Unknown Country';
  }

  // Clear cache if needed
  void clearLocationCache() {
    _cachedLocation = null;
    _lastLocationUpdate = null;
    debugPrint('🧹 Location cache cleared');
  }
}
