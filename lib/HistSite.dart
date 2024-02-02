class HistSite {
  late String _siteName, _description;
  double _lat = -1, _lng = -1;
  double _distfromuser = 0;
  int _index =0;
  //class constructor
  HistSite(String siteName, double lat, double lng, String description, double distancefromuser, int index) {
    _siteName = siteName;
    _lat = lat;
    _lng = lng;
    _description = description;
    _distfromuser = distancefromuser;
    _index = index;
  }
 // HistSite(){
//    this._siteName;
//    this._lat;
  //  this._lng;
  //  this._description;
   // this._distfromuser;
  //}

  String getName() {
    return _siteName;
  }

  String getDesc() {
    return _description;
  }
  void setDist(double d){
    this._distfromuser = d;
  }
  double getDist(){
    return this._distfromuser;
  }
  void setIndex(int i){
    this._index = i;
  }
  int getIndex(){
    return this._index;
  }
  List<double> getCoordinates() {
    return [_lat, _lng];
  }

  String toString(){
    return '{ ${this._siteName}, ${this._distfromuser}';
  }

  // compare distance of historical sites from user's current location
  int compareTo(other) {
    if (this._distfromuser < other.distancefromuser){
      return 1;
    }
    if (this._distfromuser > other.distancefromuser){
      return -1;
    }
    if (this._distfromuser == other.distancefromuser){
      return 0;
    }
    return 0;
  }
}