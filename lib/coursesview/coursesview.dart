import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../canvas/canvasapi.dart';
import '../canvas/canvasobjects.dart';

import '../infohandler.dart';
import '../theming.dart';
import '../htmlParser.dart';
import '../const.dart';

import 'fileview.dart';
import 'meetings.dart';
import 'pagedetails.dart';

// TODO: this file is too large, CourseDetails class is too large, split up stuff like PageView() into seperate classes and files

class CourseDetails extends StatefulWidget {
  final Course details;
  final CanvasApi canvas;

  CourseDetails({this.details, this.canvas});

  @override
  _CourseDetailsState createState() => _CourseDetailsState(this.details, this.canvas);
}

class _CourseDetailsState extends State<CourseDetails> {
  Course _details;
  List<Announcement> _unreadAnnouncements = [];
  bool _loadingUnreadAnnouncements = true;

  _CourseDetailsState(Course details, canvas) {
    this._details = details;

    canvas
        .get(
            'api/v1/courses/${this._details.id}/discussion_topics?only_announcements=true&per_page=99999&filter_by=unread')
        .then((ret) {
      setState(() {
        for (var data in ret) {
          var ann = Announcement(data);
          if (ann.created != null) {
            this._unreadAnnouncements.add(ann);
          }
        }
        this._loadingUnreadAnnouncements = false;
      });
    });
  }

  int _calcUpcomingEvents() {
    // TODO: take the first 5 upcomming events or something.
    if (this._details.events.length != 0)
      return this._details.events.length;
    else
      return null;
  }

  int _calcUpcomingAssignments() {
    if (this._details.assignments.length != 0)
      return this._details.assignments.length;
    else
      return null;
  }

  int _calcUpcomingAnnouncements() {
    if (this._unreadAnnouncements.length != 0)
      return this._unreadAnnouncements.length;
    else
      return null;
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

  Future<http.Response> _sendPostToEventUrl(String url, String body) {
    // TODO: implement this using canvas api
    // It's okay for comments to be empty
    Map<String, String> headers = {
      "host": "canvas.vub.be",
      "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
      "connection": "close",
      "content-length": body.length.toString(),
      "authorization": "Bearer " + this.widget.canvas.accessToken,
    };

    print(url);
    print(headers);
    print(body);
    return http.post(url, headers: headers, body: body);
  }

  // TODO: this is terrible code reuse (no code reuse)
  void _cancelEvent(int index, String reason) async {
    Navigator.pop(context);

    String title = "Success";
    String subtitle = "Successfully cancelled your reservation.";
    if (this._details.events[index].reservation == null) {
      title = "Failure";
      subtitle = "We cannot find the link to your registration.";
    } else {
      var res = await _sendPostToEventUrl(this._details.events[index].reservation.url,
          "cancel_reason=" + reason + "&_method=DELETE");

      if (res.statusCode != 200) {
        print(res.statusCode);
        print(res.body);
        title = "Failure";
        subtitle = "Something went wrong while trying to cancel your reservation.";
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(title),
          contentPadding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
          children: [
            Text(subtitle),
            TextButton(
              child: Text("close"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );

    // TODO: update the event data on close.
  }

  void _reserveEvent(int index, String comments) async {
    Navigator.pop(context);

    var res = await _sendPostToEventUrl(
        this._details.events[index].reserveUrl, "comments=" + comments + "&_method=POST");

    String title = "Success";
    String subtitle = "Successfully made a reservation.";

    if (res.statusCode == 400) {
      title = "Failure";
      subtitle = "Something went wrong while trying to make a reservation.";
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(title),
          contentPadding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
          children: [
            Text(subtitle),
            TextButton(
              child: Text("close"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  void _viewEvent(int index) {
    String time = DateFormat("d MMMM 'from' hh:mm ").format(this._details.events[index].startDate) +
        DateFormat("'until' hh:mm").format(this._details.events[index].endDate);

    List<Widget> children = [
      Text(time),
      Text("At " + this._details.events[index].location),
      Divider(),
      Text(this._details.events[index].details),
    ];

    Row buttons = Row(
      children: [
        TextButton(
          child: Text("close"),
          onPressed: () => Navigator.pop(context),
        ),
      ],
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    );
    if (this._details.events[index].reserveUrl != null) {
      if (this._details.events[index].hasAlreadyReserved)
        buttons.children.add(TextButton(
          child: Text("cancel reservation"),
          onPressed: () => _cancelEvent(index, ""),
        ));
      else
        buttons.children.add(TextButton(
          child: Text("reserve"),
          onPressed: () => _reserveEvent(index, ""),
        ));
    }
    children.add(buttons);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(this._details.events[index].name),
          contentPadding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
          children: children,
        );
      },
    );
  }

  Widget _buildListTile(String title, String subtitle, String empty, Icon icon, Function() onTap) {
    /// Will return the contents of the empty string if
    /// the string is not equal to null
    if (empty != null) {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          empty,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: icon,
      onTap: onTap,
    );
  }

  Widget _buildAssignmentTile(int index) {
    /// Will return "You currently have no assignments for this course." if
    /// the assignments list of the coursedetails is empty.
    if (this._details.assignments.isEmpty) {
      return _buildListTile(
          null, null, "You currently have no assignments for this course.", null, null);
    }

    final icon = this._details.assignments[index].hasSubmitted
        ? Icon(Icons.check_circle, color: Colors.green)
        : Icon(Icons.clear, color: Colors.red);

    String dueString = "Could not find the due date.";
    if (this._details.assignments[index].dueDate != null) {
      dueString =
          "Due at ${DateFormat("d MMMM y").format(this._details.assignments[index].dueDate)}";
    }
    return _buildListTile(
      this._details.assignments[index].name,
      dueString,
      null,
      icon,
      () => _pushView(() => _buildAssignmentView(this._details.assignments[index])),
    );
  }

  Widget _buildAnnouncementTile(int index) {
    print("build build");
    if (this._loadingUnreadAnnouncements) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
          width: 50,
          height: 50,
        ),
      );
    }

    /// Will return "You currently have no assignments for this course." if
    /// the assignments list of the coursedetails is empty.
    if (this._unreadAnnouncements.isEmpty) {
      return _buildListTile(null, null, "You have no unread announcements.", null, null);
    }

    Announcement ann = this._unreadAnnouncements[index];
    final icon = Icon(Icons.campaign);
    String date = "Could not find the posted date";
    if (ann.created != null) {
      date = DateFormat("d MMMM H:mm").format(ann.created);
    }
    return _buildListTile(
      ann.title,
      date,
      null,
      icon,
      () => _pushView(() => _buildAnnouncementView(ann)),
    );
  }

  Widget _buildEventTile(int index) {
    /// Will return "You have no upcoming events for this course." if
    /// the event list is empty.
    if (this._details.events.isEmpty) {
      return _buildListTile(null, null, "You have no upcoming events for this course.", null, null);
    }

    final icon = Icon(Icons.event);

    final startDate = this._details.events[index].startDate;
    final endDate = this._details.events[index].endDate;

    // TODO: events could be longer then a day
    return _buildListTile(
      this._details.events[index].name,
      "${DateFormat("d MMMM").format(startDate)} from ${DateFormat.Hm().format(startDate)} until ${DateFormat.Hm().format(endDate)}",
      null,
      icon,
      () => _viewEvent(index),
    );
  }

  void _pushView(Widget Function() builder) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return builder();
    }));
  }

  Widget _buildAnnouncementView(Announcement ann) {
    this
        .widget
        .canvas
        .put('api/v1/courses/${this._details.id}/discussion_topics/${ann.id}/read')
        .then((_) {
      setState(() {
        ann.isRead = true;
      });
    });

    Image avatar = Image.network(ann.author.avatarUrl);
    //print(ann.message);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: this._details.color,
        title: Text(
          ann.title,
          overflow: TextOverflow.fade,
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  clipBehavior: Clip.hardEdge,
                  child: avatar,
                  decoration: BoxDecoration(shape: BoxShape.circle),
                  width: 50,
                  height: 50,
                ),
                SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ann.author.name, style: TextStyle(fontSize: 18)),
                    Text(DateFormat("d MMMM H:mm").format(ann.created)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(5),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: htmlParse(ann.message),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentView(Assignment assignment) {
    return Scaffold(
      appBar: AppBar(
        title: Text(assignment.name),
        backgroundColor: this._details.color,
      ),
      body: ListView(
        padding: EdgeInsets.only(left: 16, right: 16, top: 20),
        children: [
          Text(assignment.name, style: TextStyle(fontSize: 25)),
          Row(
            children: [
              assignment.hasSubmitted
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : Icon(Icons.clear, color: Colors.red),
              SizedBox(width: 5),
              assignment.hasSubmitted
                  ? Text("Submitted", style: TextStyle(color: Colors.green))
                  : Text("Nothing submitted", style: TextStyle(color: Colors.red)),
              SizedBox(width: 10),
              Text('${assignment.gradeLimit.truncate()} marks')
            ],
          ),
          Divider(),
          Row(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Due at", style: TextStyle(fontSize: 17)),
                Text("Submission types", style: TextStyle(fontSize: 17)),
              ],
            ),
            SizedBox(width: 25),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat("d MMMM H:mm").format(assignment.dueDate),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                Text(assignment.submissionTypes.join(', '),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
              ],
            ),
          ]),
          Divider(),
          htmlParse(assignment.details),
        ],
      ),
    );
  }

  void _buildAnnouncements() {
    _pushView(
      () => PageDetails(
        title: "Announcements",
        color: this._details.color,
        buildTile: (BuildContext context, dynamic announcement) {
          Announcement ann = announcement;
          return Card(
            child: ListTile(
              leading: Icon(Icons.campaign),
              trailing: !ann.isRead
                  ? Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.brightness_1, size: 12, color: this._details.color),
                    )
                  : null,
              title: Text(ann.title),
              subtitle: Text(DateFormat("d MMMM H:mm").format(ann.created)),
              onTap: () {
                _pushView(() => _buildAnnouncementView(ann));
              },
            ),
          );
        },
        getData: () async {
          List<Announcement> announcements = [];
          List<dynamic> res = await this.widget.canvas.get(
              "api/v1/courses/${this._details.id}/discussion_topics?only_announcements=true&per_page=99999");
          for (Map<String, dynamic> announcement in res) {
            var ann = Announcement(announcement);

            // Canvas for some reason shows the announcements of the previous year but sets the
            // dates to null.
            if (ann.created != null) {
              announcements.add(ann);
            }
          }

          return announcements;
        },
        noDataText: "There are currently no announcements for this course",
      ),
    );
  }

  void _buildAssignments() {
    _pushView(
      () => PageDetails(
        title: "Assignments",
        color: this._details.color,
        buildTile: (BuildContext context, dynamic assignment) {
          Assignment assign = assignment;
          return Card(
            child: ListTile(
              leading: Icon(Icons.campaign),
              trailing: Padding(
                padding: EdgeInsets.all(8),
                child: assign.hasSubmitted
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : Icon(Icons.clear, color: Colors.red),
              ),
              title: Text(assign.name),
              subtitle: Text(DateFormat("d MMMM H:mm").format(assign.dueDate)),
              onTap: () => _pushView(() => _buildAssignmentView(assign)),
            ),
          );
        },
        getData: () => this._details.assignments,
        noDataText: "There are currently no assignments for this course",
      ),
    );
  }

  void _buildMeetings() {
    _pushView(() => Meetings(details: this._details, canvas: this.widget.canvas));
  }

  void _launchChat() {
    _pushView(() {
      return Scaffold(
        appBar: AppBar(title: Text("Chat"), backgroundColor: this._details.color),
        body: WebView(
          initialUrl: CanvasUrl + "courses/${this._details.id}/external_tools/6",
          javascriptMode: JavascriptMode.unrestricted,
        ),
      );
    });
  }

  Future<List<dynamic>> _getAllModuleItems() async {
    List<dynamic> modules = [];

    int i = 1;
    while (true) {
      print(i);
      List<dynamic> mods = await this
          .widget
          .canvas
          .get('api/v1/courses/${this._details.id}/modules?page=$i&include=items');

      modules.addAll(mods);

      if (mods.isEmpty) break;
      i++;
    }

    return modules;
  }

  void _buildModules() {
    _pushView(
      () => PageDetails(
        title: "Modules",
        color: this._details.color,
        getData: () async {
          List<Module> modules = [];
          print("${this._details.id} ${this.widget.canvas.accessToken}");

          var resp = await _getAllModuleItems();

          for (var mod in resp) {
            modules.add(Module(mod));
          }

          return modules;
        },
        buildTile: (_, mod) {
          Module module = mod;
          return Theme(
            data: ThemeData(accentColor: this._details.color),
            child: ExpansionTile(
              title: Text(module.title),
              initiallyExpanded: true,
              children: module.items.map((e) {
                return Column(
                  children: [
                    Divider(),
                    Row(
                      children: [
                        SizedBox(width: e.indent * 30.0),
                        Expanded(
                          child: ListTile(
                            title: Text(e.title),
                            leading: e.icon,
                            onTap: () {
                              Widget widget;
                              if (e.type == 'File') {
                                widget = FileView(e.url, this.widget.canvas);
                              } else {
                                widget = WebView(
                                    initialUrl: e.url, javascriptMode: JavascriptMode.unrestricted);
                              }
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                      appBar: AppBar(
                                          title: Text(e.title),
                                          backgroundColor: this._details.color),
                                      body: widget),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
        noDataText: "There are no modules for this course",
      ),
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

    Widget img;
    try {
      if (this._details.imageUrl != null) {
        img = Image.network(this._details.imageUrl, fit: BoxFit.fitWidth);
      }
    } catch (HttpException) {}

    return ListView(
      children: [
        Stack(children: [
          SizedBox(
            width: width,
            height: height,
            child: img,
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
                  amount: this._details.unreadAnnouncementCount,
                  color: this._details.color,
                  onPressed: _buildAnnouncements,
                ),
                _buildNotificationButton(
                  icon: Icon(Icons.assignment),
                  amount: this._details.dueAssignments,
                  color: this._details.color,
                  onPressed: _buildAssignments,
                ),
                _buildNotificationButton(
                  icon: Icon(Icons.question_answer),
                  amount: 0,
                  color: this._details.color,
                  onPressed: _launchChat,
                ),
                _buildNotificationButton(
                  icon: Icon(Icons.computer),
                  amount: this._details.curOngoingMeetings,
                  color: this._details.color,
                  onPressed: _buildMeetings,
                ),
                _buildNotificationButton(
                  icon: Icon(Icons.view_list),
                  amount: 0,
                  color: this._details.color,
                  onPressed: _buildModules,
                ),
              ],
            ),
          ),
        ),

        // TODO: these should probably go into a generic _buildCourseSection function
        Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text(
            "Upcoming due assignments",
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
              itemCount: _calcUpcomingAssignments() ?? 1,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text(
            "Unread announcements",
            style: TextStyle(color: this._details.color, fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Card(
            child: ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) => _buildAnnouncementTile(index),
              itemCount: _calcUpcomingAnnouncements() ?? 1,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text(
            "Upcoming events",
            style: TextStyle(color: this._details.color, fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Card(
            child: ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) => _buildEventTile(index),
              itemCount: _calcUpcomingEvents() ?? 1,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

  void update() {
    // TODO
  }

  @override
  _CoursesViewState createState() => _CoursesViewState(this.info);
}

class _CoursesViewState extends State<CoursesView> {
  List<Course> _courses = [];
  CanvasApi _canvasApi;
  InfoHandler _info;
  bool _loading = true;

  _CoursesViewState(InfoHandler info) {
    this._info = info;
    if (info.user.accessToken != null) {
      _canvasApi = CanvasApi(info.user.accessToken);
      update();
    } else
      this._loading = false;
  }

  void _parseAndSetCourseInfo(List<dynamic> data) {
    this._courses.clear();

    for (Map<String, dynamic> course in data) {
      // This test filters away all the non-course courses like, canvas help etc.
      print(course["originalName"]);
      if ((course["originalName"] as String).contains(" - ")) {
        String name = (course["originalName"] as String).split(" - ")[0];
        print("$name ${course["id"]}");
        Course obj = Course(name: name, id: course["id"]);
        obj.imageUrl = course["image"];

        // Retrieve the assignment information
        this
            ._canvasApi
            .get("api/v1/courses/${course["id"]}/assignments?include[]=submission")
            .then((res) {
          for (Map<String, dynamic> data in res) {
            // Note that the assignment object does it's own parsing
            var assignment = Assignment(data);
            if (assignment.dueDate != null) {
              obj.assignments.add(assignment);
            }
          }
        });

        this._courses.add(obj);
      }
    }

    this._info.setCourses(this._courses);
  }

  void _addCourseColorInfo(Map<String, dynamic> data) {
    // The data returned here from the api is in the form of:
    // "course_<id>": "#afbecd"
    for (String key in data["custom_colors"].keys) {
      if (key.startsWith("course_")) {
        int id = int.parse(key.substring(key.indexOf("_") + 1));

        try {
          Course info = this._courses.firstWhere((e) => e.id == id);
          info.color = Color(int.parse('ff' + data["custom_colors"][key].substring(1), radix: 16));
        } catch (StateError) {
          continue;
        }
      }
    }
  }

  void update() async {
    this._loading = true;
    var res = await this._canvasApi.get("api/v1/dashboard/dashboard_cards");

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

    // If there were no courses found, we assume we had an error and return.
    // TODO: it is perfectly possible the user has no courses, valve pls fix
    if (this._courses.isEmpty) {
      return;
    }

    for (Course course in this._courses) {
      this._canvasApi.get("api/v1/courses/${course.id}/activity_stream/summary").then((res) {
        if (!this.mounted) return;

        setState(() {
          for (Map<String, dynamic> activity in res) {
            if (activity["type"] == "Announcement") {
              course.unreadAnnouncementCount = activity["unread_count"];
            } else if (activity["type"] == "Discussion") {
              course.unreadAnnouncementCount = activity["unread_count"];
            }
            // TODO: more than just the activities, check discussiontopics and webconferences too.
          }
        });
      });
    }

    this._canvasApi.get("/api/v1/appointment_groups").then((appgroups) {
      if (!this.mounted) return;

      String url = "/api/v1/calendar_events?start_date=";
      url += DateTime.now().toIso8601String();
      url += "&end_date=" + DateTime.now().add(Duration(days: 365)).toIso8601String();

      if (appgroups != null && (appgroups as List<dynamic>).length != 0) {
        url += "&appointment_group_ids=";
        for (Map<String, dynamic> group in appgroups) {
          url += group["id"].toString() + ",";
        }
        url = url.substring(0, url.length - 1);
      }

      if (!this.mounted) return;
      setState(() {
        this._canvasApi.get(url).then((calendarData) {
          for (Map<String, dynamic> eventData in calendarData) {
            CourseEvent event = CourseEvent(eventData);
            for (Course course in this._courses) {
              if (course.id == event.courseId) {
                course.events.add(event);
                break;
              }
            }
          }
        });
      });
    });

    this._canvasApi.get("api/v1/users/self/colors").then((res) {
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
      try {
        widgets.insert(
            0,
            Image.network(
              this._courses[index].imageUrl,
            ));
      } catch (HttpException) {}
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
          builder: (context) =>
              CourseDetails(details: this._courses[index], canvas: this._canvasApi),
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
