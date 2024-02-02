import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../pages/mainmenu.dart';

final _firestore = FirebaseFirestore.instance;

class homePage extends StatefulWidget {
  @override
  _homePageState createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  int steps = 0;
  var calories;

  final _auth = FirebaseAuth.instance;
  static late User loggedInUser;
  late String email;

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        email = loggedInUser.email.toString();
      }
    } catch (e) {
      errorAlert(e, context); //see constants.dart
    }
  }

  Future getInfo() async {
    getCurrentUser();
    await _firestore
        .collection('userinfo')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        //this is not expensive
        if (email == doc.id.toLowerCase()) {
          steps = doc["steps"];
          calories = doc["calories"];
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([
          getInfo(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              backgroundColor: Colors.white70,
              body: Center(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: CircleAvatar(
                        radius: 50,
                        child: Text(
                          MainMenuState.username
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(fontSize: 50),
                        ),
                      ),
                    ),
                    Text(
                      MainMenuState.loggedInUser.email.toString(),
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(
                      height: 8.0,
                    ),
                    Divider(
                      color: Colors.black,
                      height: 15,
                      thickness: 2,
                      indent: 5,
                      endIndent: 5,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.local_fire_department,
                                size: 50,
                              ),
                              Text(
                                'Calories: ${double.parse(calories.toString()).toStringAsFixed(2)}',
                                style: kHeadingTextStyle,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.nordic_walking,
                                size: 50,
                              ),
                              Text(
                                'Steps: $steps',
                                style: kHeadingTextStyle,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 60,
                    ),
                    SizedBox(
                      width: 350.0,
                      child: DefaultTextStyle(
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 35.0,
                          fontFamily: 'DancingScript',
                        ),
                        child: AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                                "'Not all those who wander are lost' ~ J.R.R. Tolkien"),
                            TypewriterAnimatedText(
                                "'The world is a book and those who do not travel read only one page.' ~ Saint Augustine"),
                            TypewriterAnimatedText(
                                "'Life is either a daring adventure or nothing at all' ~ Helen Keller"),
                            TypewriterAnimatedText(
                                "Take only memories, leave only footprints' ~ Chief Seattle"),
                          ],
                        ),
                      ),
                    ),
                  ],
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
