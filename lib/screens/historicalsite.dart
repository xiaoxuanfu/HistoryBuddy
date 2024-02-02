import 'dart:convert';
import 'package:android_intent/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:geojson/geojson.dart';
import 'package:geolocator/geolocator.dart';
import 'package:history_buddy/sitesData.dart';
import 'package:history_buddy/HistSite.dart';
import 'package:history_buddy/screens/reviews_page.dart';
import 'package:history_buddy/screens/step_tracking.dart';

class historicalsite extends StatefulWidget {
  static List<HistSite> sortedHistSites = [];
  static List<GeoJsonPoint> points = [];
  @override
  _historicalsiteState createState() => _historicalsiteState();
}

class _historicalsiteState extends State<historicalsite> {
  @override
  // initialise list of HistSite objects to store data

  List<HistSite> HistSiteList = [];
  List<String> HistSiteImg = [];
  Future readSiteLocations() async {
    final geo = GeoJson();

    final String s = await DefaultAssetBundle.of(context)
        .loadString('assets/historic-sites-geojson.geojson');
    await geo.parse(s, verbose: true);
    final data = json.decode(s);

    String info = data["features"][0]["properties"]["Description"];
    var name_index = info.indexOf("NAME");
    var searchString = r"<";
    var stop_nameindex = info.indexOf(searchString, name_index + 13);
    String siteName = info.substring(name_index + 14, stop_nameindex);
    var start_descindex = info.indexOf("DESCRIPTION");
    var searchString1 = r"<";
    var stop_descindex = info.indexOf(searchString1, start_descindex + 20);
    String desc = info.substring(start_descindex + 21, stop_descindex);

    for (int i = 0; i < data["features"].length; i++) {
      String info = data["features"][i]["properties"]["Description"];
      var name_index = info.indexOf("NAME");
      var stop_nameindex = info.indexOf(r"<", name_index + 13);
      String siteName = info.substring(name_index + 14, stop_nameindex);
      var start_descindex = info.indexOf("DESCRIPTION");
      var stop_descindex = info.indexOf(r"<", start_descindex + 20);
      String desc = info.substring(start_descindex + 21, stop_descindex);

      HistSite histsite = HistSite(
          siteName,
          data["features"][i]["geometry"]["coordinates"][1],
          data["features"][i]["geometry"]["coordinates"][0],
          desc,
          0,
          i);
      HistSiteList.add(histsite);
    }
  }

  Future _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      try {
        final AndroidIntent intent = new AndroidIntent(
          action: 'android.settings.LOCATION_SOURCE_SETTINGS',
        );
        await intent.launch();
      } catch (e) {
        return Future.error('Location services are disabled.');
      }
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    Position position = await Geolocator.getCurrentPosition();
    return await Geolocator.getCurrentPosition();
  }

  // get user's current position
  // load data from geojson file
  // create list of historical sites
  // sort the list by distance from user's location

  Future asyncLoad() async {
    final geo = GeoJson();
    final String s = await DefaultAssetBundle.of(context)
        .loadString('assets/historic-sites-geojson.geojson');
    await geo.parse(s, verbose: true);
    final data = json.decode(s);
    Position position = await _determinePosition();
    await readSiteLocations();
    historicalsite.sortedHistSites = SitesData.filterSitesByDistance(
        HistSiteList, position.latitude, position.longitude);
    for (var i = 0; i < historicalsite.sortedHistSites.length; i++) {
      int index = historicalsite.sortedHistSites[i].getIndex();
      String info = data["features"][index]["properties"]["Description"];
      var start_imgindex = info.indexOf("PHOTOURL") + 43;
      var stop_imgindex = info.indexOf(r"<", start_imgindex);
      String img = info.substring(start_imgindex, stop_imgindex);
      String img_url = "https://roots.sg/~/media/" + img.replaceAll("\/", "/");
      HistSiteImg.add(img_url);
    }
  }

  // initialise the state of the UI
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([
          asyncLoad(), // call asyncLoad function to initialise the historical sites data
        ]),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
                backgroundColor: Colors.brown[100],
                body: NestedScrollView(
                    floatHeaderSlivers: true,
                    headerSliverBuilder:
                        (BuildContext context, bool innerBoxIsScrolled) {
                      return <Widget>[
                        SliverAppBar(
                          elevation: 0,
                          backgroundColor: Colors.brown[200],
                          title: Text("Historical Sites",
                              style: TextStyle(
                                  fontSize: 30,
                                  color: Colors.black,
                                  fontFamily: 'Pacifico')),
                          centerTitle: true,
                          expandedHeight: 60.0,
                          floating: false,
                          pinned: true,
                          automaticallyImplyLeading: false,
                        ),
                      ];
                    },
                    body: ListView.builder(
                        itemCount: historicalsite.sortedHistSites.length,
                        itemBuilder: (BuildContext context, int index) {
                          return ListTile(
                            leading: FadeInImage(
                              image: NetworkImage(HistSiteImg[index]),
                              placeholder: AssetImage('images/Logo.png'),
                              width: 100,
                              imageErrorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'images/Logo.png',
                                  width: 100,
                                );
                              },
                            ),
                            title: Text(historicalsite.sortedHistSites[index]
                                .getName()),
                            subtitle: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Flexible(
                                  child: Text(historicalsite
                                      .sortedHistSites[index]
                                      .getDesc()),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    FlatButton(
                                      child: const Text(
                                        'REVIEWS',
                                        style: TextStyle(
                                            color: Colors.purple,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => ReviewsPage(
                                                histsite: historicalsite
                                                    .sortedHistSites[index]),
                                          ),
                                        );
                                      },
                                    ),
                                    FlatButton(
                                      child: const Text(
                                        'TRACK STEPS',
                                        style: TextStyle(
                                            color: Colors.purple,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => StepTracking(
                                                histsite: historicalsite
                                                    .sortedHistSites[index]),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        })));
          } else {
            return Scaffold(
              body: Text("Loading..."),
            );
          }
        });
  }
}
