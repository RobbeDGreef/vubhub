import 'dart:convert';
import 'dart:io';

import "package:flutter/material.dart";
import "package:calendar_strip/calendar_strip.dart";
import 'package:flutter/services.dart';
import "package:intl/intl.dart";
import "package:flushbar/flushbar.dart";

import "parser.dart";
import "infohandler.dart";
import "settings.dart";
import "const.dart";

import "package:http/http.dart" as http;
import "package:html/parser.dart" as html;

void main() => runApp(Vub());

/// The main app
class Vub extends StatelessWidget {
  final theme = ThemeData(primaryColor: Color.fromARGB(0xFF, 0, 52, 154));
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: "VUB class schedules", home: MainUi());
  }
}

/// Statefull widget used to store all immutable data
/// so that we can change state using the State widget
class MainUi extends StatefulWidget {
  InfoHandler infoHandler;

  MainUi() {
    infoHandler = InfoHandler();
  }

  @override
  ClassesToday createState() {
    return ClassesToday(this.infoHandler);
  }
}

/// The state object, this object will be regenerated and
/// the data is thus mutable.
class ClassesToday extends State<MainUi> {
  InfoHandler info;
  List<Lecture> classes = new List();
  DateTime selectedDay = DateTime.now();
  int todaysColor = 0;
  int _selectedNavBarIndex = 0;

  ClassesToday(InfoHandler info) {
    this.info = info;
    this.info.getClassesOfDay(DateTime.now()).then((list) => update(list));
  }

  void update(List<Lecture> classes) {
    print("Updating");
    setState(() {
      bool rotset = false;
      this.classes.clear();
      for (Lecture lec in classes) {
        // If the rotationsystem is already specified don't add it again
        if (lec.name.toLowerCase().contains("rotatie")) {
          if (rotset) continue;
          rotset = true;
        }

        int i = 0;
        for (Lecture prevLec in this.classes) {
          if (lec.start.compareTo(prevLec.start) < 0) {
            this.classes.insert(i, lec);
            break;
          }
          ++i;
        }
        if (this.classes.length == i) {
          this.classes.add(lec);
        }
      }
    });
  }

  Widget _buildWeekScroller() {
    return CalendarStrip(onDateSelected: ((date) {
      this.selectedDay = date;
      this.info.getClassesOfDay(date).then((list) => update(list));
    }));
  }

  /// Prettify the minutes string to use double digit notation
  String _minutes(int x) {
    String s = x.toString();
    if (s.length == 1) {
      s = ['0', s].join("");
    }
    return s;
  }

  List<Color> _colorFromRotString(String rotsystem) {
    rotsystem = rotsystem.toLowerCase();
    if (rotsystem.contains("blauw")) {
      return [VubBlue, Colors.white];
    } else if (rotsystem.contains("oranje")) {
      return [VubOrange, Colors.white];
    }

    return [null, null];
  }

  Widget _buildLectureDetailTile(String text, Icon icon) {
    return Card(
        child: ListTile(
      title: Text(text),
      leading: icon,
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: text));
        Flushbar(message: "Copied text to clipboard", duration: Duration(seconds: 2)).show(context);
      },
    ));
  }

  Widget _buildLectureDetails(int index) {
    Lecture lec = this.classes[index];
    return Scaffold(
        appBar: AppBar(title: Text("Details")),
        body: ListView(children: [
          Padding(
              padding: EdgeInsets.only(left: 4, right: 4, bottom: 16, top: 16),
              child: Text(lec.name, style: TextStyle(fontSize: 20))),
          _buildLectureDetailTile(lec.professor, Icon(Icons.person_outline)),
          _buildLectureDetailTile(lec.details, Icon(Icons.dehaze)),
          _buildLectureDetailTile(lec.location, Icon(Icons.location_on)),
          _buildLectureDetailTile(lec.remarks, Icon(Icons.event_note_outlined)),
          _buildLectureDetailTile(
              DateFormat("EEEE d MMMM").format(lec.start) +
                  " from " +
                  DateFormat("H:mm").format(lec.start) +
                  " until " +
                  DateFormat("H:mm").format(lec.end),
              Icon(Icons.access_time)),
        ]));
  }

  void openLectureDetails(int index) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) => _buildLectureDetails(index)));
  }

  /// Creates a class or lecture tab for the
  Widget _createClassItem(BuildContext context, int i) {
    var icon = Icons.record_voice_over_outlined;
    if (this.classes[i].name.toLowerCase().contains("wpo")) icon = Icons.subject;

    var colors = _colorFromRotString(this.classes[i].name);

    if (this.classes[i].name.toLowerCase().contains("<font color=")) {
      return Card(
          child: ListTile(
              title: Text(
                  "Rotatiesysteem: rotatie " +
                      (this.classes[i].name.contains("BLAUW") ? "blauw" : "oranje"),
                  style: TextStyle(color: colors[1]))),
          color: colors[0]);
    }

    String policyString = this.classes[i].remarks;
    if (this.classes[i].remarks.toLowerCase().contains("rotatiesysteem"))
      policyString = "Rotatiesysteem: " +
          ((this.info.isUserAllowed(this.todaysColor))
              ? "you are allowed to come"
              : "you are not allowed to come");

    return Card(
        child: ListTile(
            leading: Icon(icon),
            title: Text(this.classes[i].name),
            isThreeLine: false,
            onTap: () => openLectureDetails(i),
            subtitle: Padding(
                padding: EdgeInsets.all(0),
                child: Column(children: [
                  Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(
                            child: Text(this.classes[i].location, overflow: TextOverflow.ellipsis)),
                        Text(this.classes[i].start.hour.toString() +
                            ":" +
                            _minutes(this.classes[i].end.minute) +
                            " - " +
                            this.classes[i].end.hour.toString() +
                            ":" +
                            _minutes(this.classes[i].end.minute))
                      ], mainAxisAlignment: MainAxisAlignment.spaceBetween)),
                  Row(children: [
                    Expanded(child: Text(policyString, overflow: TextOverflow.ellipsis))
                  ], mainAxisAlignment: MainAxisAlignment.start)
                ]))));
  }

  /// Builds the lesson tray (the main screen actually)
  Widget _buildMainScreen() {
    var list = ListView.builder(itemBuilder: _createClassItem, itemCount: this.classes.length);
    return Column(children: [_buildWeekScroller(), Expanded(child: list)]);
  }

  void openSettings() async {
    var groups = List<String>();
    groups.addAll(this.info.getSelectedUserGroups());

    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) => SettingsMenu(this.info)));

    if (this.info.getSelectedUserGroups() != groups) {
      this.info.getClassesOfDay(this.selectedDay).then((value) => update(value));
    }
  }

  void openAbout() {
    print("About");
  }

  Widget _buildDrawer() {
    return Drawer(
        child: ListView(
      children: [
        DrawerHeader(child: Text("Header"), decoration: BoxDecoration(color: Colors.blue)),
        ListTile(title: Text("Settings"), onTap: openSettings),
        ListTile(title: Text("About"), onTap: openAbout)
      ],
    ));
  }

  Widget createScreen(int index) {
    print("ind: $index");
    switch (index) {
      case 0:
        return _buildMainScreen();

      case 1:
        return Text("map");

      case 2:
        return Text("places");

      case 3:
        return Text("help");

      default:
        return Text("Something went wrong");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = BottomNavigationBar(
      currentIndex: this._selectedNavBarIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: (i) {
        setState(() {
          this._selectedNavBarIndex = i;
        });
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.view_agenda),
          label: "classes",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: "map",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.meeting_room),
          label: "places",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.help_center),
          label: "help",
        ),
      ],
    );

    return Scaffold(
        drawer: _buildDrawer(),
        bottomNavigationBar: bottom,
        appBar: AppBar(
          title: Text("Today's classes"),
          actions: [
            IconButton(
                icon: Icon(Icons.replay_sharp),
                onPressed: () =>
                    this.info.forceCacheUpdate(this.info.calcWeekFromDate(this.selectedDay)))
          ],
        ),
        body: createScreen(this._selectedNavBarIndex));
  }
}
