import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/intl.dart';

import '../canvas/canvasapi.dart';
import '../canvas/canvasobjects.dart';

class Meetings extends StatefulWidget {
  Course details;
  CanvasApi canvas;
  Meetings({this.details, this.canvas});

  @override
  _MeetingsState createState() => _MeetingsState(this.details, canvas);
}

class _MeetingsState extends State<Meetings> {
  Course _details;
  List<Meeting> ongoing = [];
  List<Meeting> completed = [];
  bool _loading = true;
  CanvasApi _canvas;

  _MeetingsState(Course details, CanvasApi canvas) {
    this._details = details;
    this._canvas = canvas;

    canvas.get('api/v1/courses/${this._details.id}/conferences').then((data) {
      setState(() {
        this._loading = false;
        for (var conf in data['conferences']) {
          Meeting meeting = Meeting(conf);
          if (meeting.ended == null)
            this.ongoing.add(meeting);
          else
            this.completed.add(meeting);
        }
      });
    });
  }

  int _count(List<Meeting> count) {
    if (count.isEmpty) {
      return 1;
    }
    return count.length;
  }

  void _buildRecordingPlayer(Recording rec) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(rec.title), backgroundColor: this._details.color),
          body: WebView(
            initialUrl: rec.url,
            javascriptMode: JavascriptMode.unrestricted,
            userAgent:
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36',
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingTile(List<Meeting> list, int index, String emptyString) {
    if (this._loading)
      return Center(
        child: Container(child: CircularProgressIndicator(), width: 50, height: 50),
      );

    if (list.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Center(
          child: Text(emptyString, style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
        ),
      );
    }

    DateTime date = list[index].started;
    if (list[index].ended != null) {
      date = list[index].ended;
    }

    List<Widget> tileChildren;
    if (list[index].ended == null) {
      tileChildren = [
        Divider(),
        TextButton(
          child: Text("Join conference"),
          onPressed: list[index].url != null
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                            title: Text(list[index].title), backgroundColor: this._details.color),
                        body: WebView(
                          initialUrl: list[index].url,
                          javascriptMode: JavascriptMode.unrestricted,
                          userAgent:
                              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36',
                        ),
                      ),
                    ),
                  )
              : null,
        ),
      ];
    } else {
      print(list[index].recordings.length);
      Widget recording = Text("There are no recordings of this meeting");
      if (list[index].recordings.isNotEmpty) {
        recording = TextButton(
            child: Text("View recording"),
            onPressed: () => _buildRecordingPlayer(list[index].recordings[0]));
      }
      tileChildren = [
        Divider(),
        recording,
      ];
    }

    return Card(
      child: Theme(
        data: ThemeData(accentColor: this._details.color),
        child: ExpansionTile(
          childrenPadding: EdgeInsets.only(bottom: 8),
          title: Text(list[index].title),
          subtitle: Text(DateFormat("d MMMM 'at' hh:mm ").format(date),
              style: TextStyle(color: Colors.grey[700])),
          children: tileChildren,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Meetings"), backgroundColor: this._details.color),
      body: ListView(
        padding: EdgeInsets.only(top: 16),
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8, right: 8),
            child: Text("Ongoing meetings", style: TextStyle(fontSize: 20)),
          ),
          Divider(),
          ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            itemCount: _count(this.ongoing),
            itemBuilder: (_, int i) => _buildMeetingTile(
                this.ongoing, i, "There are currently no ongoing meetings for this course"),
            shrinkWrap: true,
          ),
          Padding(
            padding: EdgeInsets.only(left: 8, right: 8),
            child: Text("Completed meetings", style: TextStyle(fontSize: 20)),
          ),
          Divider(),
          ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            itemCount: _count(this.completed),
            itemBuilder: (_, int i) => _buildMeetingTile(
                this.completed, i, "There are no completed meetings for this course"),
            shrinkWrap: true,
          ),
        ],
      ),
    );
  }
}
