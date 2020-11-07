import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../canvas/canvasapi.dart';
import '../canvas/canvasobjects.dart';
import '../const.dart';
import 'announcements.dart';
import 'assignments.dart';
import 'fileview.dart';
import 'meetings.dart';
import 'modules.dart';
import 'notificationcounter.dart';
import 'pagedetails.dart';
import 'pages.dart';

class CourseMenu extends StatelessWidget {
  Course _details;
  CanvasApi _canvas;
  Future<dynamic> _externalTools;

  CourseMenu(Course details, CanvasApi canvas) {
    this._details = details;
    this._canvas = canvas;

    _externalTools = _getExternalTools();
  }

  Future<List<dynamic>> _getExternalTools() async {
    List<dynamic> data = await this._canvas.get(
        'api/v1/courses/${this._details.id}/external_tools?include_parents=true&selectable=true');

    print(await this._canvas.get('api/v1/accounts/self/external_tools'));
    return data;
  }

  Widget _buildCourseToolTile({Icon icon, int amount = 0, String text, Function() onTap}) {
    return Card(
      child: ListTile(
        title: Text(text),
        leading: icon,
        onTap: onTap,
        trailing: amount == 0 ? null : NotificationCounter(this._details.color, amount),
      ),
    );
  }

  void _pushView(BuildContext context, Widget Function() f) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => f()));
  }

  Widget _buildCourseTools(BuildContext context) {
    return ListView(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        _buildCourseToolTile(
          icon: Icon(Icons.campaign),
          amount: this._details.unreadAnnouncementCount,
          text: "Announcements",
          onTap: () => _pushView(context, () => Announcements(this._details, this._canvas)),
        ),
        _buildCourseToolTile(
          icon: Icon(Icons.assignment),
          amount: this._details.dueAssignments,
          text: "Assignments",
          onTap: () => _pushView(context, () => Assignments(this._details, this._canvas)),
        ),
        _buildCourseToolTile(
            icon: Icon(Icons.computer),
            amount: this._details.curOngoingMeetings,
            text: "Meetings",
            onTap: () =>
                _pushView(context, () => Meetings(details: this._details, canvas: this._canvas))),
        _buildCourseToolTile(
          icon: Icon(Icons.view_list),
          text: "Modules",
          onTap: () => _pushView(context, () => Modules(this._details, this._canvas)),
        ),
        _buildCourseToolTile(
          icon: Icon(Icons.folder),
          text: "Files",
          onTap: () => _pushView(context, () => FilesView(this._details, this._canvas)),
        ),
        _buildCourseToolTile(
          icon: Icon(Icons.campaign),
          text: "Pages",
          onTap: () => _pushView(context, () => PagesView(this._details, this._canvas)),
        ),
        // TODO: syllabus
        /*
        _buildCourseToolTile(
          icon: Icon(Icons.list_alt),
          text: "Syllabus",
        ),
        */
      ],
    );
  }

  List<Widget> _parseExternals(List<dynamic> data, BuildContext context) {
    List<Widget> externals = [];
    for (var e in data) {
      String name = e['name'];
      int id = e['id'];

      if (e['course_navigation'] != null) {
        name = e['course_navigation']['name'] ?? name;
      }

      externals.add(
        _buildCourseToolTile(
          icon: Icon(Icons.input),
          text: e['name'],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return Scaffold(
                  appBar: AppBar(title: Text(name), backgroundColor: this._details.color),
                  body: InAppWebView(
                    initialHeaders: {'Authorization': 'Bearer ${this._canvas.accessToken}'},
                    initialUrl: CanvasUrl +
                        'courses/${this._details.id}/external_tools/$id?access_token=${this._canvas.accessToken}',
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
    return externals;
  }

  Widget _buildExternalTools() {
    return FutureBuilder(
      future: this._externalTools,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: _parseExternals(snapshot.data, context),
          );
        }
        return Center(
          child: Container(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Course Menu"),
        backgroundColor: this._details.color,
      ),
      body: ListView(
        padding: EdgeInsets.all(8),
        children: [
          Text(
            "Course items",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: this._details.color,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 16, bottom: 16),
            child: _buildCourseTools(context),
          ),
          Text(
            "External tools",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: this._details.color,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 16, bottom: 16),
            child: _buildExternalTools(),
          ),
        ],
      ),
    );
  }
}

class CourseMenuQuick extends StatelessWidget {
  Course _details;
  BuildContext context;
  CanvasApi _canvas;

  CourseMenuQuick(Course details, CanvasApi canvas) {
    this._details = details;
    this._canvas = canvas;
  }

  void _pushView(Widget Function() builder) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => builder()));
  }

  /// Build the quick menu button
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
        padding: EdgeInsets.all(0),
      )
    ];

    if (amount != 0) {
      children.add(
        Positioned(
          right: 0,
          child: NotificationCounter(this._details.color, amount),
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

  void _buildAnnouncements() {
    _pushView(() => Announcements(this._details, this._canvas));
  }

  void _buildAssignments() {
    _pushView(() => Assignments(this._details, this._canvas));
  }

  void _buildMeetings() {
    _pushView(() => Meetings(details: this._details, canvas: this._canvas));
  }

  void _buildModules() {
    _pushView(() => Modules(this._details, this._canvas));
  }

  void _buildAll() {
    _pushView(() => CourseMenu(this._details, this._canvas));
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    return Row(
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
        _buildNotificationButton(
          icon: Icon(Icons.arrow_forward),
          amount: 0,
          color: this._details.color,
          onPressed: _buildAll,
        ),
      ],
    );
  }
}
