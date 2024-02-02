import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:history_buddy/HistSite.dart';
import '../pages/mainmenu.dart';

final _firestore = FirebaseFirestore.instance;

String formatDate(DateTime d) {
  return d.toString().substring(0, 19);
}

class StepCounter extends StatefulWidget {
  StepCounter({required this.histsite});
  final HistSite histsite;
  @override
  _StepCounterState createState() => _StepCounterState();
}

class _StepCounterState extends State<StepCounter> {
  String email = MainMenuState.loggedInUser.email.toString();
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  late StreamSubscription _stepCountStreamSubscription;
  late StreamSubscription _pedestrianStatusStreamSubscription;
  String _status = '?', _steps = '?';
  int stepsData = 0;
  late int stepsRecord;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future getSteps() async {
    await FirebaseFirestore.instance
        .collection('userinfo')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        //this is not expensive
        if (email == doc.id.toLowerCase()) {
          stepsRecord = doc["steps"];
        }
      });
    });
  }

  void onStepCount(StepCount event) async {
    await getSteps();
    if (stepsRecord != null) {
      setState(() {
        _steps = (int.parse(event.steps.toString()) - stepsRecord).toString();
        stepsData = int.parse(_steps);
      });
    }
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    setState(() {
      _status = 'Pedestrian Status not available';
    });
    print(_status);
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      _steps = 'Step Count not available';
    });
  }

  void initPlatformState() {
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStreamSubscription = _pedestrianStatusStream.listen(
        onPedestrianStatusChanged,
        onError: onPedestrianStatusError,
        cancelOnError: true);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStreamSubscription = _stepCountStream.listen(
      onStepCount,
      onError: onStepCountError,
      cancelOnError: true,
    );

    if (!mounted) return;
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text('Confirm?'),
            content: new Text('Confirm to stop steps tracking?'),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  _stepCountStreamSubscription.cancel();
                  _pedestrianStatusStreamSubscription.cancel();
                  _firestore
                      .collection('userinfo')
                      .doc(email)
                      .update({'steps': FieldValue.increment(stepsData)});
                  _firestore.collection('userinfo').doc(email).update(
                      {'calories': FieldValue.increment(stepsData * 0.44)});
                  _stepCountStreamSubscription.cancel();
                  _pedestrianStatusStreamSubscription.cancel();
                },
                child: new Text('Yes'),
              ),
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: new Text('No'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([getSteps()]),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return WillPopScope(
              onWillPop: _onWillPop,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                home: Scaffold(
                  appBar: AppBar(
                    automaticallyImplyLeading: false,
                    title: const Text('Pedometer'),
                    backgroundColor: Colors.teal[200],
                  ),
                  floatingActionButton: FloatingActionButton.extended(
                    onPressed: () {
                      _firestore
                          .collection('userinfo')
                          .doc(email)
                          .update({'steps': FieldValue.increment(stepsData)});
                      _firestore.collection('userinfo').doc(email).update(
                          {'calories': FieldValue.increment(stepsData * 0.44)});
                      _stepCountStreamSubscription.cancel();
                      _pedestrianStatusStreamSubscription.cancel();

                      Navigator.pop(context);
                    },
                    label: const Text('Stop Counting'),
                    backgroundColor: Colors.teal[200],
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Steps taken:',
                          style: TextStyle(fontSize: 30),
                        ),
                        Text(
                          stepsData.toString(),
                          style: TextStyle(fontSize: 60),
                        ),
                        Divider(
                          height: 100,
                          thickness: 0,
                          color: Colors.white,
                        ),
                        Text(
                          'Pedestrian status:',
                          style: TextStyle(fontSize: 30),
                        ),
                        Icon(
                          _status == 'walking'
                              ? Icons.directions_walk
                              : _status == 'stopped'
                                  ? Icons.accessibility_new
                                  : Icons.error,
                          size: 100,
                        ),
                        Center(
                          child: Text(
                            _status,
                            style: _status == 'walking' || _status == 'stopped'
                                ? TextStyle(fontSize: 30)
                                : TextStyle(fontSize: 20, color: Colors.red),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else {
            return Scaffold(
              body: Center(
                child: Text(
                  "Loading...",
                ),
              ),
            );
          }
        });
  }
}
