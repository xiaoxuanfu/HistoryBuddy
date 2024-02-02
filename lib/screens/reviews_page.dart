import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:history_buddy/screens/historicalsite.dart';
import 'package:history_buddy/HistSite.dart';
import 'package:history_buddy/screens/review_form.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({required this.histsite});

  final HistSite histsite;

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(histsite.getName()),
        backgroundColor: Colors.teal[200],
        elevation: 0.0,
      ),
      body: _body(context),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReviewForm(histsite: histsite),
              ));
        },
        backgroundColor: Colors.teal[200],
      ),
    );
  }

  Widget _body(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('hist_site', isEqualTo: histsite.getName())
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading");
        }

        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data =
                document.data()! as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                child: Text(data['reviewer'].substring(0, 1).toUpperCase()),
              ),
              title: Text(data['reviewer']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _reviewsStarWidget(data['rating']),
                  Text(data['comment']),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _reviewsStarWidget(int rating) {
    var stars = <Widget>[];
    for (int i = 0; i < 5; i++) {
      Icon star = i < rating
          ? Icon(Icons.star, color: Colors.orangeAccent, size: 12)
          : Icon(Icons.star_border, color: Colors.orangeAccent, size: 12);
      stars.add(star);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: stars,
    );
  }
}
