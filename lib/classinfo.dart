import "dart:io";
import "dart:convert";
import "parser.dart";
import "package:path_provider/path_provider.dart";

/// Classinfo object, used to store all current loaded lecture data.
class ClassInfo {
  String infoUrl;
  Function() updateCallback;
  List<Lecture> classes;
  DateTime lastUpdated;

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
      if (this.updateCallback != null) this.updateCallback();
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
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      this.classes = IcalParser().reparseSaved(LineSplitter.split(contents));
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
        buf.add(l.name);
        buf.add(l.details);
        buf.add(l.start.toString());
        buf.add(l.end.toString());
      }
      file.writeAsString(buf.join('\n'));
      print("store done\n");
    } catch (e) {
      print("sad :(");
    }
  }

  ClassInfo(String url, {Function() callback}) {
    this.infoUrl = url;
    this.updateCallback = callback;

    loadInfo();
  }
  void setCallback(Function() callback) {
    this.updateCallback = callback;
    if (this.isDoneLoading) {
      this.updateCallback();
    }
  }
}
