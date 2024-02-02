import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'HistSite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geojson/geojson.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

// parse data
class SitesData {

//  List<LatLng> polylineCoordinates = [];
  // PolylinePoints polylinePoints = PolylinePoints();

  // constructor
  SitesData();

  static List<HistSite> filterSitesByDistance(
      List<HistSite> HistSiteList,
      double userLatitude,
      double userLongitude)
  {
    List<HistSite> sortedHistSite = [];

    for (HistSite histsite in HistSiteList){
      double distanceFromUser = getDistance(histsite.getCoordinates()[0], histsite.getCoordinates()[1], userLatitude, userLongitude);
      histsite.setDist(distanceFromUser);

      sortedHistSite.add(histsite);
    }

    sortedHistSite.sort((a,b) => a.getDist().compareTo(b.getDist()));
    return sortedHistSite;
  }

  static double getDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

}
