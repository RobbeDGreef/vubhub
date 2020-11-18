import 'dart:io';

import 'package:flutter/material.dart';

class SelectionView extends StatelessWidget {
  String title;
  List<String> selection;
  String selected;
  Function(String) onChosen;

  SelectionView({this.title, this.selection, this.selected, this.onChosen});

  @override
  Widget build(BuildContext context) {
    List<Widget> tiles = List();

    String subtitle = selected;

    /*
    if (!Platform.isAndroid) {
      if (subtitle != null && subtitle.length > 20) {
        subtitle = subtitle.substring(0, 20) + "...";
      }
    }
    */

    for (String select in selection) {
      print("$select $selected");
      callCallback() {
        Navigator.pop(context);
        onChosen(select);
      }

      tiles.add(ListTile(
        title: Text(select),
        trailing: Radio(
          toggleable: false,
          onChanged: (bool) => callCallback(),
          value: select,
          groupValue: selected,
        ),
        onTap: callCallback,
      ));
      tiles.add(Divider());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          this.title,
          style: TextStyle(color: Theme.of(context).accentColor),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).accentColor),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(children: tiles),
    );
  }
}
