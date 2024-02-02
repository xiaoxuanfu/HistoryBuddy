import 'package:flutter/material.dart';
import "package:rflutter_alert/rflutter_alert.dart";

InputDecoration buildInputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(fontSize: 15.0, color: Colors.grey),
    contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(32.0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.lightBlueAccent, width: 1.0),
      borderRadius: BorderRadius.all(Radius.circular(32.0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
      borderRadius: BorderRadius.all(Radius.circular(32.0)),
    ),
  );
}

InputDecoration registerInputDecoration(String labelText) {
  return InputDecoration(
    labelText: labelText,
    hintStyle: TextStyle(fontSize: 15.0, color: Colors.grey),
    contentPadding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(32.0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.lightBlueAccent, width: 1.0),
      borderRadius: BorderRadius.all(Radius.circular(32.0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
      borderRadius: BorderRadius.all(Radius.circular(32.0)),
    ),
  );
}

const kHeadingTextStyle = TextStyle(
  fontSize: 18.0,
  color: Colors.black,
  fontFamily: 'SourceSansPro',
  fontWeight: FontWeight.bold,
);

void errorAlert(e, context) {
  String error_type = "Unknown Error";
  String error_msg = "Unhandled Exception";
  String error = e.toString();
  int start = 0;
  int index = error.indexOf(":");
  if (index == -1) {
    index = error.indexOf("]");
    start = error.indexOf("/") + 1;
  }

  error_type = error.substring(start, index);
  error_msg = error.substring(index + 1);

  // Custom error messages
  // Empty Username or password
  if (error_type == "LateInitializationError" ||
      error_msg == " Given String is empty or null") {
    error_type = "Login details cannot be empty";
    error_msg = "Please try again";
  }

  // Invalid email or username
  if (error_type == "invalid-email" || error_type == "user-not-found") {
    error_type = "Invalid email or username";
    error_msg = "Please try again";
  }

  Alert(context: context, title: error_type, desc: error_msg).show();
}
