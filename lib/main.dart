import "package:flutter/material.dart";
import "package:calendar_strip/calendar_strip.dart";

import "parser.dart";
import "classinfo.dart";

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
    info.updateCallback = state.update;
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

  Widget _buildLastUpdatedWidget() {
    // @todo: Last updated, maybe we will display this in the navigator view
    return Text("Last updated: ");
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

  /// Creates a class or lecture tab for the
  Widget _createClassItem(BuildContext context, int i) {
    var icon = Icons.record_voice_over_outlined;
    if (this.classes[i].name.toLowerCase().contains("wpo"))
      icon = Icons.subject;
    return Card(
        child: ListTile(
            leading: Icon(icon),
            title: Text(this.classes[i].name),
            subtitle: Text(this.classes[i].start.hour.toString() +
                ":" +
                _minutes(this.classes[i].end.minute) +
                " - " +
                this.classes[i].end.hour.toString() +
                ":" +
                _minutes(this.classes[i].end.minute))));
  }

  /// Builds the lesson tray (the main screen actually)
  Widget _buildMainScreen() {
    var list = ListView.builder(
        itemBuilder: _createClassItem, itemCount: this.classes.length);
    return Column(children: [
      _buildLastUpdatedWidget(),
      _buildWeekScroller(),
      Expanded(child: list)
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("Today's classes"),
            actions: [
              IconButton(
                  icon: Icon(Icons.replay_sharp),
                  onPressed: () => this.info.updateInfo())
            ],
            leading: IconButton(icon: Icon(Icons.list), onPressed: null)),
        body: _buildMainScreen());
  }
}
