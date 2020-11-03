import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'canvas/canvasobjects.dart';
import 'canvas/canvasapi.dart';

import "crawler.dart";
import "parser.dart";
import "educationdata.dart";
import "event.dart";
import 'user.dart';

// The storage handler
class Storage {
  static Future<File> getFile(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/$filename");
  }

  /// Reads contents out of file in string format
  static Future<String> readFile(String filename) async {
    File f = await getFile(filename);
    if (!(await f.exists())) {
      return null;
    }

    return f.readAsString();
  }

  /// Write contents to file
  /// note: this overwrites previous data in this file.
  static Future<void> writeFile(String filename, String content) async {
    File f = await getFile(filename);
    f.writeAsString(content);
  }
}

// The actual memory cache
class Cache {
  List<Course> courses;
  Map<String, String> userGroups;
  User user;

  /// The event data is stored in linked hashmaps, the first hashmap takes the group name
  /// as a key, the second one the week number.
  Map<String, Map<int, List<Event>>> _eventData = {};

  void setUser(User user) {
    this.user = user;
    Storage.writeFile('user', user.toJson());
  }

  Future<User> getUser() async {
    // Check if this.user is set
    if (this.user != null) {
      return this.user;
    }

    // If this.user is unset, check the storage
    String content = await Storage.readFile('user');

    // If storage does not contain the user file either, return null
    if (content == null) {
      setUser(User.defaults());
      return this.user;
    }

    // If it does, parse, save and return
    this.user = User.fromJson(jsonDecode(content));
    return this.user;
  }

  String _getEventWeekFile(int week, String group) {
    return "${this.user.educationType}-${this.user.faculty}-${this.user.education}-$week-$group"
        .replaceAll(' ', '');
  }

  Future<List<Event>> getWeekEventData(int week, String group) async {
    // First try to find the data in the memory cache
    Map<int, List<Event>> groupData = _eventData[group];
    if (groupData != null) {
      List<Event> data = groupData[week];
      if (data != null) return data;
    }

    // If the data is not in the memory cache check the storage
    String eventDataString = await Storage.readFile(_getEventWeekFile(week, group));
    if (eventDataString == null) {
      // And if it is not in storage either, return null;
      return null;
    }

    // If the storage file was found, parse, save and return.
    List<Event> data = parseStoredEventData(eventDataString);
    // TODO: this might throw an exception, won't it.
    if (this._eventData[group] == null) {
      this._eventData.addAll({
        group: {week: data}
      });
    } else {
      this._eventData[group][week] = data;
    }
    return data;
  }

  void populateEvents(int week, String group, List<Event> data) {
    // Store the data in the memory cache

    if (!this._eventData.containsKey(group)) {
      this._eventData[group] = {week: data};
    } else
      this._eventData[group][week] = data;

    // Store it in storage too
    String content = "";
    for (Event ev in data) content += ev.toString() + '\n';
    Storage.writeFile(_getEventWeekFile(week, group), content);
  }
}

class InfoHandler {
  /// Note that the fields in this.user should never be changed. If you want to change
  /// the fields, please use the correct setters.
  User user = User();

  // Holds the group ids. The key is the actual group name.
  // This data is updated from crawler.getDepartmentGroups()
  Map<String, String> groupIds;

  Crawler _crawler;
  Cache _cache;
  bool _updatingConnection = false;

  String getUserId() {
    return EducationData[this.user.educationType][this.user.faculty][this.user.education];
  }

  Future<void> setUserEducation(String edu) async {
    this.user.education = edu;
    this._cache.setUser(this.user);

    this._crawler.curId = getUserId();
    await this._crawler.updateConnection();
    this.groupIds = this._crawler.getDepartmentGroups();
  }

  void setUserFaculty(String fac) {
    this.user.faculty = fac;
    this._cache.setUser(this.user);
  }

  void setUserEducationType(String eduType) {
    this.user.educationType = eduType;
    this._cache.setUser(this.user);
  }

  void setUserRotationColor(int color) {
    this.user.rotationColor = color;
    this._cache.setUser(this.user);
  }

  void setUserSelectedGroups(List<String> groups) {
    this.user.selectedGroups = groups;
    this._cache.setUser(this.user);
  }

  void setCourses(List<Course> data) {
    this._cache.courses = data;
  }

  void setTheme(bool theme) {
    this.user.theme = theme;
    this._cache.setUser(this.user);
  }

  InfoHandler() {
    this._cache = Cache();
    this._crawler = Crawler();
  }

  Future init() async {
    User user = await this._cache.getUser();

    if (user != null) this.user = user;

    if (this.user.education != null) {
      this._updatingConnection = true;
      this._crawler.curId = getUserId();
      this._crawler.updateConnection().then(
        (_) {
          this.groupIds = this._crawler.getDepartmentGroups();
        },
      );
    }
  }

  void userLogin(String token) async {
    this.user.accessToken = token;
    Map<String, dynamic> data = await CanvasApi(token).get('api/v1/users/self/profile');
    this.user.name = data['name'];
    this.user.email = data['primary_email'];
    this.user.locale = data['locale'];

    this._cache.setUser(this.user);
  }

  Future<List<Event>> getWeekData(int week) async {
    if (week == -1) {
      week = calcWeekFromDate(DateTime.now());
    }

    List<Event> allGroupData = [];
    for (String group in this.user.selectedGroups) {
      // Check the data in the memory cache and storage
      List<Event> data = await this._cache.getWeekEventData(week, group);

      // If the data was found in the cache or storage add it to all the group data.
      if (data != null) {
        allGroupData.addAll(data);
        continue;
      }
      // Otherwise try to fetch it with the crawler

      try {
        print("try to get");
        data = parseLectureList(await this._crawler.getWeekData(week, this.groupIds[group]), week);
        print(data);
      } catch (RangeError) {
        print("range error ?");
      }

      // If the data is null again, just skip this group and show error
      if (data == null) {
        print("ERROR: crawler could not fetch data for week $week and group $group");
        continue;
      }

      // Otherwise, populate the cache and add it to all the group data.
      this._cache.populateEvents(week, group, data);
      allGroupData.addAll(data);
    }

    // TODO: match coursedata etc.
    return allGroupData;
  }

  Future<List<Event>> getTodaysEvents(DateTime day) async {
    DateTime today = DateTime(day.year, day.month, day.day);

    List<Event> events = [];
    for (Event ev in await getWeekData(calcWeekFromDate(day))) {
      DateTime evDay = DateTime(ev.startDate.year, ev.startDate.month, ev.startDate.day);
      if (evDay == today) {
        events.add(ev);
      }
    }
    return events;
  }

  DateTime _calcStartDate() {
    return DateTime(2020, 9, 14);
  }

  /// The reason this function is inside this class and not a helper is because
  /// we need to calculate the year start date and we will probably need to
  /// fetch that from somehwere online, for now we just hard coded it.
  int calcWeekFromDate(DateTime date) {
    DateTime start = _calcStartDate();
    DateTime selectedWeekStart = date.subtract(Duration(days: date.weekday - 1));
    return selectedWeekStart.difference(start).inDays ~/ 7 + 1;
  }

  Future<void> forceCrawlerFetch(int week) async {
    if (this.groupIds == null) return;
    for (String group in this.user.selectedGroups) {
      var data = await this._crawler.getWeekData(week, this.groupIds[group]);
      print(data);
      await this._cache.populateEvents(week, this.groupIds[group], parseLectureList(data, week));
    }
  }
}
