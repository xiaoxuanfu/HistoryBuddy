import 'package:flutter/material.dart';
import '../constants.dart';
import "package:firebase_auth/firebase_auth.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:rflutter_alert/rflutter_alert.dart';
import '../screens/home.dart';
import '../screens/friends.dart';
import '../screens/leaderboard.dart';
import '../screens/historicalsite.dart';

final _firestore = FirebaseFirestore.instance;

class MainMenu extends StatefulWidget {
  @override
  MainMenuState createState() => MainMenuState();
}

class MainMenuState extends State<MainMenu> {
  final _auth = FirebaseAuth.instance;
  static late User loggedInUser;
  static String username = "";
  int calories = 100;

  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static List<Widget> _widgetOptions = <Widget>[
    homePage(),
    friendsPage(),
    leaderboardPage(),
    historicalsite()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  Future<String> getInfo() async {
    await _firestore
        .collection('userinfo')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        //this is not expensive
        if (loggedInUser.email == doc.id.toLowerCase()) {
          username = doc["username"];
        }
      });
    });
    return username;
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      errorAlert(e, context); //see constants.dart
    }
  }

  @override
  Widget build(BuildContext context) {
    //future builder is used to modify appBar title after info is being gathered from database (detailed explanation can be found in friends.dart)
    return FutureBuilder<String>(
        future: getInfo(),
        builder: (context, snapshot) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.brown[600],
            appBar: AppBar(
              automaticallyImplyLeading:
                  false, //prevents accidental backtracking
              backgroundColor: Colors.blue[900],
              title: Text("Welcome $username !"),
              actions: [
                TextButton(
                  child: Text("Logout",
                      style: TextStyle(
                          color: Colors.white54,
                          backgroundColor: Colors.blue[900])),
                  onPressed: () {
                    Alert(
                      context: context,
                      title: "Confirmation",
                      desc: "Are you sure you want to logout?",
                      buttons: [
                        DialogButton(
                          child: Text(
                            "Yes",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          onPressed: () {
                            _auth.signOut();
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                        ),
                        DialogButton(
                          child: Text(
                            "No",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ).show();
                  },
                )
              ],
            ),
            body: Center(
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home, color: Colors.black),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group, color: Colors.black),
                  label: 'Friends',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.leaderboard, color: Colors.black),
                  label: 'Leaderboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.hiking, color: Colors.black),
                  label: 'Historical Sites',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.amber[800],
              onTap: _onItemTapped,
            ),
          );
        });
  }
}
