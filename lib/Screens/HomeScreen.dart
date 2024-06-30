import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:testmap/Widgets/markers.dart';


class MarkerInfo {
  final LatLng position;
  final String info;
  final String name;

  MarkerInfo(this.position, this.info, this.name);
}

class Testmap extends StatefulWidget {
  const Testmap({Key? key}) : super(key: key);

  @override
  State<Testmap> createState() => _TestmapState();
}

class _TestmapState extends State<Testmap> {
  List<MarkerInfo> points = [];
  List<LatLng> polylinePoints = [];
  MapOptions? mylocation;
  late MapController mapController;
  Position? cl;
  late double lat;
  late double long;
  TextEditingController searchController = TextEditingController();
  List<dynamic> searchResults = [];

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    requestPermissionsAndFetchLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search for an address',
            suffixIcon: IconButton(
              icon: Icon(Icons.search),
              onPressed: searchAddress,
            ),
          ),
          onChanged: (value) => fetchSuggestions(value),
        ),
        backgroundColor: Colors.lightBlue,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.map),
              title: Text('Markers Page'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Markerspage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: mylocation == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: mylocation!,
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 80,
                          height: 80,
                          point: LatLng(lat, long),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 45,
                          ),
                        ),
                        ...points.map((markerInfo) => Marker(
                              point: markerInfo.position,
                              width: 80,
                              height: 80,
                              child: GestureDetector(
                                onTap: () {
                                  showMarkerInfoDialog(markerInfo.info);
                                },
                                onLongPress: () {
                                  showDeleteDialog(markerInfo);
                                },
                                onDoubleTap: () {
                                  showSaveMarkerDialog(markerInfo.position);
                                },
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 45,
                                ),
                              ),
                            )),
                      ],
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: polylinePoints,
                          color: Colors.blue,
                          strokeWidth: 5,
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: getRoute,
                    child: const Icon(Icons.directions),
                  ),
                ),
                Positioned(
                  top: 80,
                  left: 20,
                  right: 20,
                  child: searchResults.isNotEmpty
                      ? Card(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(searchResults[index]['properties']
                                    ['label']),
                                onTap: () {
                                  selectSuggestion(index);
                                },
                              );
                            },
                          ),
                        )
                      : Container(),
                ),
              ],
            ),
    );
  }

  Future<void> searchAddress() async {
    var query = searchController.text;
    if (query.isEmpty) return;
    var response = await http.get(getGeocodeUrl(query));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      if (data['features'] != null && data['features'].isNotEmpty) {
        setState(() {
          searchResults = data['features'];
        });
      } else {
        setState(() {
          searchResults = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No results found.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch search results.")),
      );
    }
  }

  Future<void> fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    var response = await http.get(getGeocodeUrl(query));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        searchResults = data['features'];
      });
    } else {
      setState(() {
        searchResults = [];
      });
    }
  }

  void selectSuggestion(int index) {
    var selectedFeature = searchResults[index];
    var coordinates = selectedFeature['geometry']['coordinates'];
    var position = LatLng(coordinates[1], coordinates[0]);
    var name = selectedFeature['properties']['label'];

    setState(() {
      points.add(MarkerInfo(position, selectedFeature['properties']['label'], name));
      searchResults = [];
      searchController.clear();
    });

    mapController.move(position, 15.0);
  }

  Future<void> getRoute() async {
    if (points.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select at least two points.")),
      );
      return;
    }

    var response = await http.get(getRouteUrl(
        '${points.first.position.longitude},${points.first.position.latitude}',
        '${points.last.position.longitude},${points.last.position.latitude}'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      setState(() {
        polylinePoints =
            (data['features'][0]['geometry']['coordinates'] as List)
                .map((p) => LatLng(p[1].toDouble(), p[0].toDouble()))
                .toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to fetch route: ${response.statusCode}")),
      );
    }
  }

  Future<void> requestPermissionsAndFetchLocation() async {
    await getPermission();
    await getLatAndLang();
  }

  Future<void> getPermission() async {
    bool servicesEnabled;
    LocationPermission permission;
servicesEnabled = await Geolocator.isLocationServiceEnabled();
    if (!servicesEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location services are not enabled")),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location permissions are denied")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Location permissions are permanently denied, we cannot request permissions."),
        ),
      );
      return;
    }
  }

  Future<void> getLatAndLang() async {
    try {
      cl = await Geolocator.getCurrentPosition();
      lat = cl!.latitude;
      long = cl!.longitude;
      mylocation = MapOptions(
        initialZoom: 4,
        initialCenter: LatLng(lat, long),
        onTap: (tapPosition, point) {
          setState(() {
            points.add(MarkerInfo(point, 'Marker at ${point.latitude}, ${point.longitude}', 'Unnamed Place'));
          });
        },
      );
      setState(() {});
    } catch (e) {
      print('Could not fetch location: $e');
    }
  }

  Uri getGeocodeUrl(String query) {
    return Uri.parse(
        'https://api.openrouteservice.org/geocode/search?api_key='Write your API key'&text=$query');
  }

  Uri getRouteUrl(String start, String end) {
    return Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key='Write your API key'&start=$start&end=$end');
  }

  void showMarkerInfoDialog(String info) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Marker Information'),
          content: Text(info),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showDeleteDialog(MarkerInfo markerInfo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Marker'),
          content: Text('Do you want to delete this marker?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  points.remove(markerInfo);
                });
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void showSaveMarkerDialog(LatLng position) {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Save Marker'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                saveMarkerPosition(position, nameController.text);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void saveMarkerPosition(LatLng position, String name) async {
    var box = await Hive.openBox('favorits');
    await box.add({'latitude': position.latitude, 'longitude': position.longitude, 'name': name});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Marker saved')),
    );
  }
}
