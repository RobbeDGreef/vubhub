import "dart:io";
import "package:html/parser.dart" as html;

/// The lecture object, used to represent VEvent's from the iCalendar
/// file
class Lecture {
  String name = "";
  String details = "";
  String professor = "";
  String location = "No location specified";
  String remarks = "";
  DateTime start;
  DateTime end;

  Lecture() {}

  Lecture.onlyName(String s) {
    this.name = s;
  }
  Lecture.fromObject(Lecture obj) {
    this.name = obj.name;
    this.details = obj.details;
    this.professor = obj.professor;
    this.location = obj.location;
    this.remarks = obj.remarks;
    this.start = obj.start;
    this.end = obj.end;
  }

  Lecture.fromString(List<String> data) {
    this.name = data[0];
    this.details = data[1];
    this.professor = data[2];
    this.location = data[3];
    this.remarks = fromSavedString(data[4]);
    this.start = DateTime.parse(data[5]);
    this.end = DateTime.parse(data[6]);
  }

  String toSavedString(String t) {
    return t.split('\n').join("\\n");
  }

  String fromSavedString(String t) {
    return t.split("\\n").join("\n");
  }

  @override
  String toString() {
    // TODO: Handle all string data fields like this.remarks
    List<String> data = List();

    data.add(this.name);
    data.add(this.details);
    data.add(this.professor);
    data.add(this.location);
    data.add(toSavedString(this.remarks));
    data.add(this.start.toString());
    data.add(this.end.toString());

    return data.join('\n');
  }
}

/// The iCalendar parser
class IcalParser {
  Iterable<String> file;
  int index;
  List<Lecture> parsedList;

  String next() {
    return this.file.elementAt(++this.index);
  }

  /// Parse part of the file into Lecture object (from BEGIN:VEVENT until END:VEVENT)
  Lecture parseEvent() {
    Lecture event = Lecture();

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

List<Lecture> parseLectureList(String data, int week) {
  if (data == null) return List();
  var doc = html.parse(data);
  List<Lecture> lectures = List();
  // Iterate over every day in the week
  for (var day in doc.getElementsByClassName("TableBody")[0].children[0].children) {
    if (day.children[0].className != "tdCol") continue;

    Lecture lec = Lecture();
    lec.name = day.children[0].text;
    lec.professor = day.children[1].text;
    lec.location = day.children[6].text;
    lec.remarks = day.children[8].text;

    for (String date in day.children[5].text.split(")")) {
      if (date == "" || int.parse(date.substring(0, date.indexOf(" "))) != week) {
        continue;
      }
      var parts = date.substring(date.indexOf("(") + 1).split("/");
      var toDay = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      lec.start = DateTime(
          toDay.year,
          toDay.month,
          toDay.day,
          int.parse(day.children[2].text.split(":")[0]),
          int.parse(day.children[2].text.split(":")[1]));
      lec.end = DateTime(
          toDay.year,
          toDay.month,
          toDay.day,
          int.parse(day.children[3].text.split(":")[0]),
          int.parse(day.children[3].text.split(":")[1]));
      lectures.add(new Lecture.fromObject(lec));
    }
  }
  return lectures;
}

List<Lecture> parseCacheStored(List<String> data) {
  List<Lecture> lectures = List();
  for (int i = 0; i < data.length; i += 7) {
    lectures.add(Lecture.fromString(data.sublist(i, i + 7)));
  }
  return lectures;
}
