import "package:flutter/material.dart";
import "package:calendar_strip/calendar_strip.dart";

import "parser.dart";
import "classinfo.dart";
import "settings.dart";

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
  // @todo: The test string here only works for group 3 (non-choice) so yeah, we need to create settings and stuff.
  final teststring =
      "http://splus.cumulus.vub.ac.be/sws/v3/evenjr/NL/XML/default.aspx?ical_set&p1=EF29CC48C18E1A2B440A71EC42FE89AE";

  ClassInfo info;

  MainUi() {
    info = ClassInfo(teststring);
  }

  @override
  ClassesToday createState() {
    var state = ClassesToday(this.info);
    info.setCallback(state.update);
    return state;
  }
}

/// The state object, this object will be regenerated and
/// the data is thus mutable.
class ClassesToday extends State<MainUi> {
  ClassInfo info;
  List<Lecture> classes = new List();
  DateTime selectedDay = DateTime.now();

  ClassesToday(ClassInfo info) {
    this.info = info;
  }

  // @todo: Optimize this crap because waw those are some hacky algorithms
  void update() {
    print("Updating");
    setState(() {
      classes.clear();

      DateTime today = DateTime(
          this.selectedDay.year, this.selectedDay.month, this.selectedDay.day);

      for (Lecture lec in this.info.classes) {
        DateTime classday =
            DateTime(lec.start.year, lec.start.month, lec.start.day);

        if (classday == today) {
          int i = 0;
          for (Lecture cur in this.classes) {
            if (lec.start.compareTo(cur.start) < 0) {
              classes.insert(i, lec);
              break;
            }
            i++;
          }
          if (i == this.classes.length) classes.add(lec);
        }
      }
    });
  }

  Widget _buildWeekScroller() {
    return CalendarStrip(onDateSelected: ((date) {
      this.selectedDay = date;
      update();
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
    if (rotsystem.contains("blauw"))
      return [Color.fromARGB(0xFF, 0, 52, 154), Colors.white];
    else if (rotsystem.contains("oranje"))
      return [Color.fromARGB(0xFF, 251, 106, 16), Colors.white];

    return [null, null];
  }

  /// Creates a class or lecture tab for the
  Widget _createClassItem(BuildContext context, int i) {
    var icon = Icons.record_voice_over_outlined;
    if (this.classes[i].name.toLowerCase().contains("wpo"))
      icon = Icons.subject;

    var colors = _colorFromRotString(this.classes[i].name);

    if (this.classes[i].name.toLowerCase().contains("rotatiesysteem"))
      return Card(
          child: ListTile(
              title: Text(this.classes[i].name,
                  style: TextStyle(color: colors[1]))),
          color: colors[0]);

    String policyString = this.classes[i].remarks;
    if (this.classes[i].remarks.toLowerCase().contains("rotatiesysteem"))
      policyString = "Rotatiesysteem: " +
          ((this.info.isUserAllowed())
              ? "you are allowed to come"
              : "you are not allowed to come");

    return Card(
        child: ListTile(
            leading: Icon(icon),
            title: Text(this.classes[i].name),
            isThreeLine: false,
            subtitle: Padding(
                padding: EdgeInsets.all(0),
                child: Column(children: [
                  Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(
                            child: Text(this.classes[i].location,
                                overflow: TextOverflow.ellipsis)),
                        Text(this.classes[i].start.hour.toString() +
                            ":" +
                            _minutes(this.classes[i].end.minute) +
                            " - " +
                            this.classes[i].end.hour.toString() +
                            ":" +
                            _minutes(this.classes[i].end.minute))
                      ], mainAxisAlignment: MainAxisAlignment.spaceBetween)),
                  Row(children: [
                    Expanded(
                        child:
                            Text(policyString, overflow: TextOverflow.ellipsis))
                  ], mainAxisAlignment: MainAxisAlignment.start)
                ]))));
  }

  /// Builds the lesson tray (the main screen actually)
  Widget _buildMainScreen() {
    var list = ListView.builder(
        itemBuilder: _createClassItem, itemCount: this.classes.length);
    return Column(children: [_buildWeekScroller(), Expanded(child: list)]);
  }

  void openSettings() {
    print("Settings");
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => SettingsMenu(this.info)));
  }

  void openAbout() {
    print("About");
  }

  Widget _buildDrawer() {
    return Drawer(
        child: ListView(
      children: [
        DrawerHeader(
            child: Text("Header"),
            decoration: BoxDecoration(color: Colors.blue)),
        ListTile(title: Text("Settings"), onTap: openSettings),
        ListTile(title: Text("About"), onTap: openAbout)
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: _buildDrawer(),
        appBar: AppBar(
          title: Text("Today's classes"),
          actions: [
            IconButton(
                icon: Icon(Icons.replay_sharp),
                onPressed: () => this.info.updateInfo())
          ],
        ),
        body: _buildMainScreen());
  }
}
