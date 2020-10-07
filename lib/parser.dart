import "dart:io";

/// The lecture object, used to represent VEvent's from the iCalendar
/// file
class Lecture {
  String name;
  String details;
  DateTime start;
  DateTime end;

  void show() {
    print("name: " + name);
    print("\tdetails: " + details);
    print("\tstart: " + start.toIso8601String());
    print("\tends: " + end.toIso8601String());
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
                  .substring(
                      line.indexOf(';', 16) + 1) // @todo magic values are evil
                  .toLowerCase();
      } else if (line.startsWith("DESCRIPTION")) {
        event.details = line.substring("DESCRIPTION".length + 1);
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

    // @todo: this is bound to go corrupt wtf, fix this.
    for (this.index = 0; this.index < this.file.length; ++this.index) {
      print("index: " + this.index.toString());
      Lecture l = Lecture();
      l.name = file.elementAt(this.index);
      l.details = file.elementAt(this.index + 1);
      l.start = DateTime.parse(file.elementAt(this.index + 2));
      l.end = DateTime.parse(file.elementAt(this.index + 3));
      this.index += 3;

      this.parsedList.add(l);
    }

    return this.parsedList;
  }
}
