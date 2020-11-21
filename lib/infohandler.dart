import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:f_logs/model/flog/flog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vubhub/backgroundfetch.dart';
import 'package:vubhub/const.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
    if (kIsWeb) return null;

    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/$filename");
  }

  /// Reads contents out of file in string format
  static Future<String> readFile(String filename) async {
    File f = await getFile(filename);
    if (f == null || !(await f.exists())) {
      return null;
    }

    return f.readAsString();
  }

  /// Write contents to file
  /// note: this overwrites previous data in this file.
  static Future<void> writeFile(String filename, String content) async {
    File f = await getFile(filename);
    if (f != null) f.writeAsString(content);
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

  void setUser(User user) async {
    this.user = user;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('user', user.toJson());
    } else {
      Storage.writeFile('user', user.toJson());
    }
  }

  Future<User> getUser() async {
    // Check if this.user is set
    if (this.user != null) {
      return this.user;
    }

    // If this.user is unset, check the storage
    String content;
    if (kIsWeb) {
      // If we are in web mode we need to check the SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      content = await prefs.getString('user');
    } else {
      content = await Storage.readFile('user');
    }

    // If storage does not contain the user file either, return null
    if (content == null) {
      setUser(User.defaults());
      return this.user;
    }

    // If it does, parse, save and return
    this.user = User.fromJson(jsonDecode(content));
    return this.user;
  }

  String getEventWeekFilepath(int week, String group) {
    return "${this.user.educationType}-${this.user.faculty}-${this.user.education}-$week-$group"
        .replaceAll(' ', '');
  }

  Future<List<Event>> getWeekEventData(int week, String group) async {
    // First try to find the data in the memory cache
    Map<int, List<Event>> groupData = _eventData[group];
    if (groupData != null) {
      List<Event> data = groupData[week];
      if (data != null) {
        // We call toList() on this data object so that
        // instead of returning a reference, it returns a copy.
        // This is important because we run filters over this
        // list object in the getWeekData function in the InfoHandler
        // and if we run 'remove' on the list. The data would be
        // removed in the memory cache too and that's not the
        // desired behavior.
        return data.toList();
      }
    }

    // If the data is not in the memory cache check the storage
    String eventDataString = await Storage.readFile(getEventWeekFilepath(week, group));
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
    // The same as the large block of code above. We return
    // toList() to return a copy instead of a reference
    // so that the memory cache would not be altered when we run
    // filters over the list.
    return data.toList();
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
    Storage.writeFile(getEventWeekFilepath(week, group), content);
  }

  void populateEventsByIcal(String ical, String group) {
    this._eventData[group] = {};
    var data = parseIcalToWeekEvents(ical);
    this._eventData[group].addAll(data);
  }
}

class InfoHandler {
  /// Note that the fields in this.user should never be changed. If you want to change
  /// the fields, please use the correct setters.
  User user = User();

  // Holds the group ids. The key is the actual group name.
  // This data is updated from crawler.getDepartmentGroups()
  Map<String, String> groupIds;

  // This variable will be set to false in init() if this is not the first launch
  bool isFirstLaunch = true;

  Crawler _crawler;
  Cache _cache;
  bool _updatingConnection = false;
  bool alreadyShowed = false;

  String getUserId() {
    return EducationData[this.user.educationType][this.user.faculty][this.user.education];
  }

  Future<void> setUserEducation(String edu) async {
    this.user.education = edu;
    this._cache.setUser(this.user);
    print("set user id");

    if (kIsWeb) {
      await webUpdateGroups();
    } else {
      this._crawler.curId = getUserId();
      await this._crawler.updateConnection();
      this.groupIds = this._crawler.getDepartmentGroups();
    }
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
    registerPeriodic(LectureUpdateIntervals[this.user.updateInterval], this);
  }

  void setCourses(List<Course> data) {
    this._cache.courses = data;
  }

  void setTheme(bool theme) {
    this.user.theme = theme;
    this._cache.setUser(this.user);
  }

  void setUpdateInterval(String interval) {
    this.user.updateInterval = interval;
    this._cache.setUser(this.user);
    registerPeriodic(LectureUpdateIntervals[interval], this);
  }

  InfoHandler() {
    this._cache = Cache();
    this._crawler = Crawler();
  }

  Future init() async {
    User user = await this._cache.getUser();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    isFirstLaunch = prefs.getBool('firstLaunch') ?? true;
    if (isFirstLaunch) {
      prefs.setBool('firstLaunch', false);
    }

    if (user != null) this.user = user;

    if (this.user.education != null) {
      this._updatingConnection = true;

      if (kIsWeb) {
        await webUpdateGroups();
      } else {
        this._crawler.curId = getUserId();
        this._crawler.updateConnection().then(
          (_) {
            this.groupIds = this._crawler.getDepartmentGroups();
          },
        );
      }
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

  void addFilter(String group, CourseFilter filter) {
    if (this.user.courseFilters[group] == null) {
      this.user.courseFilters[group] = [];
    }
    this.user.courseFilters[group].add(filter);
    this._cache.setUser(user);
  }

  void removeFilter(String group, String name) {
    this.user.courseFilters[group].removeWhere((element) {
      return (element.name == name);
    });

    this._cache.setUser(this.user);
  }

  Future<String> getWeekUpdateTime(int week) async {
    if (week == -1) {
      week = calcWeekFromDate(DateTime.now());
    }

    if (this.user.selectedGroups.isEmpty) {
      return "Never";
    }

    var path = this._cache.getEventWeekFilepath(week, this.groupIds[this.user.selectedGroups[0]]);
    File f = await Storage.getFile(path);

    if (!(await f.exists())) {
      print(f.path);
      return "Never";
    }

    return DateFormat("d MMMM yyyy 'at' HH:mm").format(await f.lastModified());
  }

  // TODO: this is bruteforce and a slow algorithm, improve pls
  bool applyFilters(Event event, String group) {
    List<String> words = event.name.toLowerCase().replaceAll(RegExp(r'[,:\(\)]'), '').split(' ');

    for (CourseFilter filter in this.user.courseFilters[group] ?? []) {
      bool containsAll = true;
      for (String word in filter.words) {
        if (!words.contains(word)) {
          containsAll = false;
          break;
        }
      }
      if (containsAll) return true;
    }

    return false;
  }

  Future<List<Event>> getWeekData(int week) async {
    if (week == -1) {
      week = calcWeekFromDate(DateTime.now());
    }

    if (!kIsWeb) FLog.info(text: "Getting data for ${this.user.selectedGroups}");

    Map urls;
    List<Event> allGroupData = [];
    for (String group in this.user.selectedGroups) {
      // Check the data in the memory cache and storage
      List<Event> data = await this._cache.getWeekEventData(week, group);

      // If the data was found in the cache or storage add it to all the group data.
      if (data != null) {
        data.removeWhere((element) => applyFilters(element, group));
        allGroupData.addAll(data);
        continue;
      }
      // Otherwise try to fetch it with the crawler

      if (!kIsWeb) {
        try {
          data =
              parseLectureList(await this._crawler.getWeekData(week, this.groupIds[group]), week);
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
      } else {
        if (urls == null) {
          var ids = this.user.selectedGroups.toList();
          for (int i = 0; i < ids.length; i++) {
            ids[i] = Uri.encodeComponent(this.groupIds[ids[i]]);
          }

          final requrl =
              VubhubServerUrl + '/ical?education_id=${getUserId()}&group_ids=${ids.join(',')}';
          urls = jsonDecode((await http.get(requrl)).body);
        }
        var res = await http.get(VubhubServerUrl + '/corsproxy/' + urls[this.groupIds[group]]);
        this._cache.populateEventsByIcal(res.body, group);
        data = await this._cache.getWeekEventData(week, group);
      }

      data.removeWhere((element) => applyFilters(element, group));
      allGroupData.addAll(data);
    }

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

  Future webUpdateGroups() async {
    this.groupIds = {};
    var serverres = await http.get(VubhubServerUrl + '/groups?education_id=${getUserId()}');
    Map<String, dynamic> res = jsonDecode(serverres.body);
    for (String key in res.keys) {
      this.groupIds[key] = res[key];
    }
  }

  static DateTime _calcStartDate() {
    return DateTime(2020, 9, 14);
  }

  /// The reason this function is inside this class and not a helper is because
  /// we need to calculate the year start date and we will probably need to
  /// fetch that from somehwere online, for now we just hard coded it.
  static int calcWeekFromDate(DateTime date) {
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
