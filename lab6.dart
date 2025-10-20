import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Lab6MapPage extends StatefulWidget {
  const Lab6MapPage({super.key});

  @override
  State<Lab6MapPage> createState() => _Lab6MapPageState();
}

class _Lab6MapPageState extends State<Lab6MapPage> {
  late YandexMapController mapController;
  final List<MapObject> mapObjects = [];
  List<MapObjectData> landmarks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLandmarks();
  }

  Future<void> _loadLandmarks() async {
    try {
      final response = await http.get(
        Uri.parse('http://pstgu.yss.su/iu9/mobiledev/lab4_yandex_map/2023.php?x=var13'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        setState(() {
          landmarks = jsonData.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final gpsParts = (item['gps'] as String).split(',');
            final latitude = double.parse(gpsParts[0].trim());
            final longitude = double.parse(gpsParts[1].trim());

            return MapObjectData(
              id: index.toString(),
              name: item['name'],
              address: item['address'],
              tel: item['tel'],
              latitude: latitude,
              longitude: longitude,
            );
          }).toList();

          isLoading = false;
          _initMapObjects();
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading landmarks: $e');
    }
  }

  void _initMapObjects() {
    for (var landmark in landmarks) {
      final placemark = PlacemarkMapObject(
        mapId: MapObjectId(landmark.id),
        point: Point(latitude: landmark.latitude, longitude: landmark.longitude),
        opacity: 1.0,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage('assets/images/img2.png'),
            scale: 0.15,
          ),
        ),
        onTap: (PlacemarkMapObject self, Point point) {
          _showObjectDetails(landmark);
        },
      );
      mapObjects.add(placemark);
    }
  }

  void _showObjectDetails(MapObjectData landmark) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          landmark.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        message: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.phone,
                    size: 20,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      landmark.tel,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.location,
                    size: 20,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      landmark.address,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.map_pin,
                    size: 20,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${landmark.latitude.toStringAsFixed(4)}, ${landmark.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _moveToLocation(landmark.latitude, landmark.longitude);
            },
            child: const Text('Переместить камеру'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          isDefaultAction: true,
          child: const Text('Закрыть'),
        ),
      ),
    );
  }

  void _moveToLocation(double latitude, double longitude) {
    mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(latitude: latitude, longitude: longitude),
          zoom: 15,
        ),
      ),
      animation: const MapAnimation(type: MapAnimationType.smooth, duration: 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Лаб 6 - Яндекс Карты'),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(
                child: CupertinoActivityIndicator(
                  radius: 20,
                ),
              )
            : YandexMap(
                onMapCreated: (YandexMapController controller) {
                  mapController = controller;
                  // Center on first landmark if available
                  if (landmarks.isNotEmpty) {
                    controller.moveCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: Point(
                            latitude: landmarks[0].latitude,
                            longitude: landmarks[0].longitude,
                          ),
                          zoom: 11.0,
                        ),
                      ),
                    );
                  }
                },
                mapObjects: mapObjects,
              ),
      ),
    );
  }
}

class MapObjectData {
  final String id;
  final String name;
  final String address;
  final String tel;
  final double latitude;
  final double longitude;

  MapObjectData({
    required this.id,
    required this.name,
    required this.address,
    required this.tel,
    required this.latitude,
    required this.longitude,
  });
}
