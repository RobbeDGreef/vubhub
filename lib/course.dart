import 'package:flutter/material.dart';

import 'event.dart';

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

class Announcement {
  String title;
  String message;
  DateTime created;
  bool isRead;

  Announcement(Map<String, dynamic> data) {
    this.title = data["title"];
    this.message = data["message"];
    this.created = DateTime.parse(data["posted_at"]);
    this.isRead = data["read_state"] == "read";
  }
}

class Course {
  String name;
  String imageUrl;
  int id;
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
}
