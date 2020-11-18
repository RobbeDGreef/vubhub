import 'dart:convert';

import 'package:flutter/material.dart';
import "package:html/parser.dart" as html;
import "event.dart";
import 'canvas/canvasobjects.dart';
import 'infohandler.dart';

/*
/// The iCalendar parser, This is actually obsolete but I leave it in
/// since there is a chance that we might need this parser again for different
/// calendar implementations.
class IcalParser {
  Iterable<String> file;
  int index;
  List<Lecture> parsedList;

  String next() {
    return this.file.elementAt(++this.index);
  }

  /// Parse part of the file into Lecture object (from BEGIN:VEVENT until END:VEVENT)
  Lecture parseEvent() {
    Lecture event = Lecture.empty();

    for (; this.index < this.file.length; ++this.index) {
      String line = this.file.elementAt(this.index);

      if (line.startsWith("END:VEVENT")) {
        break;
      } else if (line.startsWith("SUMMARY")) {
        event.name = line.substring("SUMMARY".length + 1);
        if (event.name[0] == '&') // Rotatiesysteem
          event.name = "Rotatiesysteem: " +
              line
                  .substring(line.indexOf(';', 16) + 1) // TODO magic values are evil
                  .toLowerCase();
      } else if (line.startsWith("DESCRIPTION")) {
        event.details = line.substring("DESCRIPTION".length + 1);
        int indx = line.indexOf("Location:") + 10;
        event.location = line.substring(indx, line.indexOf("\\n", indx));

        indx = line.indexOf("Remarks:") + 9;
        event.remarks = line.substring(indx, line.indexOf("\\n", indx));
      } else if (line.startsWith("DTSTART")) {
        try {
          event.start = DateTime.parse(line.substring(line.indexOf(':') + 1));
        } on FormatException {
          print("errorline start: " + line);
        }
      } else if (line.startsWith("DTEND")) {
        try {
          event.end = DateTime.parse(line.substring(line.indexOf(':') + 1));
        } on FormatException {
          print("Errorline: " + line);
        }
      }
    }

    return event;
  }

  /// Parse the large clump of string into a list of Lecture objects
  List<Lecture> parse(Iterable<String> file) {
    this.parsedList = new List();
    this.file = file;

    for (this.index = 0; this.index < this.file.length; ++this.index) {
      if (file.elementAt(this.index).startsWith("BEGIN:VEVENT")) {
        this.parsedList.add(parseEvent());
      }
    }

    return this.parsedList;
  }

  List<Lecture> reparseSaved(Iterable<String> file) {
    this.parsedList = List();
    this.file = file;

    // TODO: this is bound to go corrupt wtf, fix this.
    for (this.index = 0; this.index < this.file.length; ++this.index) {
      List<String> data = List();
      for (int i = 0; i < 6; ++i) {
        data.add(file.elementAt(this.index + i));
      }
      this.parsedList.add(Lecture.fromString(data));
      this.index += 5;
    }

    return this.parsedList;
  }
}
*/

List<Event> parseLectureList(String data, int week) {
  if (data == null) {
    return [];
  }

  var doc = html.parse(data);

  List<Event> lectures = [];
  // Iterate over every day in the week
  for (var day in doc.getElementsByClassName("TableBody")[0].children[0].children) {
    if (day.children[0].className != "tdCol") continue;

    Event lec = Event.empty();
    lec.name = day.children[0].text;
    lec.host = day.children[1].text;
    lec.location = day.children[6].text;
    lec.remarks = day.children[8].text;
    lec.customColor = Colors.white;

    for (String date in day.children[5].text.split(")")) {
      if (date == "" || int.parse(date.substring(0, date.indexOf(" "))) != week) {
        continue;
      }
      var parts = date.substring(date.indexOf("(") + 1).split("/");
      var toDay = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      lec.startDate = DateTime(
          toDay.year,
          toDay.month,
          toDay.day,
          int.parse(day.children[2].text.split(":")[0]),
          int.parse(day.children[2].text.split(":")[1]));
      lec.endDate = DateTime(
          toDay.year,
          toDay.month,
          toDay.day,
          int.parse(day.children[3].text.split(":")[0]),
          int.parse(day.children[3].text.split(":")[1]));
      lectures.add(Event.from(lec));
    }
  }
  return lectures;
}

List<Event> parseCacheStoredEvents(List<String> data) {
  List<Event> lectures = [];
  for (int i = 0; i < data.length; i += Event.stringListSize) {
    lectures.add(Event.fromStringList(data.sublist(i, i + Event.stringListSize)));
  }
  return lectures;
}

List<Course> parseCacheStoredCourses(List<String> data) {
  List<Course> courses = [];

  for (int i = 0; i < data.length; i += Course.stringListSize) {
    courses.add(Course.fromStringList(data.sublist(i, i + Course.stringListSize)));
  }
  return courses;
}

List<Event> parseStoredEventData(String data) {
  List<Event> events = [];

  List<String> lines = data.split('\n');

  print(lines.length);
  // Strip last line since it will be empty
  lines = lines.sublist(0, lines.length - 1);
  print(lines.length);

  for (int i = 0; i < lines.length; i += Event.stringListSize) {
    print(i);
    events.add(Event.fromStringList(lines.sublist(i, i + Event.stringListSize)));
  }

  return events;
}

String trimUntil(String s, String pat) {
  int i = s.indexOf(pat) + 1;
  return s.substring(i);
}

Map<int, List<Event>> parseIcalToWeekEvents(String ical) {
  Event e = Event.empty();
  Map<int, List<Event>> data = {};

  bool reading = false;
  for (String line in LineSplitter().convert(ical)) {
    if (line.startsWith('BEGIN:VEVENT')) {
      reading = true;
      continue;
    }

    if (reading) {
      if (line.startsWith('SUMMARY')) {
        e.name = trimUntil(line, ':');
      } else if (line.startsWith('DTSTART')) {
        e.startDate = DateTime.parse(trimUntil(line, ':'));
      } else if (line.startsWith('DTEND')) {
        e.endDate = DateTime.parse(trimUntil(line, ':'));
      } else if (line.startsWith('DESCRIPTION')) {
        var description = trimUntil(line, ':').split('\\n\\n');

        for (String item in description) {
          if (item.startsWith('Lokaal')) {
            e.location = trimUntil(item, ':').substring(1);
          } else if (item.startsWith('Docent')) {
            e.host = trimUntil(item, ':').substring(1);
          } else if (item.startsWith('Opmerkingen')) {
            e.remarks = trimUntil(item, ':').substring(1);
          }
        }
      }
    }
    if (line.startsWith('END:VEVENT')) {
      reading = false;
      if (e.startDate != null) {
        if (data[InfoHandler.calcWeekFromDate(e.startDate)] == null)
          data[InfoHandler.calcWeekFromDate(e.startDate)] = [];

        data[InfoHandler.calcWeekFromDate(e.startDate)].add(e);
      }
      e = Event.empty();
    }
  }

  return data;
}
