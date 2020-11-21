import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../event.dart';

class TimeTableView extends StatefulWidget {
  DateTime weekStartDate;
  Future<List<Event>> Function(DateTime) provider;
  Function(Event) onTap;
  int weekLength;

  TimeTableView(
      {@required this.weekStartDate, @required this.provider, this.weekLength = 7, this.onTap});
  @override
  _TimeTableViewState createState() =>
      _TimeTableViewState(this.weekStartDate, this.provider, this.weekLength, this.onTap);
}

class _TimeTableViewState extends State<TimeTableView> {
  DateTime weekStartDate;
  double hourHeight = 50;
  int weekLength;
  Future<List<Event>> Function(DateTime) provider;
  Function(Event) onTap;

  _TimeTableViewState(this.weekStartDate, this.provider, this.weekLength, this.onTap);

  Widget _buildDayNotification(Event e) {
    return Card(
      color: Colors.red,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          e.name.split(RegExp("&gt|>"))[1].substring(1),
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDayWidgets(Map<int, List<Event>> dayNotifications) {
    final weekDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return Padding(
      padding: EdgeInsets.only(left: _getTextSize('00', TextStyle()).width),
      child: Row(
        children: List<Widget>.generate(
          this.weekLength,
          (index) {
            final day = this.weekStartDate.add(Duration(days: index));
            return Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(weekDays[day.weekday - 1]),
                  Text(DateFormat("dd").format(day), style: TextStyle(fontSize: 18)),
                  for (Event e in dayNotifications[index] ?? []) _buildDayNotification(e),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventTile(Event e, Map<int, int> indentMap) {
    /// When two events overlap, we want one to stick out a bit so the user notices that there are two. That is what we use the indent
    /// map for.

    final detailStyle = TextStyle(fontSize: 12);

    if (indentMap[e.startDate.hour] != null)
      indentMap[e.startDate.hour] += 10;
    else
      indentMap[e.startDate.hour] = 0;

    return Card(
      margin: EdgeInsets.only(right: 10.0 + indentMap[e.startDate.hour], bottom: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      elevation: 4.0,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        child: SizedBox(
          height: this.hourHeight * (e.endDate.difference(e.startDate).inMinutes / 60),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: ListView(
              physics: NeverScrollableScrollPhysics(),
              children: [
                Text(e.name, style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 5),
                if (e.location != "") Text(e.location, style: detailStyle),
                Text(e.remarks, style: detailStyle),
              ],
            ),
          ),
        ),
        onTap: () {
          if (this.onTap != null) this.onTap(e);
        },
      ),
    );
  }

  Widget _buildEventRow(int index, List<Event> events) {
    var stack = Stack(
      fit: StackFit.passthrough,
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: List<Widget>.generate(24, (index) {
                    return Column(children: [
                      SizedBox(height: this.hourHeight),
                      Divider(
                        endIndent: 0,
                        height: 0,
                        indent: 0,
                        thickness: 1,
                      ),
                    ]);
                  }),
                ),
              ),
              VerticalDivider(
                thickness: 1,
                width: 2,
                endIndent: 0,
                indent: 5,
              ),
            ],
          ),
        ),
      ],
    );

    if (events != null) {
      Map<int, int> indentMap = {};
      for (Event e in events) {
        stack.children.add(
          Positioned.fill(
            top: (e.startDate.hour + e.startDate.minute / 60) * this.hourHeight,
            bottom: (24.0 - (e.endDate.hour + e.endDate.minute / 60)) * this.hourHeight,
            child: _buildEventTile(e, indentMap),
          ),
        );
      }
    }

    return Expanded(
      child: stack,
    );
  }

  Widget _buildEventView(Map<int, List<Event>> events) {
    return Expanded(
      child: SingleChildScrollView(
        controller: ScrollController(initialScrollOffset: 6 * this.hourHeight),
        child: Row(
          children: [
            _buildHourWidget(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List<Widget>.generate(
                    this.weekLength,
                    (index) => _buildEventRow(
                        index, events[this.weekStartDate.add(Duration(days: index)).day])),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Size _getTextSize(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
      textDirection: ui.TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: 200);
    return painter.size;
  }

  Widget _buildHourWidget() {
    // Here we calculate the height the hour text will have, we use text '0' because we will never have anything larger than that.
    // However i don't exactly know why this code works because something tells me that we should divide the height by 2 but for some
    // reason thats wrong
    return Padding(
      padding: EdgeInsets.only(left: 5, right: 5),
      child: Column(
        children: List<Widget>.generate(24, (index) {
          return SizedBox(
            height: index == 0
                ? this.hourHeight - _getTextSize('0', TextStyle()).height
                : this.hourHeight,
            child: index != 0 ? Text(index.toString()) : Text(""),
          );
        }),
      ),
    );
  }

  Widget _buildMonthWidget() {
    var monthText = DateFormat("MMMM").format(this.weekStartDate);
    if (this.weekStartDate.add(Duration(days: 7)).month != this.weekStartDate.month)
      monthText += " / ${DateFormat("MMMM").format(this.weekStartDate.add(Duration(days: 7)))}";

    monthText += " ${this.weekStartDate.year}";

    return Padding(
      padding: EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: OutlinedButton(
              child: Text("Jump to this week"),
              style: ButtonStyle(
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Theme.of(context).primaryColor)),
              onPressed: () {
                setState(() {
                  this.weekStartDate =
                      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
                });
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_back_ios_sharp),
            onPressed: () {
              setState(() {
                this.weekStartDate = this.weekStartDate.subtract(Duration(days: 7));
              });
            },
            splashRadius: 20,
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios_sharp),
            onPressed: () {
              setState(() {
                this.weekStartDate = this.weekStartDate.add(Duration(days: 7));
              });
            },
            splashRadius: 20,
          ),
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text(monthText, style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<int, List<Event>> parsedEvents = {};
    Map<int, List<Event>> dayNotifications = {};

    return FutureBuilder(
      future: this.provider(this.weekStartDate),
      builder: (context, snapshot) {
        Widget eventWidget = Expanded(
          child: Center(
            child: Container(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(),
            ),
          ),
        );
        if (snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
          for (Event e in snapshot.data) {
            if (e.name.startsWith(RegExp('&lt|<'))) {
              if (dayNotifications[e.startDate.weekday - 1] == null)
                dayNotifications[e.startDate.weekday - 1] = [];

              var list = dayNotifications[e.startDate.weekday - 1];
              if (list.indexWhere((element) => element.name == e.name) == -1) list.add(e);
            } else {
              if (parsedEvents[e.startDate.day] == null) parsedEvents[e.startDate.day] = [];
              parsedEvents[e.startDate.day].add(e);
            }
          }
          eventWidget = _buildEventView(parsedEvents);
        }
        return Column(
          children: [
            _buildMonthWidget(),
            _buildDayWidgets(dayNotifications),
            Divider(thickness: 1, color: Colors.grey),
            eventWidget,
          ],
        );
      },
    );
  }
}
