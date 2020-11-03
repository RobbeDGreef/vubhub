import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import "package:flutter/material.dart";
import 'package:vubhub/dayview.dart';
import 'package:package_info/package_info.dart';
import 'package:f_logs/f_logs.dart';

import "mapview.dart";
import "infohandler.dart";
import "settings.dart";
import 'const.dart';
import "placesview.dart";
import 'coursesview/coursesview.dart';
import 'help.dart';
import 'news.dart';
import 'theming.dart';
import 'dayview.dart';
import 'push_notifications.dart';

FirebaseAnalytics analytics = FirebaseAnalytics();

void main() async {
  final PushNotificationManager man = PushNotificationManager();
  WidgetsFlutterBinding.ensureInitialized();
  await man.init();

  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
    FLog.error(stacktrace: details.stack, text: "Flutter error occurred (${details.exception})");
  };

  InfoHandler infoHandler = InfoHandler();
  await infoHandler.init();

  runZoned<Future<void>>(() async {
    runApp(Vub(infoHandler));
  }, onError: (error, stacktrace) {
    print(error);
    print(stacktrace);
    FLog.error(stacktrace: stacktrace, text: "Dart error occurred (${error})");
  });
}

/// The main app
class Vub extends StatefulWidget {
  InfoHandler infoHandler;

  Vub(InfoHandler infoHandler) {
    this.infoHandler = infoHandler;
  }

  @override
  VubState createState() => VubState(this.infoHandler);
}

class VubState extends State<Vub> {
  final theme = ThemeData(primaryColor: Color.fromARGB(0xFF, 0, 52, 154));
  InfoHandler infoHandler;

  VubState(InfoHandler infoHandler) {
    this.infoHandler = infoHandler;
  }

  void updateTheme(bool light) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildTheme(this.infoHandler.user.theme ?? true),
      title: "VUB class schedules",
      home: MainUi(this.infoHandler),
      navigatorObservers: [FirebaseAnalyticsObserver(analytics: analytics)],
    );
  }
}

/// Statefull widget used to store all immutable data
/// so that we can change state using the State widget
class MainUi extends StatefulWidget {
  InfoHandler infoHandler;

  MainUi(InfoHandler info) {
    this.infoHandler = info;
  }

  @override
  _MainUiState createState() {
    return _MainUiState(this.infoHandler);
  }
}

/// The state object, this object will be regenerated and
/// the data is thus mutable.
class _MainUiState extends State<MainUi> {
  InfoHandler _info;
  int _selectedNavBarIndex = 0;
  dynamic currentPage;
  PackageInfo packageInfo;

  _MainUiState(InfoHandler info) {
    // We are going to assume that this returns fast enough
    PackageInfo.fromPlatform().then((v) => this.packageInfo = v);
    this._info = info;
  }

  void _openSettings() async {
    List<String> groups = [];
    groups.addAll(this._info.user.selectedGroups);

    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) => SettingsMenu(this._info)));

    if (this._selectedNavBarIndex == 0 && this._info.user.selectedGroups == groups) {
      return;
    }
    try {
      this.currentPage.update();
    } catch (e) {}
  }

  void _openAbout() {
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text("About us")),
        body: Column(
          children: [
            ListView(
              shrinkWrap: true,
              padding: EdgeInsets.all(8),
              children: [
                Text(
                  "About",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                Text("Who are we", style: TextStyle(fontSize: 20)),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(WhoAreWeText, style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
            Text("Version: $CurrentAppRelease"),
          ],
        ),
      );
    }));
  }

  void _openHelp() {
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
      return HelpView();
    }));
  }

  Widget _buildDrawer() {
    return Drawer(
        child: ListView(
      children: [
        DrawerHeader(
            decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage("assets/vub-cs2.png")),
                color: Colors.white)),
        ListTile(title: Text("Settings"), onTap: _openSettings),
        ListTile(title: Text("About"), onTap: _openAbout),
        ListTile(title: Text("Help"), onTap: _openHelp),
      ],
    ));
  }

  Widget _buildTabScreen(int index) {
    switch (index) {
      case 0:
        this.currentPage = DayView(info: this._info);
        break;

      case 1:
        this.currentPage = CoursesView(info: this._info);
        break;

      case 2:
        this.currentPage = MapView();
        break;

      case 3:
        this.currentPage = PlacesView(this._info);
        break;

      case 4:
        this.currentPage = NewsView();
        break;

      default:
        this.currentPage = Text("Something went wrong");
        break;
    }
    return this.currentPage;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = BottomNavigationBar(
      currentIndex: this._selectedNavBarIndex,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      onTap: (i) {
        setState(() {
          this._selectedNavBarIndex = i;
        });
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.view_agenda),
          label: "classes",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: "courses",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: "map",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.meeting_room),
          label: "places",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.public),
          label: "News",
        ),
      ],
    );

    final tabText = ["Today", "Course information", "VUB campus map", "Places", "News"];

    final refreshAction = [
      IconButton(
        icon: Icon(Icons.replay_sharp),
        onPressed: () {
          print(tabText[6]);
          this.currentPage.fullUpdate();
        },
      ),
    ];

    return Scaffold(
        drawer: _buildDrawer(),
        bottomNavigationBar: bottom,
        appBar: AppBar(
            title: Text(tabText[this._selectedNavBarIndex]),
            actions: (this._selectedNavBarIndex == 0) ? refreshAction : []),
        body: _buildTabScreen(this._selectedNavBarIndex));
  }
}
