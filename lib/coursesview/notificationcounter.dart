import 'package:flutter/material.dart';

class NotificationCounter extends StatelessWidget {
  Color color;
  int amount;

  NotificationCounter(Color color, int amount) {
    this.color = color;
    this.amount = amount;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),

      // The text here is pre and post-fixed with spaces to make it take up
      // more space and create a properly sized card.
      child: Text(
        " " + amount.toString() + " ",
        style: TextStyle(fontSize: 14, color: Colors.white),
      ),
    );
  }
}
