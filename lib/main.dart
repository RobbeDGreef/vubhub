import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:vubhub/dayview.dart';
import 'package:package_info/package_info.dart';
import 'package:f_logs/f_logs.dart';
import 'package:workmanager/workmanager.dart';

import 'canvas/canvasapi.dart';
import 'firstlaunch.dart';
import "mapview.dart";
import "infohandler.dart";
import 'settings/settings.dart';
import 'const.dart';
import "placesview.dart";
import 'coursesview/coursesview.dart';
import 'help.dart';
import 'news.dart';
import 'theming.dart';
import 'dayview.dart';
import 'push_notifications.dart';
import 'backgroundfetch.dart';

FirebaseAnalytics analytics = FirebaseAnalytics();

void callbackDispenser() {
  Workmanager.executeTask((taskName, inputData) async {
    try {
      String curId = inputData['curId'];
      int week = InfoHandler.calcWeekFromDate(DateTime.now());
      List<dynamic> groups = inputData['groups'];
      String path = inputData['path'];
      await backgroundFetch(curId, week, groups, path);
    } catch (e) {
      print("exception $e\n");
      FLog.error(text: "Error in background process $e");
    }
    return Future.value(true);
  });
}

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

  Workmanager.initialize(callbackDispenser, isInDebugMode: kDebugMode);
  if (infoHandler.isFirstLaunch) {
    registerPeriodic(LectureUpdateIntervals[infoHandler.user.updateInterval], infoHandler);
  }

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
      debugShowCheckedModeBanner: false,
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
    List<Widget> children = [Text("Not logged in to Canvas", style: TextStyle(fontSize: 20))];

    if (this._info.user.name != null) {
      children = [
        Text("Logged into canvas as"),
        SizedBox(height: 10),
        Row(children: [
          FutureBuilder(
              future: CanvasApi(this._info.user.accessToken).get('api/v1/users/self'),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    clipBehavior: Clip.hardEdge,
                    child: Image.network(
                      snapshot.data['avatar_url'],
                    ),
                  );
                }

                return Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[400]),
                  child:
                      Center(child: Text(this._info.user.name[0], style: TextStyle(fontSize: 35))),
                );
              }),
          SizedBox(width: 10),
          Expanded(
            child: ListView(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                Text(this._info.user.name,
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                Text(this._info.user.email ?? '', style: Theme.of(context).textTheme.subtitle1),
              ],
            ),
          ),
        ]),
      ];
    }

    return Drawer(
        child: ListView(
      children: [
        DrawerHeader(
          child: Center(
            child: ListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: children,
            ),
          ),
        ),
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
          icon: Icon(Icons.location_on),
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
          this.currentPage.fullUpdate();
        },
      ),
    ];

    if (this._info.isFirstLaunch && !this._info.alreadyShowed) {
      return Scaffold(
        body: FirstLaunchSetup(
            info: this._info, close: () => setState(() => this._info.alreadyShowed = true)),
      );
    }

    return Scaffold(
        drawer: _buildDrawer(),
        bottomNavigationBar: bottom,
        appBar: AppBar(
            title: Text(tabText[this._selectedNavBarIndex]),
            actions: (this._selectedNavBarIndex == 0) ? refreshAction : []),
        body: _buildTabScreen(this._selectedNavBarIndex));
  }
}
