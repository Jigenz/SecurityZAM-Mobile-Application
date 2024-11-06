import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class GeolocationPage extends StatefulWidget {
  const GeolocationPage({Key? key}) : super(key: key);

  @override
  _GeolocationPageState createState() => _GeolocationPageState();
}

class _GeolocationPageState extends State<GeolocationPage> {
  final TextEditingController _ipController = TextEditingController();
  String _locationMessage =
      'Enter an IP address or use GPS to get geolocation data.';
  bool _isLoading = false;
  LatLng? _coordinates;
  GoogleMapController? _mapController;

  // Replace with your actual API key from ipgeolocation.io
  final String _apiKey = '730fefb4e3d143cd85df29448cbf5403';

  Future<void> _getIPLocation(String ipAddress) async {
    setState(() {
      _isLoading = true;
      _locationMessage = 'Fetching location data...';
    });

    try {
      if (ipAddress.isEmpty) {
        // Get the device's public IP address
        final ipResponse =
            await http.get(Uri.parse('https://api.ipify.org?format=json'));
        if (ipResponse.statusCode != 200) {
          setState(() {
            _locationMessage = 'Failed to get your public IP address.';
            _isLoading = false;
          });
          print('Error response: ${ipResponse.body}');
          return;
        }

        final ipData = json.decode(ipResponse.body);
        ipAddress = ipData['ip'];
      }

      // Validate IP address format (IPv4 and IPv6)
      final ipRegex = RegExp(
          r'^(([0-9]{1,3}\.){3}[0-9]{1,3}|([a-fA-F0-9:]+:+)+[a-fA-F0-9]+)$');
      if (!ipRegex.hasMatch(ipAddress)) {
        setState(() {
          _locationMessage = 'Invalid IP address format.';
          _isLoading = false;
        });
        return;
      }

      // Check if IP is private
      if (isPrivateIP(ipAddress)) {
        setState(() {
          _locationMessage = 'Cannot geolocate private IP addresses.';
          _isLoading = false;
        });
        return;
      }

      // Get location information based on IP using ipgeolocation.io
      final locationResponse = await http.get(
        Uri.parse(
            'https://api.ipgeolocation.io/ipgeo?apiKey=$_apiKey&ip=$ipAddress'),
      );

      if (locationResponse.statusCode != 200) {
        setState(() {
          _locationMessage =
              'Failed to get location data. Status code: ${locationResponse.statusCode}';
          _isLoading = false;
        });
        print('Error response: ${locationResponse.body}');
        return;
      }

      final locationData = json.decode(locationResponse.body);

      // Check for errors in the API response
      if (locationData.containsKey('message')) {
        setState(() {
          _locationMessage = 'API Error: ${locationData['message']}';
          _isLoading = false;
        });
        print('API Error: ${locationData['message']}');
        return;
      }

      // Extract location details
      String country = locationData['country_name'] ?? 'Unknown';
      String stateProv = locationData['state_prov'] ?? 'Unknown';
      String city = locationData['city'] ?? 'Unknown';
      double lat = double.tryParse(locationData['latitude'] ?? '') ?? 0.0;
      double lon = double.tryParse(locationData['longitude'] ?? '') ?? 0.0;
      String isp = locationData['isp'] ?? 'Unknown';
      String timezone = locationData['time_zone']['name'] ?? 'Unknown';

      setState(() {
        _locationMessage = '''
IP Address: $ipAddress
Country: $country
State/Province: $stateProv
City: $city
Latitude: $lat
Longitude: $lon
ISP: $isp
Timezone: $timezone
        ''';
        _coordinates = LatLng(lat, lon);
        _isLoading = false;
      });

      // Move the map camera to the new coordinates
      if (_mapController != null && _coordinates != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_coordinates!, 10),
        );
      }
    } catch (e) {
      setState(() {
        _locationMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      print('Exception occurred: $e');
    }
  }

  Future<void> _getGPSLocation() async {
    setState(() {
      _isLoading = true;
      _locationMessage = 'Fetching GPS location data...';
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationMessage = 'Location services are disabled.';
          _isLoading = false;
        });
        return;
      }

      // Check for location permissions
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationMessage = 'Location permissions are denied.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationMessage = 'Location permissions are permanently denied.';
          _isLoading = false;
        });
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Use reverse geocoding to get address details
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks[0];

      setState(() {
        _locationMessage = '''
GPS Location:
Country: ${place.country}
State/Province: ${place.administrativeArea}
City: ${place.locality}
Latitude: ${position.latitude}
Longitude: ${position.longitude}
        ''';
        _coordinates = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Move the map camera to the new coordinates
      if (_mapController != null && _coordinates != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_coordinates!, 15),
        );
      }
    } catch (e) {
      setState(() {
        _locationMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      print('Exception occurred: $e');
    }
  }

  bool isPrivateIP(String ipAddress) {
    try {
      if (ipAddress.contains(':')) {
        // IPv6 private addresses (Unique Local Addresses)
        return ipAddress.startsWith('fc') || ipAddress.startsWith('fd');
      } else {
        // IPv4
        List<String> parts = ipAddress.split('.');
        if (parts.length != 4) return false;
        int octet1 = int.parse(parts[0]);
        int octet2 = int.parse(parts[1]);

        if (octet1 == 10) {
          return true;
        } else if (octet1 == 172 && (octet2 >= 16 && octet2 <= 31)) {
          return true;
        } else if (octet1 == 192 && octet2 == 168) {
          return true;
        } else {
          return false;
        }
      }
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Geolocation'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: _coordinates != null
                ? GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _coordinates!,
                      zoom: 10,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('location'),
                        position: _coordinates!,
                      ),
                    },
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text('Map will appear here'),
                    ),
                  ),
          ),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText:
                          'Enter IP Address (leave empty to use your IP)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    onSubmitted: (value) {
                      _getIPLocation(value.trim());
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                _getIPLocation(_ipController.text.trim());
                              },
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Get IP Geolocation'),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                _getGPSLocation();
                              },
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Get GPS Location'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _locationMessage,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
