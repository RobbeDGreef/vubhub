import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../canvas/canvasapi.dart';
import '../canvas/canvasobjects.dart';
import '../htmlParser.dart';
import 'pagedetails.dart';

class AnnouncementView extends StatelessWidget {
  Announcement _announcement;
  Course _details;
  CanvasApi _canvas;

  AnnouncementView(Announcement ann, Course details, CanvasApi canvas) {
    this._details = details;
    this._announcement = ann;
    this._canvas = canvas;
  }

  @override
  Widget build(BuildContext context) {
    this
        ._canvas
        .put('api/v1/courses/${this._details.id}/discussion_topics/${this._announcement.id}/read');

    Widget avatar = Center(child: Icon(Icons.person));
    try {
      avatar = Image.network(_announcement.author.avatarUrl);
    } catch (e) {}

    return Scaffold(
      appBar: AppBar(
        backgroundColor: this._details.color,
        title: Text(
          this._announcement.title,
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
                    Text(DateFormat("d MMMM H:mm").format(this._announcement.created)),
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
              child: htmlParse(this._announcement.message),
            ),
          ),
        ],
      ),
    );
  }
}

class Announcements extends StatelessWidget {
  CanvasApi _canvas;
  Course _details;

  Announcements(Course details, CanvasApi canvas) {
    this._canvas = canvas;
    this._details = details;
  }

  @override
  Widget build(BuildContext context) {
    return PageDetails(
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
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => AnnouncementView(ann, this._details, this._canvas)));
            },
          ),
        );
      },
      getData: () async {
        List<Announcement> announcements = [];
        List<dynamic> res = await this._canvas.get(
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
    );
  }
}
