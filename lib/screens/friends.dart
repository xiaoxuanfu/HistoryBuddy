import 'package:flutter/material.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:flutter/services.dart';
import '../constants.dart';
import '../pages/mainmenu.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

final _firestore = FirebaseFirestore.instance;

class friendsPage extends StatefulWidget {
  @override
  _friendsPageState createState() => _friendsPageState();
}

class _friendsPageState extends State<friendsPage> {
  //Retrieve information from public class MainMenuState
  String email = MainMenuState.loggedInUser.email.toString();
  String username = MainMenuState.username.toString();

  // Belongs to current user
  List<String> friendList = [];
  List<String> requestList = [];

  // For adding friend functionality
  late String friendUsername;
  late String friendEmail;

  // Get real name of requesting friend and current friends to be displayed below username
  var friendNameList = {};
  var requestNameList = {};

  var txtController = TextEditingController(); // For clearing text field

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
    this.friendList = friendList;
    setState(() {});
  }

  Future<void> getRequestList() async {
    List<String> requestList = [];
    await _firestore
        .collection('userinfo')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        if (email == doc.id.toLowerCase()) {
          for (String friendUsername in doc["requests"]) {
            requestList.add(friendUsername);
          }
        }
      });
    });
    this.requestList = requestList;
    setState(() {});
  }

  // Get real name of requesting friend and current friends to be displayed below username
  Future<void> getFriendNameList() async {
    var friendNameList = Map();
    var requestNameList = Map();
    await _firestore
        .collection('userinfo')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        for (String friendUsername in friendList) {
          if (friendUsername == doc["username"]) {
            friendNameList[friendUsername] = doc["name"];
          }
        }
        for (String friendUsername in requestList) {
          if (friendUsername == doc["username"]) {
            requestNameList[friendUsername] = doc["name"];
          }
        }
      });
    });
    this.friendNameList = friendNameList;
    this.requestNameList = requestNameList;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    //Cannot add function calls/setState to widgets, though can add in an onPressed async button (similar to refresh) but require user interaction (not ideal).
    //FutureBuilder allows to await the getFriendList function where the attribute friendList is updated according to data fetched from the database collection
    //This is done before building widgets, so widgets can now make use of the updated attribute friendList.
    return FutureBuilder(
        future: Future.wait([
          getFriendList(),
          getRequestList(),
          getFriendNameList(),
        ]), //multiple futures to wait for
        builder: (context, snapshot) {
          return Scaffold(
            resizeToAvoidBottomInset:
                false, //also include this in home.dart because bottom navigation bar will cause pixel overflow
            backgroundColor: Colors.white70,
            body: Center(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15.0, horizontal: 24.0),
                    child: TextField(
                      controller: txtController,
                      maxLength: 30,
                      keyboardType: TextInputType.visiblePassword,
                      inputFormatters: [
                        new FilteringTextInputFormatter(RegExp("[a-zA-Z0-9._]"),
                            allow: true),
                      ],
                      onChanged: (value) {
                        friendUsername = value;
                      },
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () async {
                            // Cannot add yourself as friend
                            try {
                              if (friendUsername == username) {
                                Alert(
                                        context: context,
                                        title: "Error",
                                        desc: "Cannot add yourself")
                                    .show();
                                return;
                                //Check if request to be sent is already your friend
                              } else if (friendList.contains(friendUsername)) {
                                Alert(
                                        context: context,
                                        title: "Error",
                                        desc:
                                            "User is already in your friendlist")
                                    .show();
                                return;
                              }

                              bool validFriendUsername = false;
                              await _firestore //check username to add exists in database
                                  .collection('userinfo')
                                  .get()
                                  .then((QuerySnapshot querySnapshot) {
                                querySnapshot.docs.forEach((doc) {
                                  if (friendUsername == doc["username"]) {
                                    validFriendUsername = true;
                                    friendEmail = doc.id;
                                    requestList.add(username);
                                    //Change requestList field for friend, do nothing for existing user unless "pending request" is implemented
                                    _firestore
                                        .collection('userinfo')
                                        .doc(friendEmail)
                                        .update({
                                      "requests":
                                          FieldValue.arrayUnion(requestList)
                                    }); //union set, no duplicates, no same username anyways
                                    Alert(
                                            context: context,
                                            title: "Success",
                                            desc:
                                                "Friend request sent to '$friendUsername'")
                                        .show();
                                  }
                                });
                              });
                              if (!validFriendUsername) {
                                Alert(
                                        context: context,
                                        title: "Error",
                                        desc: "Username does not exist")
                                    .show();
                              }
                            } catch (e) {
                              errorAlert(e, context);
                            } finally {
                              txtController.clear();
                              friendUsername = "";
                              setState(
                                  () {}); //refresh state and show added-new-user immediately on widget
                            }
                          },
                        ),
                        hintText: "Add friend by username",
                        hintStyle:
                            TextStyle(fontSize: 15.0, color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 20.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(32.0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.lightBlueAccent, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(32.0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.lightBlueAccent, width: 2.0),
                          borderRadius: BorderRadius.all(Radius.circular(32.0)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 12.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                    child: Row(
                      children: [
                        Text(
                          'Requests: ',
                          style: kHeadingTextStyle,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 75, //show 1 request per view, scrollable
                    child: ListView(
                      shrinkWrap: true, //only occupies the space it needs
                      children: [
                        for (var friend in requestList)
                          ListTile(
                            onTap: () async {
                              Alert(
                                context: context,
                                title: "Friend Request",
                                desc: "$friend has requested to be friends",
                                buttons: [
                                  DialogButton(
                                    child: Text(
                                      "Accept",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 20),
                                    ),
                                    onPressed: () async {
                                      //update my request
                                      List<String> newRequest = [];
                                      newRequest.add(friend);
                                      _firestore
                                          .collection('userinfo')
                                          .doc(email)
                                          .update({
                                        "requests":
                                            FieldValue.arrayRemove(newRequest)
                                      });
                                      getRequestList();
                                      //update my friends
                                      List<String> newFriend = [];
                                      newFriend.add(friend);
                                      _firestore
                                          .collection('userinfo')
                                          .doc(email)
                                          .update({
                                        "friends":
                                            FieldValue.arrayUnion(newFriend)
                                      });
                                      getFriendList();
                                      setState(() {});
                                      //update his friends
                                      await _firestore
                                          .collection('userinfo')
                                          .get()
                                          .then((QuerySnapshot querySnapshot) {
                                        querySnapshot.docs.forEach((doc) {
                                          if (friend == doc["username"]) {
                                            String newFriendEmail = doc.id;
                                            List<String> newFriend = [];
                                            newFriend.add(username);
                                            _firestore
                                                .collection('userinfo')
                                                .doc(newFriendEmail)
                                                .update({
                                              "friends": FieldValue.arrayUnion(
                                                  newFriend)
                                            });
                                          }
                                        });
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                  DialogButton(
                                    child: Text(
                                      "Reject",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 20),
                                    ),
                                    onPressed: () {
                                      //remove my request
                                      for (String request in requestList) {
                                        //update my request
                                        List<String> newRequest = [];
                                        newRequest.add(request);
                                        _firestore
                                            .collection('userinfo')
                                            .doc(email)
                                            .update({
                                          "requests":
                                              FieldValue.arrayRemove(newRequest)
                                        });
                                        getRequestList();
                                        setState(() {});
                                      }
                                      Navigator.pop(context);
                                    },
                                  )
                                ],
                              ).show();
                            },
                            leading: CircleAvatar(
                              child: Text(friend
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase()),
                            ),
                            title: Text(friend),
                            //ternary operator introduced because widget may attempt creation before requestNameList is updated (may be null) -> Forced a setstate for all get functions but implemented just in case
                            subtitle: requestNameList[friend] != null
                                //Real name displayed here
                                ? Text(requestNameList[friend])
                                : Text(""),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 24.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Row(
                      children: [
                        Text(
                          'Friends: ${friendList.length}', // Display total number of friends
                          style: kHeadingTextStyle,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    //show around 4 friend per view, scrollable
                    child: ListView(
                      shrinkWrap: true, //only occupies the space it needs
                      children: [
                        for (var friend in friendList)
                          ListTile(
                            onTap: () async {
                              Alert(
                                context: context,
                                title: "Remove Friend",
                                desc: "Remove $friend from friend list?",
                                buttons: [
                                  DialogButton(
                                    child: Text(
                                      "Yes",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 20),
                                    ),
                                    onPressed: () async {
                                      //update my friends
                                      List<String> removeFriend = [];
                                      removeFriend.add(friend);
                                      _firestore
                                          .collection('userinfo')
                                          .doc(email)
                                          .update({
                                        "friends":
                                            FieldValue.arrayRemove(removeFriend)
                                      });
                                      getFriendList();
                                      setState(() {});
                                      //update his friends
                                      await _firestore
                                          .collection('userinfo')
                                          .get()
                                          .then((QuerySnapshot querySnapshot) {
                                        querySnapshot.docs.forEach((doc) {
                                          if (friend == doc["username"]) {
                                            String removeFriendEmail = doc.id;
                                            List<String> removeFriend = [];
                                            removeFriend.add(username);
                                            _firestore
                                                .collection('userinfo')
                                                .doc(removeFriendEmail)
                                                .update({
                                              "friends": FieldValue.arrayRemove(
                                                  removeFriend)
                                            });
                                          }
                                        });
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                  DialogButton(
                                    child: Text(
                                      "No",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 20),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ).show();
                            },
                            leading: CircleAvatar(
                              child: Text(friend
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase()),
                            ),
                            title: Text(friend),
                            //ternary operator introduced because widget may attempt creation before friendNameList is updated (may be null) -> Forced a setstate for all get functions but implemented just in case
                            subtitle: friendNameList[friend] != null
                                //Real name displayed here
                                ? Text(friendNameList[friend])
                                : Text(""),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
