import 'package:flutter/material.dart';
import 'package:vubhub/infohandler.dart';
import 'package:flutter/services.dart';
import 'package:flushbar/flushbar.dart';
import 'package:intl/intl.dart';

import 'calendar_strip/calendar_strip.dart';

import 'infohandler.dart';
import 'theming.dart';
import 'const.dart';
import 'event.dart';

class DayView extends StatefulWidget {
  InfoHandler info;
  _DayViewState state;

  void fullUpdate() {
    if (this.state != null) {
      this.state.fullUpdate();
    }
  }

  void update() {
    if (this.state != null) {
      this.state.update();
    }
  }

  DayView({this.info});
  @override
  _DayViewState createState() {
    this.state = _DayViewState(this.info);
    return this.state;
  }
}

class _DayViewState extends State<DayView> {
  InfoHandler _info;
  List<Event> _classes = [];
  DateTime _selectedDay = DateTime.now();
  DateTime _selectedWeek = DateTime.now();
  int _todaysColor = 0;
  bool _loading = true;

  _DayViewState(InfoHandler info) {
    this._info = info;
    _loadNewClassData(DateTime.now(), false);
  }

  void fullUpdate() {
    setState(
      () {
        this._classes.clear();
        this._loading = true;
      },
    );
    this._info.forceCacheUpdate(this._info.calcWeekFromDate(this._selectedDay)).then((_) {
      _loadNewClassData(this._selectedDay, false);
    });
  }

  void update() {
    this._loadNewClassData(this._selectedDay);
  }

  /// This function will update the this._classes list
  /// it takes an extra optional flag for handling the loading
  void _loadNewClassData(DateTime date, [bool shouldSetState = true]) {
    if (shouldSetState) {
      setState(() {
        this._loading = true;
        this._classes.clear();
      });
    }

    this._info.getClassesOfDay(date).then((list) {
      this._loading = false;
      _update(list);
    });
  }

  /// This function will update the this._classes list from
  /// a parsed Lecture object data list. It handles sorting
  /// and other hacks.
  void _update(List<Event> classes) {
    print("Updating");
    setState(() {
      bool rotset = false;
      this._classes.clear();

      for (Event lec in classes) {
        // If the rotationsystem is already specified don't add it again
        if (lec.name.toLowerCase().contains("rotatie")) {
          if (rotset) continue;
          rotset = true;
        }

        int i = 0;
        for (Event prevLec in this._classes) {
          if (lec.startDate.compareTo(prevLec.startDate) < 0) {
            this._classes.insert(i, lec);
            break;
          }
          ++i;
        }
        if (this._classes.length == i) {
          this._classes.add(lec);
        }
      }
    });
  }

  DateTime _calcWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Widget _buildMonthNameWidget(String monthString) {
    /// What we would like to achieve:
    ///   Month1 / Month2 2020            week x
    ///
    /// note that month2 is optional (for weeks that start in a different
    /// month than they end)

    /*
    DateTime weekStart = _calcWeekStart(date);
    DateTime weekEnd = _calcWeekStart(date).add(Duration(days: 6));

    String monthString = DateFormat("MMMM").format(weekStart);
    if (weekStart.month != weekEnd.month) {
      monthString += " / " + DateFormat("MMMM").format(weekEnd);
    }
    */

    int weekNum = this._info.calcWeekFromDate(this._selectedWeek);
    String weekString = "week $weekNum";

    // We want to prevent printing week 0 or week -1 etc
    if (weekNum > 0) {
      monthString += " - " + weekString;
    }

    TextStyle style = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87);
    return Padding(
      padding: EdgeInsets.only(top: 7, bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(monthString, style: style),
        ],
      ),
    );
  }

  Widget _buildWeekScroller() {
    /// I hate this. This is such a hack but the code from calendar_strip doesn't allow
    /// for selectedDate to exist without startDate and endDate being specified.
    /// to be clear, it should, but there are quite a few bugs in that code and I'm pretty
    /// sure this is one of them.

    DateTime selected = this._selectedDay != null ? this._selectedDay : DateTime.now();
    return CalendarStrip(
        monthNameWidget: _buildMonthNameWidget,
        selectedDate: selected,
        startDate: DateTime(0),
        endDate: DateTime(3000),
        addSwipeGesture: true,
        onWeekSelected: ((date) {
          this._selectedWeek = date;
        }),
        onDateSelected: ((date) {
          this._selectedDay = date;
          _loadNewClassData(date);
        }));
  }

  /// Prettify the minutes string to use double digit notation
  String _prettyMinutes(int x) {
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
        margin: EdgeInsets.only(left: 8, right: 8, bottom: 4, top: 4),
        child: ListTile(
          title: Text(text),
          leading: icon,
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: text));
            Flushbar(
              margin: EdgeInsets.all(8),
              borderRadius: 8,
              message: "Copied text to clipboard",
              icon: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
              duration: Duration(seconds: 2),
              animationDuration: Duration(milliseconds: 500),
            ).show(context);
          },
        ));
  }

  Widget _buildLectureDetails(int index) {
    Event lec = this._classes[index];

    // Nothing special going on here, just instead of writing the whole
    // widget tree every time for theses objects i just added them to a list
    // to cleanly generate them at the bottom of the function.
    final List<List<dynamic>> details = [
      [lec.host, Icon(Icons.person_outline)],
      [lec.details, Icon(Icons.dehaze)],
      [lec.location, Icon(Icons.location_on)],
      [lec.remarks, Icon(Icons.event_note_outlined)],
      [
        DateFormat("EEEE d MMMM").format(lec.startDate) +
            " from " +
            DateFormat("H:mm").format(lec.startDate) +
            " until " +
            DateFormat("H:mm").format(lec.endDate),
        Icon(Icons.access_time)
      ]
    ];

    final List<Widget> children = [
      Padding(
          padding: EdgeInsets.only(left: 4, right: 4, bottom: 16, top: 16),
          child: Text(
            lec.name,
            style: TextStyle(fontSize: 20, color: AlmostDark),
            textAlign: TextAlign.center,
          )),
    ];

    for (List<dynamic> info in details) {
      if (info[0] != "") children.add(_buildLectureDetailTile(info[0], info[1]));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Details")),
      body: ListView(children: children),
      backgroundColor: AlmostWhite,
    );
  }

  void _openLectureDetails(int index) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) => _buildLectureDetails(index)));
  }

  /// Creates a class or lecture tab for the
  Widget _buildClassListTile(BuildContext context, int i) {
    // Display a circular throbber to show the user the system is loading
    if (this._loading) {
      return Center(
          child: Container(
        margin: EdgeInsets.all(8),
        child: CircularProgressIndicator(),
        width: 50,
        height: 50,
      ));
    }

    // Display a widget so the user knows he has no classes and that it is
    // normal that the list view is empty.
    if (this._classes.length == 0) {
      return ListTile(title: Text("No classes today", textAlign: TextAlign.center));
    }

    var icon = Icons.record_voice_over_outlined;
    if (this._classes[i].name.toLowerCase().contains("wpo")) {
      icon = Icons.subject;
    }

    var colors = _colorFromRotString(this._classes[i].name);

    if (this._classes[i].name.toLowerCase().contains("<font color=")) {
      return Card(
          child: ListTile(
              title: Text(
                  "Rotatiesysteem: rotatie " +
                      (this._classes[i].name.contains("BLAUW") ? "blauw" : "oranje"),
                  style: TextStyle(color: colors[1]))),
          color: colors[0]);
    }

    String policyString = this._classes[i].remarks;
    if (this._classes[i].remarks.toLowerCase().contains("rotatiesysteem"))
      policyString = "Rotatiesysteem: " +
          ((this._info.isUserAllowed(this._todaysColor))
              ? "you are allowed to come"
              : "you are not allowed to come");

    return Card(
        child: ListTile(
            leading: Icon(icon),
            title: Text(this._classes[i].name),
            isThreeLine: false,
            onTap: () => _openLectureDetails(i),
            subtitle: Padding(
                padding: EdgeInsets.all(0),
                child: Column(children: [
                  Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(
                            child:
                                Text(this._classes[i].location, overflow: TextOverflow.ellipsis)),
                        Text(this._classes[i].startDate.hour.toString() +
                            ":" +
                            _prettyMinutes(this._classes[i].endDate.minute) +
                            " - " +
                            this._classes[i].endDate.hour.toString() +
                            ":" +
                            _prettyMinutes(this._classes[i].endDate.minute))
                      ], mainAxisAlignment: MainAxisAlignment.spaceBetween)),
                  Row(children: [
                    Expanded(child: Text(policyString, overflow: TextOverflow.ellipsis))
                  ], mainAxisAlignment: MainAxisAlignment.start)
                ]))));
  }

  @override
  Widget build(BuildContext context) {
    // The ternary operator on the item count there is used to aways
    // at least return 1, so that we can call the listview builder to build
    // our "You have no classes" and loading symbol widgets.
    return Column(
      children: [
        _buildWeekScroller(),
        Expanded(
          child: ListView.builder(
            itemBuilder: _buildClassListTile,
            itemCount: this._classes.length == 0 ? 1 : this._classes.length,
          ),
        ),
      ],
    );
  }
}
