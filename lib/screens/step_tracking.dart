import 'package:flutter/material.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:history_buddy/HistSite.dart';
import 'package:history_buddy/screens/step_counter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:hive/hive.dart';

Future<Position> _getGeoLocationPosition() async {
  bool serviceEnabled;
  LocationPermission permission;
  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    await Geolocator.openLocationSettings();
    return Future.error('Location services are disabled.');
  }
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }
  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
}

class StepTracking extends StatefulWidget {
  const StepTracking({Key? key, required this.histsite}) : super(key: key);
  final HistSite histsite;

  @override
  _StepTrackingState createState() => _StepTrackingState();
}

class _StepTrackingState extends State<StepTracking> {
  late LatLng _user;
  late Position currentLocation;
  late double distance;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserLocation();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      final activityRecognition = FlutterActivityRecognition.instance;

      // Check if the user has granted permission. If not, request permission.
      PermissionRequestResult reqResult;
      reqResult = await activityRecognition.checkPermission();
      while (reqResult != PermissionRequestResult.GRANTED)
        reqResult = await activityRecognition.requestPermission();
    });
  }

  Future<Position> locateUser() async {
    return await _getGeoLocationPosition();
  }

  Future getUserLocation() async {
    currentLocation = await locateUser();
    setState(() {
      _user = LatLng(currentLocation.latitude, currentLocation.longitude);
    });
  }

  Future getDistance() async {
    final start = [_center.latitude, _center.longitude];
    final end = [_user.latitude, _user.longitude];
    this.distance =
        Geolocator.distanceBetween(start[0], start[1], end[0], end[1]);
  }

  late LatLng _center = LatLng(
      widget.histsite.getCoordinates()[0], widget.histsite.getCoordinates()[1]);
  late GoogleMapController mapController;

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    final marker = Marker(
      markerId: MarkerId(widget.histsite.getName()),
      position: _center,
      infoWindow: InfoWindow(
        title: widget.histsite.getName(),
      ),
    );

    setState(() {
      markers[MarkerId(widget.histsite.getName())] = marker;
    });
  }

  @override
  Widget build(BuildContext context) {
    Set<Circle> myCircles = {
      Circle(
        circleId: CircleId('1'),
        center: _center,
        radius: 500,
        fillColor: Colors.blue.shade100.withOpacity(0.7),
        strokeColor: Colors.blue.shade100.withOpacity(0.3),
      )
    };

    return FutureBuilder(
        future: Future.wait([
          locateUser(),
          getUserLocation(),
          getDistance(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(widget.histsite.getName()),
                  backgroundColor: Colors.teal[200],
                ),
                floatingActionButton: FloatingActionButton.extended(
                  onPressed: () {
                    if (distance > 500) {
                      showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                                title: Text('Stopped Step Tracking'),
                                content: Text(
                                    'You are too far away from the historical site! Move closer to start step tracking!'),
                                actions: <Widget>[
                                  new TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // dismisses only the dialog and returns nothing
                                    },
                                    child: new Text('OK'),
                                  ),
                                ],
                              ));
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StepCounter(
                              histsite: widget.histsite,
                            ),
                          ));
                    }
                  },
                  label: const Text('Start Counting!'),
                  backgroundColor: Colors.teal[200],
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerFloat,
                body: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 15.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: markers.values.toSet(),
                  circles: myCircles,
                ),
              ),
            );
          } else {
            return Scaffold(
              body: Text("Loading..."),
            );
          }
        });
  }
}
