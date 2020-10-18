import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'const.dart';
import 'infohandler.dart';
import 'theming.dart';

class CanvasApi {
  InfoHandler _infoHandler;
  // TODO: isn't this like a huge secret lol, shouldn't this be like... encrypted????
  String _userCanvasAuthToken;

  CanvasApi(InfoHandler infoHandler) {
    this._infoHandler = infoHandler;
    this._userCanvasAuthToken = this._infoHandler.getUserCanvasAuthToken();
  }

  Future<dynamic> request({@required String apiUrl, Map<String, String> optionalHeaders}) async {
    if (_userCanvasAuthToken == null) {
      print("'$_userCanvasAuthToken'");
      return {"errors": true};
    }
    Map<String, String> headers = {
      "Authorization": "Bearer " + _userCanvasAuthToken,
    };

    if (optionalHeaders != null) {
      headers.addAll(optionalHeaders);
    }
    var res = await http.get(CanvasUrl + apiUrl, headers: headers);
    return jsonDecode(res.body);
  }
}

class Assignment {
  String name;
  String details;
  DateTime dueDate;
  bool hasSubmitted;

  Assignment(Map<String, dynamic> data) {
    this.name = data["name"];
    this.details = data["description"];
    try {
    this.dueDate = DateTime.parse(data["due_at"]);
    } catch (ArgumentError) {
      this.dueDate = null;
    }
    this.hasSubmitted = data["has_submitted_submissions"];
  }
}

class Discussion {}

class CourseInfo {
  String name;
  String imageUrl;
  int id;
  Color color = Colors.grey;
  List<Assignment> assignments = [];
  List<Discussion> discussions = [];
  int unreadAnnouncements = 0;
  int dueAssignments = 0;
  int unreadDiscussions = 0;
  int curOngoingMeetings = 0;

  CourseInfo.empty();
  CourseInfo({this.name, this.id});
}

class CourseDetails extends StatefulWidget {
  final CourseInfo details;

  CourseDetails({this.details});

  @override
  _CourseDetailsState createState() => _CourseDetailsState(this.details);
}

class _CourseDetailsState extends State<CourseDetails> {
  CourseInfo _details;

  _CourseDetailsState(CourseInfo details) {
    this._details = details;
  }

  Widget _buildNotificationButton({Icon icon, int amount, Color color, Function() onPressed}) {
    /// Structure:
    /// Padding
    ///   - Stack to place the notification indicator on top of the iconbutton
    ///     - IconButton
    ///     - Positioned to place the card on the right of the stack (only if amount != 0)
    ///       - Card
    ///         - Text to display the notification amount

    List<Widget> children = [
      IconButton(
        color: Colors.grey[600],
        icon: icon,
        iconSize: 35.0,
        onPressed: onPressed,
      )
    ];

    if (amount != 0) {
      children.add(
        Positioned(
          right: 0,
          child: Card(
            color: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),

            // The text here is pre and post-fixed with spaces to make it take up
            // more space and create a properly sized card.
            child: Text(
              " " + amount.toString() + " ",
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(8),
      child: Stack(
        children: children,
      ),
    );
  }

  Widget _buildAssignmentTile(int index) {
    /// Will return "You currently have no assignments for this course." if
    /// the assignments list of the coursedetails is empty.
    /// If not, a widget of the following structure will be returned
    ///
    /// ListTile
    ///   - Text the assignment name
    if (this._details.assignments.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          "You currently have no assignments for this course.",
          textAlign: TextAlign.center,
        ),
      );
    }

    final icon = Icon(this._details.assignments[index].hasSubmitted
        ? Icons.check
        : Icons.check_box_outline_blank);

    return ListTile(
      title: Text(this._details.assignments[index].name),
      subtitle:
          Text("Due at ${DateFormat("d MMMM y").format(this._details.assignments[index].dueDate)}"),
      trailing: icon,
    );
  }

  Widget _buildView() {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.width * 0.55;

    /// Structure:
    /// Container to set the background color of the list view
    ///  - ListView
    ///    - Stack to show the image and color overlay
    ///    - Card that shows a quick menu with icons
    ///      - Row
    ///        - NotificationButton (custom)
    ///        - NotificationButton (custom)
    ///
    ///    - Text "Assignments"
    ///    - Card that quick show the assignments you have for this course
    ///      - ListView
    ///        - AssignmentTile (custom)
    ///          ...
    /// ...
    return ListView(
      children: [
        Stack(children: [
          SizedBox(
            width: width,
            height: height,
            child: (this._details.imageUrl != null)
                ? Image.network(
                    this._details.imageUrl,
                    fit: BoxFit.fitWidth,
                  )
                : null,
          ),
          Container(color: this._details.color.withAlpha(153), width: width, height: height),
        ]),
        Padding(
          padding: EdgeInsets.all(16),
          child: Card(
            elevation: 3.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNotificationButton(
                  icon: Icon(Icons.campaign),
                  amount: this._details.unreadAnnouncements,
                  color: this._details.color,
                  onPressed: () => print("Announcements"),
                ),
                _buildNotificationButton(
                  icon: Icon(Icons.assignment),
                  amount: this._details.dueAssignments,
                  color: this._details.color,
                  onPressed: () => print("Assignments"),
                ),
                _buildNotificationButton(
                  icon: Icon(Icons.question_answer),
                  amount: this._details.unreadDiscussions,
                  color: this._details.color,
                  onPressed: () => print("Discussions"),
                ),
                _buildNotificationButton(
                  icon: Icon(Icons.people),
                  amount: this._details.curOngoingMeetings,
                  color: this._details.color,
                  onPressed: () => print("Meetings"),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text(
            "Assignments",
            style: TextStyle(color: this._details.color, fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Card(
            child: ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) => _buildAssignmentTile(index),
              itemCount:
                  this._details.assignments.length == 0 ? 1 : this._details.assignments.length,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlmostWhite,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: this._details.color,
        elevation: 0,
        title: Text(this._details.name),
      ),
      body: _buildView(),
    );
  }
}

class CoursesView extends StatefulWidget {
  InfoHandler info;
  CoursesView({@required this.info});

  @override
  _CoursesViewState createState() => _CoursesViewState(this.info);
}

class _CoursesViewState extends State<CoursesView> {
  List<CourseInfo> _courses = [];
  CanvasApi _canvasApi;
  InfoHandler _info;
  int _userId;
  bool _loading = true;

  _CoursesViewState(InfoHandler info) {
    this._info = info;
    _canvasApi = CanvasApi(info);
    update();
  }

  void _parseAndSetCourseInfo(List<dynamic> data) {
    this._courses.clear();

    for (Map<String, dynamic> course in data) {
      // This test filters away all the non-course courses like, canvas help etc.
      if ((course["name"] as String).contains(" - ")) {
        String name = (course["name"] as String).split(" - ")[0];
        print("$name ${course["id"]}");

        CourseInfo obj = CourseInfo(name: name, id: course["id"]);

        // Retrieve the assignment information
        this._canvasApi.request(apiUrl: "api/v1/courses/${course["id"]}/assignments").then((res) {
          for (Map<String, dynamic> assignment in res) {
            // Note that the assignment object does it's own parsing
            obj.assignments.add(Assignment(assignment));
          }
        });

        this._courses.add(obj);
      }
    }
  }

  void _addExtraCourseInfo(List<dynamic> data) {
    for (Map<String, dynamic> course in data) {
      try {
        CourseInfo info = this._courses.firstWhere((e) => e.id == course["id"]);
        info.imageUrl = course["image"];
      } catch (StateError) {
        continue;
      }
    }
  }

  void _addCourseColorInfo(Map<String, dynamic> data) {
    // The data returned here from the api is in the form of:
    // "course_<id>": "#afbecd"
    for (String key in data["custom_colors"].keys) {
      if (key.startsWith("course_")) {
        int id = int.parse(key.substring(key.indexOf("_") + 1));

        try {
          CourseInfo info = this._courses.firstWhere((e) => e.id == id);
          info.color = Color(int.parse('ff' + data["custom_colors"][key].substring(1), radix: 16));
        } catch (StateError) {
          continue;
        }
      }
    }
  }

  void update() async {
    this._loading = true;
    var res = await this._canvasApi.request(apiUrl: "api/v1/courses");

    // if the widget is not visible anymore, just return and do not try to update state
    if (!this.mounted) return;

    setState(() {
      // We use the same hack here that we have used for a few other thing
      // in this codebase. When we are loading or have an error like here,
      // we don't just leave the list empty, we add a text item that says
      // something to give the user an indication that something went wrong.
      // But to do so we need to activate the listview.builder and thus we
      // need to add a dummy item.

      if (res is Map<String, dynamic> && res.containsKey("errors")) {
        this._courses = [];
        this._loading = false;
      } else
        _parseAndSetCourseInfo(res);
    });

    // If there were no courses found, we assume we had an error.
    // TODO: it is perfectly possible the user has no courses, valve pls fix
    if (this._courses.isEmpty) {
      return;
    }

    // We capture the user id for later which apperantly is also passed
    this._userId = res[0]["enrollments"][0]["user_id"];

    for (CourseInfo course in this._courses) {
      this
          ._canvasApi
          .request(apiUrl: "api/v1/courses/${course.id}/activity_stream/summary")
          .then((res) {
        if (!this.mounted) return;

        setState(() {
          for (Map<String, dynamic> activity in res) {
            if (activity["type"] == "Announcement") {
              course.unreadAnnouncements = activity["unread_count"];
            } else if (activity["type"] == "Discussion") {
              course.unreadAnnouncements = activity["unread_count"];
            }
            // TODO: more than just the activities, check discussiontopics and webconferences too.
          }
        });
      });
    }

    this._canvasApi.request(apiUrl: "api/v1/dashboard/dashboard_cards").then((res) {
      if (!this.mounted) return;
      setState(() {
        _addExtraCourseInfo(res);
      });
    });

    print(this._userId);
    this._canvasApi.request(apiUrl: "api/v1/users/${this._userId}/colors").then((res) {
      if (!this.mounted) return;
      setState(() {
        _addCourseColorInfo(res);
      });
    });

    this._loading = false;
  }

  Widget _buildErrorWidget() {
    if (this._loading)
      return Center(
        child: Container(
            margin: EdgeInsets.all(8), child: CircularProgressIndicator(), width: 50, height: 50),
      );

    if (this._courses.isEmpty)
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Your canvas authentication key does not seem to be valid. Please check Settings > Accounts if you want to view course information.",
            style: TextStyle(fontSize: 18),
            softWrap: true,
            textAlign: TextAlign.center,
          ),
        ),
      );

    return Text("You should not be seeing this please contact the developers");
  }

  Widget _buildCourseTile(BuildContext context, int index) {
    List<Widget> widgets = [Container(color: this._courses[index].color.withAlpha(153))];
    if (this._courses[index].imageUrl != null) {
      widgets.insert(0, Image.network(this._courses[index].imageUrl));
    }

    // This here is a hack and there has to be a better way
    // We add two containers and leave one blank to 'fill empty space' but idk
    // man, it seems weird.
    widgets.add(Column(
      children: [
        Expanded(flex: 5, child: Container()),
        Expanded(
          flex: 4,
          child: Container(
            alignment: Alignment.topLeft,
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                child: Text(
                  this._courses[index].name,
                  textAlign: TextAlign.left,
                  style: TextStyle(color: this._courses[index].color, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
            ),
          ),
        ),
      ],
    ));

    return InkResponse(
      child: GridTile(
        child: Card(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: widgets,
            ),
          ),
        ),
      ),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => CourseDetails(details: this._courses[index]),
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    //return ListView.builder(
    //  itemBuilder: (BuildContext context, int index) => _buildCourseTile(index),
    //  itemCount: this._courses.length,
    //);

    if (this._courses.length == 0) {
      return _buildErrorWidget();
    }

    return GridView.builder(
      itemBuilder: (BuildContext context, int index) => _buildCourseTile(context, index),
      itemCount: this._courses.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      padding: EdgeInsets.all(5),
    );
  }
}
