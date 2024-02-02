import 'package:flutter/material.dart';
import 'pages/mainmenu.dart';
import 'pages/login.dart';
import 'pages/register.dart';
import "package:firebase_core/firebase_core.dart";


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/mainmenu': (context) => MainMenu(),
        '/register': (context) => Register(),
      },
    );
  }
}

