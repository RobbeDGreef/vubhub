import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vubhub/infohandler.dart';
import 'package:flutter/services.dart';
import 'package:flushbar/flushbar.dart';
import 'package:intl/intl.dart';
import 'package:vubhub/timetableview/timetableview.dart';

import 'calendar_strip/calendar_strip.dart';
import 'canvas/canvasapi.dart';

import 'infohandler.dart';
import 'theming.dart';
import 'const.dart';
import 'event.dart';
import 'todoview.dart';

class DayView extends StatefulWidget {
  InfoHandler info;
  _DayViewState state;
  Orientation orientation;

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

  DayView(this.info, this.orientation);
  @override
  _DayViewState createState() => _DayViewState(this.info, this.orientation);
}

class _DayViewState extends State<DayView> {
  InfoHandler _info;
  DateTime _selectedDay = DateTime.now();
  DateTime _selectedWeek = DateTime.now();
  Orientation _orientation;
  int _todaysColor = 0;
  bool timeTableView = false;

  int lastDayIndex = 1000;
  bool _loading = true;

  CanvasApi _canvas;
  int _todoCount = 0;

  @override
  void initState() {
    this.widget.state = this;
    super.initState();
  }

  _DayViewState(InfoHandler info, Orientation orientation) {
    this._info = info;
    this._orientation = orientation;

    if (this._orientation == Orientation.landscape) this.timeTableView = true;

    if (this._info.user.accessToken != null) {
      this._canvas = CanvasApi(this._info.user.accessToken);
      this._canvas.get('api/v1/users/self/todo_item_count').then((data) {
        for (var key in data.keys) {
          setState(() {
            this._todoCount += data[key];
          });
        }
      });
    }
  }

  void fullUpdate() {
    // todo
    setState(() {});
    this._info.forceCrawlerFetch(InfoHandler.calcWeekFromDate(this._selectedDay)).then((_) {
      //_loadNewClassData(this._selectedDay, false);
    });
  }

  void update() {
    // todo: is this correct
    setState(() {});
  }

  Future<List<Event>> _loadNewClassData(DateTime date) async {
    this._loading = true;
    List<Event> list = await this._info.getTodaysEvents(date);
    print("list found $list");
    return _parseEvents(list);
  }

  Future<List<Event>> _loadNewWeekClassData([int week = -1]) async {
    this._loading = true;
    List<Event> list = await this._info.getWeekData(week);

    // Easy way to remove duplicates from a list.
    return list.toSet().toList();
  }

  /// This function will update the this._classes list from
  /// a parsed Lecture object data list. It handles sorting
  /// and other hacks.
  List<Event> _parseEvents(List<Event> classes) {
    print("Updating");

    List<Event> parsed = [];

    for (Event lec in classes) {
      if (parsed.indexWhere((element) => (element == lec)) != -1) continue;

      // Set the day's color
      if (lec.name.toLowerCase().contains("<font color")) {
        this._todaysColor = lec.name.toLowerCase().contains("blue") ? 0 : 1;
      }

      int i = 0;
      for (Event prevLec in parsed) {
        if (lec.startDate.compareTo(prevLec.startDate) < 0) {
          parsed.insert(i, lec);
          break;
        }
        ++i;
      }
      if (parsed.length == i) {
        parsed.add(lec);
      }
    }
    return parsed;
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

    int weekNum = InfoHandler.calcWeekFromDate(this._selectedWeek);
    String weekString = "week $weekNum";

    // We want to prevent printing week 0 or week -1 etc
    if (weekNum > 0) {
      monthString += " - " + weekString;
    }

    TextStyle style = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
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
        iconColor: Theme.of(context).textTheme.bodyText1.color,
        selectedDate: selected,
        startDate: DateTime(0),
        endDate: DateTime(3000),
        addSwipeGesture: true,
        onWeekSelected: ((date) {
          this._selectedWeek = date;
        }),
        onDateSelected: ((date) {
          setState(() {
            this._selectedDay = date;
            this._loading = true;
          });
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

    // TODO: do this with a list or somthing similar
    if (rotsystem.contains("blauw")) {
      return [VubBlue, Colors.white];
    } else if (rotsystem.contains("oranje")) {
      return [VubOrange, Colors.white];
    } else if (rotsystem.contains("red")) {
      return [Colors.red, Colors.white];
    }

    return [null, null];
  }

  Widget _buildEventDetailTile(String text, Icon icon) {
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

  Widget _buildEventDetails(Event lec) {
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
            style: TextStyle(fontSize: 20, color: Theme.of(context).textTheme.bodyText1.color),
            textAlign: TextAlign.center,
          )),
    ];

    for (List<dynamic> info in details) {
      if (info[0] != "") children.add(_buildEventDetailTile(info[0], info[1]));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Details")),
      body: ListView(children: children),
    );
  }

  void _openEventDetails(Event lec) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) => _buildEventDetails(lec)));
  }

  Widget _buildEventTile(List<Event> eventlist, int i) {
    // Display a widget so the user knows he has no classes and that it is
    // normal that the list view is empty.
    if (eventlist.length == 0) {
      return ListTile(title: Text("You have no classes today.", textAlign: TextAlign.center));
    }

    var icon = Icons.record_voice_over_outlined;
    if (eventlist[i].name.toLowerCase().contains("wpo")) {
      icon = Icons.subject;
    }

    var colors = _colorFromRotString(eventlist[i].name);

    if (eventlist[i].name.toLowerCase().contains(RegExp("<font color=|&lt;font color="))) {
      return Card(
          child: ListTile(
            title: Text(
              kIsWeb
                  ? eventlist[i].name.substring(eventlist[i].name.indexOf(RegExp('&gt;')) + 4)
                  : eventlist[i].name.substring(eventlist[i].name.indexOf(RegExp('>')) + 1),
              style: TextStyle(
                color: colors[1],
              ),
            ),
          ),
          color: colors[0]);
    }

    String policyString = eventlist[i].remarks;
    if (eventlist[i].remarks.toLowerCase().contains("rotatiesysteem"))
      policyString = "Rotatiesysteem: " +
          ((this._info.user.rotationColor == this._todaysColor)
              ? "you are allowed to come"
              : "you are not allowed to come");

    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: ListTile(
          //tileColor: tileColor,
          leading: Icon(icon),
          title: Text(eventlist[i].name, style: TextStyle(/*color: textColor*/)),
          isThreeLine: false,
          onTap: () => _openEventDetails(eventlist[i]),
          subtitle: Padding(
            padding: EdgeInsets.all(0),
            child: Column(
              children: [
                Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(
                          child: Text(eventlist[i].location,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(/*color: textColor2*/))),
                      Text(
                        eventlist[i].startDate.hour.toString() +
                            ":" +
                            _prettyMinutes(eventlist[i].endDate.minute) +
                            " - " +
                            eventlist[i].endDate.hour.toString() +
                            ":" +
                            _prettyMinutes(eventlist[i].endDate.minute),
                        style: TextStyle(/*color: textColor2*/),
                      )
                    ], mainAxisAlignment: MainAxisAlignment.spaceBetween)),
                Row(children: [
                  Expanded(
                      child: Text(
                    policyString,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(/*color: textColor2*/),
                  ))
                ], mainAxisAlignment: MainAxisAlignment.start)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventView(Future<List<Event>> eventlist) {
    List<Widget> todoChildren = [];
    if (this._canvas != null && this._todoCount != 0) {
      todoChildren = [
        Divider(),
        TextButton(
          child: Text("You have ${this._todoCount} things to do."),
          onPressed: () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => TodoView(this._canvas))),
        ),
      ];
    }

    // The ternary operator on the item count there is used to aways
    // at least return 1, so that we can call the listview builder to build
    // our "You have no classes" and loading symbol widgets.
    print("builddd");
    return FutureBuilder(
      future: eventlist,
      builder: (context, snapshot) {
        if (snapshot.hasData && !this._loading) {
          this._loading = false;
          return ListView(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 0),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) => _buildEventTile(snapshot.data, index),
                  itemCount: snapshot.data.length == 0 ? 1 : snapshot.data.length,
                ),
              ),
              ...todoChildren,
            ],
          );
        }
        this._loading = false;
        return Center(child: Container(width: 50, height: 50, child: CircularProgressIndicator()));
      },
    );
  }
  /*
  Widget _buildTimeTable(List<Event> list) {
    final provider = tt.EventProvider.list(
      List<tt.BasicEvent>.generate(
        list.length,
        (i) => tt.BasicEvent(
          start: LocalDateTime.dateTime(list[i].startDate),
          end: LocalDateTime.dateTime(list[i].endDate),
          title: list[i].name,
          id: list[i],
          color: Colors.white,
        ),
      ),
    );
    return tt.Timetable(
      eventBuilder: (tt.Event e) {
        return tt.BasicEventWidget(
          e,
        );
      },
      controller: tt.TimetableController(eventProvider: provider, initialDate: LocalDate.today()),
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    // Making sure that the state is set in the parent
    this.widget.state = this;

    if (this.timeTableView) {
      return TimeTableView(
        weekStartDate: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
        provider: (DateTime startDate) {
          int week = InfoHandler.calcWeekFromDate(startDate);
          return _loadNewWeekClassData(week);
        },
        weekLength: 5,
        onTap: _openEventDetails,
      );
    }

    return Column(
      children: [
        _buildWeekScroller(),
        Expanded(
          child: GestureDetector(
            onPanEnd: (details) {
              setState(() {
                if (details.velocity.pixelsPerSecond.dx > 0)
                  this._selectedDay = this._selectedDay.subtract(Duration(days: 1));
                else
                  this._selectedDay = this._selectedDay.add(Duration(days: 1));
              });
            },
            child: _buildEventView(_loadNewClassData(this._selectedDay)),
          ),
        ),
        /*
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {},
            onHorizontalDragEnd: (details) {
              setState(() {
                if (details.primaryVelocity > 0)
                  this._selectedDay = this._selectedDay.subtract(Duration(days: 1));
                else
                  this._selectedDay = this._selectedDay.add(Duration(days: 1));
              });
            },
            child: _buildEventView(_loadNewClassData(this._selectedDay)),
          ),
        ),
        */
      ],
    );
  }
}
