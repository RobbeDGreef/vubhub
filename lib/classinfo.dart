import "dart:io";
import "dart:convert";
import 'package:shared_preferences/shared_preferences.dart';

import "parser.dart";
import "package:path_provider/path_provider.dart";

/// Classinfo object, used to store all current loaded lecture data.
class ClassInfo {
  String infoUrl;
  Function() updateCallback;
  List<Lecture> classes;
  DateTime lastUpdated;
  int userColor;
  bool isDoneLoading = false;

  Future updateInfo() async {
    List<String> chunks = new List();
    var httpClient = new HttpClient();
    var request = await httpClient.getUrl(Uri.parse(this.infoUrl));
    var response = await request.close();
    var stream = response
        .transform(utf8.decoder)
        .listen((contents) => chunks.add(contents));

    return Future.wait([stream.asFuture()]).then((e) {
      var content = chunks.join('');
      this.classes = IcalParser().parse(LineSplitter.split(content));
      this.isDoneLoading = true;
      if (this.updateCallback != null) {
        this.updateCallback();
      }
      storeInfo();
    });
  }

  Future<String> get _localPath async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File("$path/latest.cal");
  }

  void loadInfo() async {
    this.isDoneLoading = false;
    try {
      print("loading data from last time");
      final file = await _localFile;
      String contents = await file.readAsString();
      this.classes = IcalParser().reparseSaved(LineSplitter.split(contents));
      this.isDoneLoading = true;
      if (this.updateCallback != null) {
        this.updateCallback();
      }
    } catch (e) {
      print("no update info so reloading: $e");
      updateInfo();
    }
  }

  void storeInfo() async {
    try {
      print("Storing the info for next time");
      final file = await _localFile;
      List<String> buf = List();
      for (Lecture l in this.classes) {
        buf.add(l.toString());
      }
      file.writeAsString(buf.join('\n'));
      final prefs = await SharedPreferences.getInstance();
      prefs.setString("lastUpdated", DateTime.now().toString());

      print("store done\n");
    } catch (e) {
      print("sad :(");
    }
  }

  void loadUserData() async {
    print("loading user data");
    final prefs = await SharedPreferences.getInstance();
    this.userColor = prefs.getInt("userColor") ?? 0;
    String s = prefs.getString("lastUpdated") ?? "";
    if (s != "")
      this.lastUpdated = DateTime.parse(s);
    else
      this.lastUpdated = DateTime(0, 0, 0);

    print("Loaded user data");
  }

  ClassInfo(String url, {Function() callback}) {
    this.infoUrl = url;
    this.updateCallback = callback;

    loadUserData();
    loadInfo();
  }

  bool isUserAllowed() {
    return this.userColor == 0;
  }

  void setCallback(Function() callback) {
    this.updateCallback = callback;
    if (this.isDoneLoading) {
      this.updateCallback();
    }
  }

  String getUserColorString() {
    return (this.userColor == 1) ? "orange" : "blue";
  }

  void updateColorFromString(String color) async {
    // @todo: Magic values are evil
    if (color == "orange")
      this.userColor = 1;
    else
      this.userColor = 0;

    final prefs = await SharedPreferences.getInstance();
    prefs.setInt("userColor", this.userColor);
  }
}
