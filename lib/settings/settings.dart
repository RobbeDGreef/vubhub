import 'dart:convert';
import 'dart:io';

import 'package:f_logs/f_logs.dart';
import 'package:flushbar/flushbar.dart';
import "package:flutter/material.dart";
import "package:settings_ui/settings_ui.dart";
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

import '../infohandler.dart';
import '../const.dart';
import '../educationdata.dart';
import '../main.dart';
import 'selection.dart';

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
            onPageFinished: (url) {
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
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    // In development
    //_popupDesktop();
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
