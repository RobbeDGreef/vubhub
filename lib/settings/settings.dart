import 'dart:convert';
import 'dart:ui' as ui;

import 'package:f_logs/f_logs.dart';
import 'package:flushbar/flushbar.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import "package:settings_ui/settings_ui.dart";
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

import '../infohandler.dart';
import '../const.dart';
import '../educationdata.dart';
import '../main.dart';
import '../user.dart';
import 'selection.dart';

// Uncomment for web build
// import 'dart:html';

class SelectMultiMenu extends StatefulWidget {
  String _title;
  List<String> _selected;
  List<String> _selection;
  Function(bool, String) _callback;

  SelectMultiMenu(
      String title, List<String> selected, List<String> selection, Function(bool, String) ptr) {
    this._title = title;
    this._selected = selected;
    this._selection = selection;
    this._callback = ptr;
  }

  @override
  _SelectMultiMenuState createState() =>
      _SelectMultiMenuState(this._title, this._selected, this._selection, this._callback);
}

class _SelectMultiMenuState extends State<SelectMultiMenu> {
  String _title;
  List<String> _selected;
  List<String> _selection;
  Function(bool, String) _callback;

  _SelectMultiMenuState(
      String title, List<String> selected, List<String> selection, Function(bool, String) ptr) {
    this._title = title;
    this._selected = selected;
    this._selection = selection;
    this._callback = ptr;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tiles = List();
    for (String select in this._selection) {
      tiles.add(CheckboxListTile(
        title: Text(select),
        value: this._selected.contains(select),
        onChanged: (bool val) {
          setState(() {
            if (val) {
              if (!this._selected.contains(select)) this._selected.add(select);
            } else {
              this._selected.remove(select);
            }
            this._callback(val, select);
          });
        },
      ));
      tiles.add(Divider());
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(
            this._title,
            style: TextStyle(color: Theme.of(context).accentColor),
          ),
          iconTheme: IconThemeData(color: Theme.of(context).accentColor),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(children: tiles));
  }
}

class KeywordSelector extends StatefulWidget {
  final Function(String, List<String>) onAdded;
  final Function(String, List<String>) onRemoved;

  KeywordSelector({this.onAdded, this.onRemoved});

  @override
  _KeywordSelectorState createState() =>
      _KeywordSelectorState(onAdded: onAdded, onRemoved: onRemoved);
}

class _KeywordSelectorState extends State<KeywordSelector> {
  final Function(String, List<String>) onAdded;
  final Function(String, List<String>) onRemoved;

  final List<String> keywords = [];

  String _oldString = ' ';

  _KeywordSelectorState({this.onAdded, this.onRemoved});

  Widget _buildChip(String el) {
    return Chip(
        label: Text(el, style: TextStyle(fontSize: 18)),
        deleteIcon: Icon(Icons.close),
        onDeleted: () {
          setState(() {
            this.keywords.remove(el);
          });
          this.onRemoved(el, this.keywords);
        });
  }

  @override
  Widget build(BuildContext context) {
    // This piece of code is quite hacky but I wasn't able to find a way to get keypresses for phones in flutter
    // We basically just default the text field out with
    // a string containing a single space ' '. This way we can test
    // if the backspace is called. We test if a new keyword was added using the space behind the string

    var txt = TextEditingController(text: this._oldString);
    txt.selection = TextSelection.fromPosition(TextPosition(offset: this._oldString.length));
    return Wrap(
      spacing: 5,
      children: [
        ...(keywords.map((e) => _buildChip(e)).toList()),
        TextFormField(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.only(left: 4, right: 4),
          ),
          maxLines: null,
          style: TextStyle(fontSize: 18),
          controller: txt,
          enableInteractiveSelection: false,
          onChanged: (String newstr) {
            if (newstr.isEmpty) {
              setState(() {
                _oldString = ' ';
                if (this.keywords.isNotEmpty) {
                  String last = this.keywords.last;
                  this.keywords.removeLast();
                  this.onRemoved(last, this.keywords);
                }
              });
            } else if (newstr.endsWith(' ')) {
              setState(() {
                _oldString = ' ';

                // We have to make sure that the string does not consist of just spaces
                bool onlySpaces = true;
                for (var char in newstr.characters) {
                  if (char != ' ') {
                    onlySpaces = false;
                    break;
                  }
                }
                try {
                  String keyword = newstr.substring(1, newstr.length - 1);
                  if (!onlySpaces && !this.keywords.contains(keyword)) {
                    this.keywords.add(keyword);
                    this.onAdded(this.keywords.last, this.keywords);
                  }
                } catch (RangeError) {}
              });
            } else {
              _oldString = newstr;
            }
          },
        ),
      ],
    );
  }
}

class GroupFilterMenu extends StatelessWidget {
  InfoHandler info;
  String group;

  GroupFilterMenu({this.info, this.group});

  @override
  Widget build(BuildContext context) {
    Color color = Theme.of(context).accentColor;
    return ListView(
      children: [],
    );
  }
}

class GroupFilterView extends StatefulWidget {
  final String group;
  final InfoHandler info;

  GroupFilterView({this.group, this.info});

  @override
  _GroupFilterViewState createState() => _GroupFilterViewState(group: this.group, info: this.info);
}

class _GroupFilterViewState extends State<GroupFilterView> {
  final InfoHandler info;
  final String group;

  String _name;
  List<String> _keywords;

  _GroupFilterViewState({this.group, this.info});

  Widget build(BuildContext context) {
    Color color = Theme.of(context).accentColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          group,
          style: TextStyle(color: color),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: color),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              elevation: 3.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: (this.info.user.courseFilters[group]?.length ?? 0) == 0
                      ? 1
                      : this.info.user.courseFilters[group].length,
                  itemBuilder: (context, index) {
                    if (this.info.user.courseFilters[group] == null ||
                        this.info.user.courseFilters[group].isEmpty)
                      return Padding(
                        padding: EdgeInsets.only(top: 20, bottom: 20, left: 8, right: 8),
                        child: Text(
                          "No filters",
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      );
                    return ListTile(
                        title: Text(this.info.user.courseFilters[group][index].name),
                        trailing: CloseButton(onPressed: () {
                          setState(() => this.info.removeFilter(
                              group, this.info.user.courseFilters[group][index].name));
                        }));
                  }),
            ),
          ),
          Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).chipTheme.backgroundColor,
            ),
            child: IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    this._keywords = [];
                    this._name = "";
                    return SimpleDialog(
                      title: Text(group),
                      titlePadding: EdgeInsets.all(16),
                      contentPadding: EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 16),
                      children: [
                        Text("Set a name for your filter"),
                        TextField(style: TextStyle(fontSize: 20), onChanged: (s) => this._name = s),
                        SizedBox(height: 20),
                        Text("Words to match (press space to separate)"),
                        SizedBox(height: 5),
                        KeywordSelector(
                          onAdded: (s, kwds) => this._keywords = kwds,
                          onRemoved: (s, kwds) => this._keywords = kwds,
                        ),
                        TextButton(
                          child: Text("Done"),
                          onPressed: () {
                            Navigator.pop(context);
                            if (this._keywords.isNotEmpty &&
                                (this.info.user.courseFilters[group] == null ||
                                    this
                                            .info
                                            .user
                                            .courseFilters[group]
                                            .indexWhere((element) => element.name == this._name) ==
                                        -1)) {
                              setState(() => this.info.addFilter(
                                    group,
                                    CourseFilter(name: this._name, words: this._keywords),
                                  ));
                            } else if (this._keywords.isEmpty) {
                              Flushbar(
                                message: 'The given keywords were empty',
                                duration: Duration(seconds: 2),
                                margin: EdgeInsets.all(8),
                                borderRadius: 8,
                                animationDuration: Duration(milliseconds: 500),
                              ).show(context);
                            } else {
                              Flushbar(
                                message: 'The given filter already exists',
                                duration: Duration(seconds: 2),
                                margin: EdgeInsets.all(8),
                                borderRadius: 8,
                                animationDuration: Duration(milliseconds: 500),
                              ).show(context);
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 30, left: 16, right: 16),
            child: Text(
                "Add filters with keywords that match the course name. If a course matches all the keywords it won't be displayed on the day view.\n\nFor example:\n'Discrete mathematics' would be 'discrete' and 'mathematics' although one would probably sufise."),
          ),
        ],
      ),
    );
  }
}

class FilterMenu extends StatefulWidget {
  InfoHandler info;

  FilterMenu({this.info});

  @override
  _FilterMenuState createState() => _FilterMenuState(info: this.info);
}

class _FilterMenuState extends State<FilterMenu> {
  InfoHandler info;

  _FilterMenuState({this.info});

  Widget _buildContent() {
    return ListView.builder(
      itemCount: this.info.user.selectedGroups.length,
      itemBuilder: (context, index) {
        String group = this.info.user.selectedGroups[index];
        return Card(
          child: ListTile(
            title: Text(this.info.user.selectedGroups[index]),
            subtitle: Text(this.info.user.courseFilters[group] == null ||
                    this.info.user.courseFilters[group].isEmpty
                ? "No filters"
                : "${this.info.user.courseFilters[group].length} filters"),
            onTap: () => Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) => GroupFilterView(
                        info: this.info, group: this.info.user.selectedGroups[index]),
                  ),
                )
                .then((_) => setState(() {})),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color color = Theme.of(context).accentColor;
    return Scaffold(
      appBar: AppBar(
        title: Text("Course filters per group", style: TextStyle(color: color)),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: color),
        elevation: 0,
      ),
      body: _buildContent(),
    );
  }
}

void _popupMobile(context, info) {
  // Clear cookies so that the user can re-login.
  CookieManager().clearCookies();

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: Text("Login", style: TextStyle(color: Theme.of(context).accentColor)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Theme.of(context).accentColor),
          ),
          body: WebView(
            initialUrl: CanvasLoginUrl,
            javascriptMode: JavascriptMode.unrestricted,
            onPageStarted: (url) {
              if (url.startsWith('https://canvas.instructure.com')) {
                final code = Uri.parse(url).queryParameters['code'];
                String tokenUrl = CanvasTokenUrlBase + "&code=" + code;
                print(tokenUrl);
                http.post(tokenUrl).then((res) {
                  Navigator.pop(context);
                  var json = jsonDecode(res.body);
                  if (json['error'] != null) {
                    // Display error message
                    Flushbar(
                      message: "An error occurred while trying to log in",
                      duration: Duration(seconds: 2),
                      margin: EdgeInsets.all(8),
                      borderRadius: 8,
                      animationDuration: Duration(milliseconds: 500),
                    ).show(context);
                    return;
                  } else {
                    info.userLogin(json['access_token']);
                  }
                });
              }
            },
          ),
        );
      },
    ),
  );
}

void _popupWeb(BuildContext context, InfoHandler info) {
  /* Uncomment for web build 
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) {
        final IFrameElement iframe = IFrameElement();
        iframe.src = CorsProxyUrl + CanvasLoginUrl;
        iframe.style.border = 'none';

        // ignore: undefined_prefixed_name
        ui.platformViewRegistry.registerViewFactory(
          'iframeElement',
          (viewId) => iframe,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text("Login", style: TextStyle(color: Theme.of(context).accentColor)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Theme.of(context).accentColor),
          ),
          body: HtmlElementView(
            viewType: 'iframeElement',
          ),
        );
      },
    ),
  );
  */
}

void _desktopLogin() {}

/*
void _popupDesktop(context, info) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(title: Text("Login")),
          body: Center(
            child: Container(
              width: 300,
              height: 500,
              child: ListView(
                padding: EdgeInsets.all(8),
                children: [
                  Row(
                    children: [
                      Image(
                        image: AssetImage("assets/canvasLogo.png"),
                        fit: BoxFit.cover,
                        width: 140,
                      ),
                      Image(
                        image: AssetImage("assets/vub-logo.png"),
                        fit: BoxFit.cover,
                        width: 140,
                      ),
                    ],
                  ),
                  Text("E-mail"),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (s) => this._email = s,
                  ),
                  Text("Password"),
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (s) => this._password = s,
                  ),
                  TextButton(
                    child: Text("Login"),
                    onPressed: () => _desktopLogin(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
*/

void canvasLogin(BuildContext context, InfoHandler info) {
  if (kIsWeb) {
    _popupWeb(context, info);
  } else {
    _popupMobile(context, info);
  }
}

class SettingsMenu extends StatefulWidget {
  InfoHandler info;

  SettingsMenu(InfoHandler info) {
    this.info = info;
  }

  @override
  _SettingsMenuState createState() => _SettingsMenuState(this.info);
}

class _SettingsMenuState extends State<SettingsMenu> {
  String _dropDownColor;
  String _dropDownEduType = EducationData.keys.first;
  String _dropDownFac = EducationData[EducationData.keys.first].keys.first;
  String _dropDownEdu;
  String _dropDownUserGroup;
  String _userName = "Not logged in";
  String _email = "";
  String _password = "";
  List<String> _userGroups = [];
  InfoHandler _info;
  List<String> _selectedUserGroups;
  String _updateInterval;
  String latestTime = "...";

  List<String> getEducations() {
    return EducationData[this._dropDownEduType][this._dropDownFac].keys.toList();
  }

  _SettingsMenuState(InfoHandler info) {
    this._info = info;
    this._dropDownColor = info.user.rotationColor == 1 ? 'orange' : 'blue';

    if (info.user.educationType != null) {
      this._dropDownEduType = info.user.educationType;
      this._dropDownFac = info.user.faculty;
      this._dropDownEdu = info.user.education;
      this._selectedUserGroups = info.user.selectedGroups;
      this._updateInterval = info.user.updateInterval;
    }

    if (info.user.name != '') {
      this._userName = info.user.name;
    }

    if (info.groupIds != null) this._userGroups = info.groupIds.keys.toList();

    this._info.getWeekUpdateTime(-1).then((val) {
      setState(() {
        this.latestTime = val;
      });
    });
  }

  void showLoadingDialog(String text) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              padding: EdgeInsets.all(8),
              width: 60,
              height: 120,
              child: Column(
                children: [
                  Text(text, style: TextStyle(fontSize: 18)),
                  Center(
                    child: Container(
                      margin: EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                      width: 50,
                      height: 50,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  SettingsTile _buildChooseSettings(
      String title, String selected, Icon icon, List<String> selection, Function(String) ptr) {
    return SettingsTile(
        title: title,
        subtitle: selected,
        leading: icon,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) => SelectionView(
                  title: title, selection: selection, selected: selected, onChosen: ptr)));
        });
  }

  SettingsTile _buildChooseMultiSettings(String title, List<String> selected, Icon icon,
      List<String> selection, Function(bool, String) ptr,
      {subtitle}) {
    return SettingsTile(
        title: title,
        leading: icon,
        subtitle: subtitle,
        //trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) => SelectMultiMenu(title, selected, selection, ptr)));
        });
  }

  SettingsTile _buildFilterSettings() {
    return SettingsTile(
        title: "Course filters",
        leading: Icon(Icons.filter_list),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => FilterMenu(info: this._info),
          ));
        });
  }

  Widget _buildAccountSettings() {
    return SettingsTile(
      title: "Login to canvas",
      subtitle: this._userName,
      leading: Icon(Icons.account_box),
      onTap: () {
        canvasLogin(context, this._info);
        setState(() => this._userName = this._info.user.name);
      },
    );
  }

  Widget _buildSettings() {
    return SettingsList(
      darkBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
      sections: [
        SettingsSection(
          title: "User",
          tiles: [
            _buildAccountSettings(),
            _buildChooseSettings("Corona rotation color", this._dropDownColor,
                Icon(Icons.color_lens), ["blue", "orange"], (String newval) {
              setState(() {
                this._dropDownColor = newval;
                this._info.setUserRotationColor(newval == 'blue' ? 0 : 1);
              });
            }),
            _buildChooseSettings("Level of education", this._dropDownEduType, Icon(Icons.menu_book),
                EducationData.keys.toList(), (String newval) {
              setState(() {
                this._dropDownEduType = newval;
                this._info.setUserEducationType(newval);
              });
            }),
            _buildChooseSettings("Faculty", this._dropDownFac, Icon(Icons.account_balance),
                EducationData[this._dropDownEduType].keys.toList(), (String newval) {
              setState(() {
                this._dropDownFac = newval;
                this._info.setUserFaculty(newval);
              });
            }),
            _buildChooseSettings(
                "Education type", this._dropDownEdu, Icon(Icons.school), getEducations(), (val) {
              setState(() {
                this._dropDownEdu = val;
                this._selectedUserGroups = [];
                showLoadingDialog("Loading group data");
                this._info.setUserEducation(val).then((v) {
                  setState(() {
                    this._userGroups = this._info.groupIds.keys.toList();
                    Navigator.pop(context);
                  });
                });
              });
            }),
            _buildChooseMultiSettings(
                "Groups", this._selectedUserGroups, Icon(Icons.group), this._userGroups,
                (valueSet, val) {
              setState(() {
                // TODO: maybe use a Set() for this ?
                if (valueSet && !this._selectedUserGroups.contains(val)) {
                  this._selectedUserGroups.add(val);
                } else if (!valueSet) {
                  this._selectedUserGroups.remove(val);
                }

                // TODO: this is probably inefficient
                this._info.setUserSelectedGroups(this._selectedUserGroups);
              });
            }),
          ],
        ),
        SettingsSection(
          title: 'Lectures',
          tiles: [
            _buildFilterSettings(),
            if (!kIsWeb)
              _buildChooseSettings(
                "Lecture update interval",
                this._updateInterval,
                Icon(Icons.update),
                LectureUpdateIntervals.keys.toList(),
                (val) {
                  setState(() {
                    this._updateInterval = val;
                    this._info.setUpdateInterval(val);
                  });
                },
              ),
            if (!kIsWeb)
              SettingsTile(
                title: "This weeks lectures latest update",
                leading: Icon(Icons.access_time),
                subtitle: this.latestTime,
              )
          ],
        ),
        SettingsSection(
          title: "Theme",
          tiles: [
            SettingsTile.switchTile(
                title: 'Dark mode',
                subtitle: 'Experimental',
                leading: Icon(Icons.invert_colors),
                onToggle: (value) {
                  setState(() {
                    this._info.setTheme(!value);
                    context.findAncestorStateOfType<VubState>().updateTheme(!value);
                  });
                },
                switchValue: !this._info.user.theme)
          ],
        ),
        if (!kIsWeb)
          SettingsSection(
            title: "Logging",
            tiles: [
              SettingsTile(
                title: 'Clear logs',
                subtitle: 'Logs are used to track bugs when you send us a bug report.',
                leading: Icon(Icons.file_copy),
                onTap: () => FLog.clearLogs(),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Settings")), body: _buildSettings());
  }
}
