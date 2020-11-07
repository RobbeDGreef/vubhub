import 'package:flutter/material.dart';

import '../event.dart';
import '../const.dart';

class Assignment {
  String name;
  String details;
  DateTime dueDate;
  bool hasSubmitted;
  double gradeLimit;
  String submissionDownloadUrl;
  List<dynamic> submissionTypes;

  void _renameSubmissionTypes() {
    for (int i = 0; i < this.submissionTypes.length; i++) {
      this.submissionTypes[i] = this.submissionTypes[i].replaceAll('_', ' ');
      this.submissionTypes[i] =
          '${this.submissionTypes[i][0].toUpperCase()}${this.submissionTypes[i].substring(1)}';
    }
  }

  Assignment(Map<String, dynamic> data) {
    this.name = data["name"];
    this.details = data["description"];
    this.gradeLimit = data['points_possible'];
    this.submissionDownloadUrl = data['submissions_download_url'];
    this.submissionTypes = data['submission_types'];

    if (data['submission'] == null || data['submission']['attempt'] == null)
      this.hasSubmitted = false;
    else {
      this.hasSubmitted = true;
      print(data['submission']['attempt']);
    }
    if (data['due_at'] != null) {
      this.dueDate = DateTime.parse(data["due_at"]);
    }

    _renameSubmissionTypes();
  }
}

class Discussion {}

class CourseEvent extends Event {
  String reserveUrl;
  String url;
  bool hasAlreadyReserved;
  CourseEvent reservation;

  CourseEvent(Map<String, dynamic> data) : super.empty() {
    this.name = data['title'];
    this.details = data["description"];
    this.startDate = DateTime.parse(data["start_at"]);
    this.endDate = DateTime.parse(data["end_at"]);
    this.location = data["location_name"];
    this.reserveUrl = data["reserve_url"];
    this.hasAlreadyReserved = data["reserved"];
    this.url = data["url"];

    // TODO: one might have multiple reservations ?
    if (data["child_events"] != null && (data["child_events"] as List<dynamic>).isNotEmpty) {
      this.reservation = CourseEvent(data["child_events"][0]);
    }

    if ((data["context_code"] as String).startsWith("course_")) {
      this.courseId = int.parse((data["context_code"] as String).substring(7));
    }
  }
}

class Author {
  String name;
  String avatarUrl;

  Author(Map<String, dynamic> data) {
    this.name = data["display_name"];
    this.avatarUrl = data["avatar_image_url"];
  }
}

class Announcement {
  String title;
  String message;
  DateTime created;
  bool isRead;
  Author author;
  int id;

  Announcement(Map<String, dynamic> data) {
    this.title = data["title"];
    this.message = data["message"];
    this.isRead = data["read_state"] == "read";
    this.author = Author(data["author"]);
    this.id = data['id'];

    if (data['posted_at'] != null) {
      this.created = DateTime.parse(data["posted_at"]);
    }
  }
}

class Course {
  String name = '';
  String imageUrl = '';
  int id = -1;
  Color color = Colors.grey;
  List<Assignment> assignments = [];
  List<Discussion> discussions = [];
  List<CourseEvent> events = [];
  int unreadAnnouncementCount = 0;
  int dueAssignments = 0;
  int unreadDiscussions = 0;
  int curOngoingMeetings = 0;

  Course.empty();
  Course({this.name, this.id});

  static final int stringListSize = 4;

  String toString() {
    List<String> data = [];
    print("name: $name, imageurl: $imageUrl, id: $id, color: ${color.value}");
    data.add(this.name);
    data.add(this.imageUrl.toString());
    data.add(this.id.toString());
    data.add(this.color.value.toString());

    for (int i = 0; i < data.length; i++) {
      data[i] = data[i].split('\n').join('\\n');
    }

    return data.join('\n');
  }

  Course.fromStringList(List<String> data) {
    this.name = data[0];
    this.imageUrl = data[1];
    this.id = int.parse(data[2]);
    this.color = Color(int.parse(data[3]));

    // The rest of the data is currently not stored to disk.
  }
}

class Recording {
  String title;
  int duration;
  String url;

  Recording(Map<String, dynamic> data) {
    this.title = data['title'];
    this.duration = data['duration_minutes'];
    // TODO: this is a bit of a hack, normally the second item in the list of playback formats is of type 'video' so we are going to assume that this is correct
    this.url = data['playback_formats'][1]['url'];
  }
}

class Meeting {
  int id;
  String title;
  String details;
  DateTime started;
  DateTime ended;
  String url;
  List<Recording> recordings = [];

  Meeting(Map<String, dynamic> data) {
    this.title = data["title"];
    this.details = data["description"];
    this.id = data['id'];

    // Can only join url if the meeting is ongoing
    if (data['ended_at'] == null) {
      this.url = CanvasUrl + data["url"] + '/join'; // or just url ?
    }

    if (data['ended_at'] != null) {
      this.ended = DateTime.parse(data["ended_at"]);
    }
    if (data['started_at'] != null) {
      this.started = DateTime.parse(data["started_at"]);
    }

    if (data['recordings'] != null) {
      for (var rec in data['recordings']) {
        recordings.add(Recording(rec));
      }
    }
  }
}

class ModuleItem {
  String title;
  int indent;
  String url;
  String type;
  Icon icon;

  ModuleItem(Map<String, dynamic> data) {
    this.title = data['title'];
    this.indent = data['indent'];
    this.type = data['type'];
    if (type == 'ExternalUrl') {
      icon = Icon(Icons.link);
      this.url = data['external_url'];
    } else if (type == 'File') {
      icon = Icon(Icons.attach_file);
      this.url = data['url'];
    } else {
      icon = Icon(Icons.filter_none);
      this.url = data['html_url'];
    }
  }
}

class Module {
  String title;
  List<ModuleItem> items = [];

  Module(Map<String, dynamic> data) {
    this.title = data['name'];

    if (data['items'] != null) {
      for (var el in data['items']) {
        items.add(ModuleItem(el));
      }
    }
  }
}

class CanvasFile {
  String name;
  String contentType;
  String url;

  DateTime updated;

  // In bytes
  int size;

  CanvasFile(Map<String, dynamic> file) {
    this.name = file['filename'];
    this.contentType = file['content-type'];
    this.url = file['url'];
    this.size = file['size'];

    if (file['updated_at'] != null) {
      updated = DateTime.parse(file['updated_at']);
    }
  }
}

class CanvasPage {
  String name;
  String url;

  DateTime created;
  String body;

  CanvasPage(Map<String, dynamic> page) {
    this.name = page['title'];
    this.url = page['url'];
    this.body = page['body'];

    if (page['created_at'] != null) {
      this.created = DateTime.parse(page['created_at']);
    }
  }
}
