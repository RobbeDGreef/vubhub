import 'package:flutter/material.dart';
import 'package:quiver/core.dart';

class Event {
  String name = "";
  String details = "";
  String remarks = "";
  DateTime startDate;
  DateTime endDate;
  String location = "";
  String host = "";
  int courseId = -1;
  Color customColor = Colors.grey;

  int eventType = 0;

  static final int stringListSize = 10;

  Event();
  Event.empty();

  Event.fromStringList(List<String> data) {
    this.name = data[0];
    this.details = data[1];
    this.remarks = data[2];
    this.startDate = DateTime.parse(data[3]);
    this.endDate = DateTime.parse(data[4]);
    this.location = data[5];
    this.host = data[6];
    this.courseId = int.parse(data[7]);
    this.customColor = Color(int.parse(data[8]));
    this.eventType = int.parse(data[9]);
  }

  String toString() {
    List<String> data = [];

    data.add(this.name);
    data.add(this.details);
    data.add(this.remarks);
    data.add(this.startDate.toString());
    data.add(this.endDate.toString());
    data.add(this.location);
    data.add(this.host);
    data.add(this.courseId.toString());
    data.add(this.customColor.value.toString());
    data.add(this.eventType.toString());

    // This is just to make sure that every string
    // takes up exactly one line.
    int i = 0;
    for (String s in data) {
      data[i] = s.split('\n').join('\\n');
      i++;
    }

    return data.join('\n');
  }

  // TODO: is there really no better way ????
  Event.from(Event toCopy) {
    this.name = toCopy.name;
    this.details = toCopy.details;
    this.remarks = toCopy.remarks;
    this.startDate = toCopy.startDate;
    this.endDate = toCopy.endDate;
    this.location = toCopy.location;
    this.host = toCopy.host;
    this.courseId = toCopy.courseId;
    this.customColor = toCopy.customColor;
    this.eventType = toCopy.eventType;
  }

  @override
  int get hashCode {
    // TODO: I don't know if this is a great idea.
    return this.name.hashCode ^
        this.startDate.hashCode ^
        this.endDate.hashCode ^
        this.location.hashCode ^
        this.host.hashCode ^
        this.remarks.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (!(other is Event)) return false;

    Event event = other;
    if (this.name == event.name &&
        this.startDate == event.startDate &&
        this.endDate == event.endDate &&
        this.location == event.location &&
        this.host == event.host &&
        this.remarks == event.remarks) return true;
    return false;
  }
}
