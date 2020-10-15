import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import "crawler.dart";
import "parser.dart";
import "const.dart";

class Cache {
  void storeString(String key, String val) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, val);
  }

  void storeStringList(String key, List<String> val) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(key, val);
  }

  void storeInt(String key, int val) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(key, val);
  }

  Future<String> tryToLoadString(String key, String defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    String val = prefs.getString(key);
    if (val == null) {
      storeString(key, defaultValue);
      return defaultValue;
    }
    return val;
  }

  Future<int> tryToLoadInt(String key, int defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    int val = prefs.getInt(key);
    if (val == null) {
      storeInt(key, defaultValue);
      return defaultValue;
    }
    return val;
  }

  Future<File> _getWeekFile(
      int week, String userEduType, String userFac, String userEdu, String group) async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/" + "$userEduType-$userFac-$userEdu-$week-$group".replaceAll(' ', ''));
  }

  Future<List<Lecture>> getWeekData(
      int week, String userEduType, String userFac, String userEdu, String group) async {
    // Retrieve the week data from cache

    print("trying to get week data from week $week");
    print("week $week $userEduType $userFac $userEdu");
    // TODO: check if the data is already loaded in into the memory cache
    // TODO: create a memory cache

    final file = await _getWeekFile(week, userEduType, userFac, userEdu, group);

    // If the file does not exist, return null and tell the InfoHandler that it should be retrieved
    if (!(await file.exists())) {
      print("File does not exist");
      return null;
    }
    print("reading content");
    List<String> content = await file.readAsLines();

    // TODO: save this to the memory cache first
    return parseCacheStored(content);
  }

  Future populateWeekData(int week, String userEduType, String userFac, String userEdu,
      List<Lecture> data, String group) async {
    // Save the week data to cache
    print("saving data");
    // TODO: save the data to the memory cache
    final file = await _getWeekFile(week, userEduType, userFac, userEdu, group);
    String cacheData = "";
    for (Lecture lec in data) {
      cacheData += lec.toString() + "\n";
    }
    print(cacheData);
    file.writeAsString(cacheData);
  }

  Future<List<String>> getSelectedGroups() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList("userSelectedGroups") ?? [];
  }

  void saveSelectedGroups(List<String> val) {
    storeStringList("userSelectedGroups", val);
  }

  void doForcedCacheUpdate(String data) {
    // Force update everything
  }
}

/// Handles information exchange with other objects
class InfoHandler {
  Crawler _crawler;
  Cache _cache;

  int _userColor;
  String _userEduType;
  String _userFac;
  String _userEdu;
  String _userEmail;
  String _userCanvasAuthToken;
  Map<String, String> _userGroups;
  List<String> _selectedUserGroups;

  String getUserId() => EducationData[this._userEduType][this._userFac][this._userEdu];
  String getUserEduType() => this._userEduType;
  String getUserFac() => this._userFac;
  String getUserEdu() => this._userEdu;
  String getUserEmail() => this._userEmail;
  String getUserCanvasAuthToken() => this._userCanvasAuthToken;
  int getUserColor() => this._userColor;
  List<String> getSelectedUserGroups() => this._selectedUserGroups;

  List<String> getUserGroups() {
    this._userGroups = this._crawler.getDepartmentGroups();
    return this._userGroups.keys.toList();
  }

  void setUserGroups(List<String> val) {
    this._selectedUserGroups = val;
    this._cache.saveSelectedGroups(val);
  }

  void setUserEmail(String val) {
    this._userEmail = val;
    this._cache.storeString("userEmail", val);
  }

  void setUserCanvasAuthToken(String val) {
    this._userCanvasAuthToken = val;
    this._cache.storeString("userCanvasAuthToken", val);
  }

  void setUserColor(int color) {
    this._userColor = color;
    this._cache.storeInt("userColor", this._userColor);
  }

  void setUserEduType(String edu) {
    this._userEduType = edu;
    this._cache.storeString("userEduType", edu);
  }

  Future<void> setUserEdu(String edu) async {
    this._userEdu = edu;
    this._cache.storeString("userEdu", edu);

    // New education type means no more selected user groups
    // TODO: maybe this needs to be fixed to save previous user groups too
    setUserGroups([]);

    // When the user education type is set we also want to update the crawler to fetch the
    // new url
    this._crawler.curId = getUserId();
    await this._crawler.updateConnection();
  }

  void setUserFac(String fac) {
    this._userFac = fac;
    this._cache.storeString("userFac", fac);
  }

  InfoHandler() {
    _cache = Cache();
    _crawler = Crawler();

    // The crawler initialisation has go be called after loadUserInfo()
    // meaning we have to do this in a seperate async function
    _initCrawler();
  }

  Future<void> _loadUserInfo() async {
    this._userColor = await _cache.tryToLoadInt("userColor", DefaultUserColor);
    this._userEduType = await _cache.tryToLoadString("userEduType", DefaultUserEduType);
    this._userFac = await _cache.tryToLoadString("userFac", DefaultUserFac);
    this._userEdu = await _cache.tryToLoadString("userEdu", DefaultUserEdu);
    this._userEmail = await _cache.tryToLoadString("userEmail", null);
    this._userCanvasAuthToken = await _cache.tryToLoadString("userCanvasAuthToken", null);
  }

  void _initCrawler() async {
    // We have to wait for user data to load before we can initialize
    // the crawler etc.
    await _loadUserInfo();

    this._crawler.curId = getUserId();
    await this._crawler.updateConnection();

    this._userGroups = this._crawler.getDepartmentGroups();
    this._cache.getSelectedGroups().then((groups) => this._selectedUserGroups = groups);
  }

  Future _waitFor(Function() test, [Duration interval = Duration.zero]) async {
    var compl = Completer();
    check() {
      if (test())
        compl.complete();
      else
        Timer(interval, check);
    }

    check();
    return compl.future;
  }

  Future<List<Lecture>> getWeekData(int week) async {
    if (week == -1) {
      week = calcWeekFromDate(DateTime.now());
    }

    // TODO: this can't be healthy
    await _waitFor(() {
      return this._userEdu != null;
    }, Duration(seconds: 2));

    await _waitFor(() {
      return this._selectedUserGroups != null;
    }, Duration(seconds: 2));

    List<Lecture> allData = List();
    for (String group in this._selectedUserGroups) {
      List<Lecture> data =
          await _cache.getWeekData(week, this._userEduType, this._userFac, this._userEdu, group);
      if (data == null) {
        try {
          data = parseLectureList(await _crawler.getWeekData(week, this._userGroups[group]), week);
          _cache.populateWeekData(
              week, this._userEduType, this._userFac, this._userEdu, data, group);
        } catch (RangeError) {
          print("range error due to inpropper crawler request");
        }
      }
      if (data != null) {
        allData.addAll(data);
      }
    }

    return allData;
  }

  Future<List<Lecture>> getClassesOfDay(DateTime day) async {
    DateTime toDay = DateTime(day.year, day.month, day.day);
    List<Lecture> list = List();

    for (Lecture lec in await getWeekData(calcWeekFromDate(day))) {
      DateTime classDay = DateTime(lec.start.year, lec.start.month, lec.start.day);
      if (classDay == toDay) {
        list.add(lec);
      }
    }
    return list;
  }

  DateTime _calcStartDate() {
    // TODO: URGENT: we need a way to calculate the year start date because this will
    // change every year.
    return DateTime(2020, 9, 14);
  }

  DateTime _calcDateFromWeek(int week) {
    return _calcStartDate().add(Duration(days: 7 * (week - 1)));
  }

  int calcWeekFromDate(DateTime date) {
    DateTime start = _calcStartDate();
    DateTime selectedWeekStart = date.subtract(Duration(days: date.weekday - 1));
    return selectedWeekStart.difference(start).inDays ~/ 7 + 1;
  }

  bool isUserAllowed(int color) {
    return color == this._userColor;
  }

  Future forceCacheUpdate(int week) async {
    // TODO: update all weeks instead of just the currently selected one
    // Also when we implement that maybe update them in the following order:
    // - the current week
    // - all preloaded next weeks
    // - the previous weeks
    for (String group in this._selectedUserGroups) {
      var data = await this._crawler.getWeekData(week, this._userGroups[group]);
      await _cache.populateWeekData(week, this._userEduType, this._userFac, this._userEdu,
          parseLectureList(data, week), group);
    }
    //_cache.doForcedCacheUpdate(await this._crawler.getWeekData(week));
  }

  String colorIntToString(int color) {
    if (color == 1)
      return "orange";
    else
      return "blue";
  }

  int colorStringToInt(String color) {
    if (color == "orange")
      return 1;
    else
      return 0;
  }
}
