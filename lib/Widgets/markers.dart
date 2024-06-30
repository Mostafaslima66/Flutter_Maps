import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:testmap/Screens/marker_details.dart';



class Markerspage extends StatefulWidget {
  const Markerspage({super.key});

  @override
  State<Markerspage> createState() => _MarkerspageState();
}

class _MarkerspageState extends State<Markerspage> {
  List<Map<String, dynamic>> markers = [];

  @override
  void initState() {
    super.initState();
    fetchMarkers();
  }

  Future<void> fetchMarkers() async {
    var box = await Hive.openBox('favorits');
    setState(() {
      markers = box.values.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  Future<void> deleteMarker(int index) async {
    var box = await Hive.openBox('favorits');
    await box.deleteAt(index);
    fetchMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Markers Page'),
      ),
      body: markers.isEmpty
          ? Center(child: Text('No saved markers'))
          : ListView.builder(
              itemCount: markers.length,
              itemBuilder: (context, index) {
                var marker = markers[index];
                return Dismissible(
                  key: Key(marker.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    deleteMarker(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Marker deleted')),
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  child: ListTile(
                    title: Text(marker['name'] ?? 'Unnamed Place'),
                    subtitle: Text(
                        'Lat: ${marker['latitude']}, Lon: ${marker['longitude']}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MarkerDetailPage(
                            position: LatLng(marker['latitude'], marker['longitude']),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
