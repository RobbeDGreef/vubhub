import "package:flutter/material.dart";
import "package:calendar_strip/calendar_strip.dart";
import 'package:flutter/services.dart';
import "package:intl/intl.dart";
import "package:flushbar/flushbar.dart";
import "package:photo_view/photo_view.dart";

import "parser.dart";
import "infohandler.dart";
import "settings.dart";
import "const.dart";
import "places.dart";

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
/// and another one
class ClassesToday extends State<MainUi> {
  InfoHandler info;
  List<Lecture> classes = [Lecture.empty()];
  DateTime selectedDay = DateTime.now();
  int todaysColor = 0;
  int _selectedNavBarIndex = 0;
  bool _loading = true;

  ClassesToday(InfoHandler info) {
    this.info = info;
    loadNewClassData(DateTime.now(), false);
  }

  void loadNewClassData(DateTime date, [bool shouldSetState = true]) {
    if (shouldSetState) {
      setState(() {
        this._loading = true;
        this.classes.clear();
        this.classes.add(Lecture.empty());
      });
    }

    this.info.getClassesOfDay(date).then((list) {
      this._loading = false;
      update(list);
    });
  }

  void update(List<Lecture> classes) {
    print("Updating");
    setState(() {
      bool rotset = false;
      this.classes.clear();
      if (classes.isEmpty) {
        this.classes.add(Lecture.onlyName("No classes today"));
      }
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
    /// I hate this. This is such a hack but the code from calendar_strip doesn't allow
    /// for selectedDate to exist without startDate and endDate being specified.
    /// to be clear, it should, but there are quite a few bugs in that code and I'm pretty
    /// sure this is one of them.
    return CalendarStrip(
        selectedDate: this.selectedDay != null ? this.selectedDay : DateTime.now(),
        startDate: DateTime(0),
        endDate: DateTime(3000),
        addSwipeGesture: true,
        onDateSelected: ((date) {
          this.selectedDay = date;
          loadNewClassData(date);
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
        Flushbar(
          margin: EdgeInsets.all(8),
          borderRadius: 8,
          message: "Copied text to clipboard",
          icon: Icon(Icons.info_outline, color: Colors.blue),
          duration: Duration(seconds: 2),
          animationDuration: Duration(milliseconds: 500),
        ).show(context);
      },
    ));
  }

  Widget _buildLectureDetails(int index) {
    Lecture lec = this.classes[index];
    final List<List<dynamic>> details = [
      [lec.professor, Icon(Icons.person_outline)],
      [lec.details, Icon(Icons.dehaze)],
      [lec.location, Icon(Icons.location_on)],
      [lec.remarks, Icon(Icons.event_note_outlined)],
      [
        DateFormat("EEEE d MMMM").format(lec.start) +
            " from " +
            DateFormat("H:mm").format(lec.start) +
            " until " +
            DateFormat("H:mm").format(lec.end),
        Icon(Icons.access_time)
      ]
    ];
    final List<Widget> children = [
      Padding(
          padding: EdgeInsets.only(left: 4, right: 4, bottom: 16, top: 16),
          child: Text(lec.name, style: TextStyle(fontSize: 20))),
    ];

    for (List<dynamic> info in details) {
      if (info[0] != "") children.add(_buildLectureDetailTile(info[0], info[1]));
    }

    return Scaffold(appBar: AppBar(title: Text("Details")), body: ListView(children: children));
  }

  void openLectureDetails(int index) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) => _buildLectureDetails(index)));
  }

  /// Creates a class or lecture tab for the
  Widget _createClassItem(BuildContext context, int i) {
    if (this._loading) {
      return Center(
          child: Container(
        margin: EdgeInsets.all(8),
        child: CircularProgressIndicator(),
        width: 50,
        height: 50,
      ));
    }
    var icon = Icons.record_voice_over_outlined;
    if (this.classes[i].name.toLowerCase().contains("wpo")) {
      icon = Icons.subject;
    }

    var colors = _colorFromRotString(this.classes[i].name);

    if (this.classes[i].name.toLowerCase() == "no classes today") {
      return ListTile(title: Text("No classes today", textAlign: TextAlign.center));
    }

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
      loadNewClassData(this.selectedDay);
    }
  }

  void openAbout() {
    print("About");
  }

  Widget _buildDrawer() {
    return Drawer(
        child: ListView(
      children: [
        DrawerHeader(
            decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage("assets/vub-cs.png")),
                color: Colors.white)),
        ListTile(title: Text("Settings"), onTap: openSettings),
        ListTile(title: Text("About"), onTap: openAbout)
      ],
    ));
  }

  void openLibraryBooking() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => LibraryBookingMenu(this.info),
      ),
    );
  }

  Widget _buildPlaceTile(String title, Function() ptr) {
    return Card(
      child: ListTile(
        contentPadding: EdgeInsets.all(5),
        leading: Icon(Icons.library_books),
        title: Text(title),
        onTap: () => ptr(),
      ),
    );
  }

  List<Widget> _getPlaces() {
    return [
      _buildPlaceTile("Centrale bibliotheek VUB", openLibraryBooking),
    ];
  }

  Widget createScreen(int index) {
    switch (index) {
      case 0:
        return _buildMainScreen();

      case 1:
        return PhotoView(
          imageProvider: AssetImage("assets/VubMapNew.png"),
        );

      case 2:
        return MapView();

      case 3:
        return ListView(children: _getPlaces());

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

    final tabText = ["Today's classes", "VUB campus map", "places", "help"];

    return Scaffold(
        drawer: _buildDrawer(),
        bottomNavigationBar: bottom,
        appBar: AppBar(
          title: Text(tabText[this._selectedNavBarIndex]),
          actions: (this._selectedNavBarIndex == 0)
              ? [
                  IconButton(
                      icon: Icon(Icons.replay_sharp),
                      onPressed: () {
                        setState(() {
                          this.classes.clear();
                          this.classes.add(Lecture.empty());
                          this._loading = true;
                        });
                        this
                            .info
                            .forceCacheUpdate(this.info.calcWeekFromDate(this.selectedDay))
                            .then((_) {
                          loadNewClassData(this.selectedDay, false);
                        });
                      })
                ]
              : [],
        ),
        body: createScreen(this._selectedNavBarIndex));
  }
}
