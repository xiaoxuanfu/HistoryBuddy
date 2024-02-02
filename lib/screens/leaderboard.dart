import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:history_buddy/pages/mainmenu.dart';

final _firestore = FirebaseFirestore.instance;

class leaderboardPage extends StatefulWidget {
  @override
  _leaderboardPageState createState() => _leaderboardPageState();
}

class _leaderboardPageState extends State<leaderboardPage> {
  List usernameList = [];
  List friendList = [];
  var dataMap = {};
  var dataFilter = 'steps';
  var viewFilter = 'global';
  String email = MainMenuState.loggedInUser.email.toString();
  String username = MainMenuState.username.toString();

  Future<void> getFriendList() async {
    List<String> friendList = [];
    await _firestore
        .collection('userinfo')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        if (email == doc.id.toLowerCase()) {
          for (String friendUsername in doc["friends"]) {
            friendList.add(friendUsername);
          }
        }
      });
    });
    friendList.add(username); //add self
    this.friendList = friendList;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('userinfo')
            .orderBy(dataFilter, descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.lightBlueAccent,
              ),
            );
          }
          final data = snapshot.data!.docs;
          var dataMap = Map();

          if (viewFilter == 'friends') {
            getFriendList();
            List usernameList = [];
            for (var document in data) {
              try {
                if (friendList.contains(document.get('username'))) {
                  dataMap[document.get('username')] = document.get(dataFilter);
                  usernameList.add(document.get('username'));
                }
              } catch (e) {
                print(e);
              }
            }
            this.usernameList = usernameList;
          } else {
            List usernameList = [];
            for (var document in data) {
              try {
                dataMap[document.get('username')] = document.get(dataFilter);
                usernameList.add(document.get('username'));
              } catch (e) {
                print(e);
              }
            }
            this.usernameList = usernameList;
          }

          return Scaffold(
            backgroundColor: Colors.brown[100],
            body: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView(
                children: <Widget>[
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            DropdownButton<String>(
                              value: viewFilter,
                              style: const TextStyle(
                                  fontSize: 16.0, color: Colors.deepPurple),
                              underline: Container(
                                height: 2,
                                color: Colors.deepPurpleAccent,
                              ),
                              onChanged: (String? newValue) async {
                                setState(() {
                                  viewFilter = newValue!;
                                });
                              },
                              items: <String>[
                                'global',
                                'friends'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                            Text(
                              "Leaderboard",
                              style: TextStyle(
                                fontSize: 30.0,
                                fontFamily: 'Pacifico',
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(
                              width: 35.0,
                            ),
                            DropdownButton<String>(
                              value: dataFilter,
                              icon: const Icon(Icons.arrow_downward),
                              elevation: 16,
                              style: const TextStyle(
                                  fontSize: 16.0, color: Colors.deepPurple),
                              underline: Container(
                                height: 2,
                                color: Colors.deepPurpleAccent,
                              ),
                              onChanged: (String? newValue) {
                                setState(() {
                                  dataFilter = newValue!;
                                });
                              },
                              items: <String>[
                                'steps',
                                'calories'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        color: Colors.black,
                        height: 15,
                        thickness: 2,
                        indent: 5,
                        endIndent: 5,
                      ),
                      Container(
                          height: 450,
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              for (var index in usernameList)
                                ListTile(
                                  leading: CircleAvatar(
                                    child: Text(index
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase()),
                                  ),
                                  title: Text(index.toString(),
                                      style: index.toString() == username
                                          ? TextStyle(
                                              fontWeight: FontWeight.bold)
                                          : TextStyle()),
                                  trailing: Text(
                                    dataFilter == 'calories'
                                        ? double.parse(
                                                dataMap[index].toString())
                                            .toStringAsFixed(2)
                                        : dataMap[index].toString(),
                                    style: index.toString() == username
                                        ? TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold)
                                        : TextStyle(fontSize: 18.0),
                                  ),
                                ),
                            ],
                          )),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }
}
