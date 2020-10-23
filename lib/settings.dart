import 'package:flushbar/flushbar.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import "package:settings_ui/settings_ui.dart";

import "infohandler.dart";
import 'const.dart';

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

    return Scaffold(appBar: AppBar(title: Text(this._title)), body: ListView(children: tiles));
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
  List<String> _userGroups = [];
  InfoHandler _info;
  List<String> _selectedUserGroups;

  List<String> getEducations() {
    return EducationData[this._dropDownEduType][this._dropDownFac].keys.toList();
  }

  _SettingsMenuState(InfoHandler info) {
    this._info = info;
    this._dropDownColor = info.colorIntToString(info.getUserColor());
    this._dropDownEduType = info.getUserEduType();
    this._dropDownFac = info.getUserFac();
    this._dropDownEdu = info.getUserEdu();
    this._selectedUserGroups = info.getSelectedUserGroups();
    this._userGroups = info.getUserGroups();
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

  Widget _buildSelectionScreen(
      String title, List<String> selection, String selected, Function(String) callback) {
    List<Widget> tiles = List();
    for (String select in selection) {
      tiles.add(ListTile(
          title: Text(select),
          onTap: () {
            Navigator.pop(context);
            callback(select);
          }));
      tiles.add(Divider());
    }

    return Scaffold(appBar: AppBar(title: Text(title)), body: ListView(children: tiles));
  }

  SettingsTile _buildChooseSettings(
      String title, String selected, Icon icon, List<String> selection, Function(String) ptr) {
    if (selected.length > 20) {
      selected = selected.substring(0, 20) + "...";
    }
    return SettingsTile(
        title: title,
        subtitle: selected,
        leading: icon,
        //trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) =>
                  _buildSelectionScreen(title, selection, selected, ptr)));
        });
  }

  SettingsTile _buildChooseMultiSettings(String title, List<String> selected, Icon icon,
      List<String> selection, Function(bool, String) ptr) {
    return SettingsTile(
        title: title,
        leading: icon,
        //trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) => SelectMultiMenu(title, selected, selection, ptr)));
        });
  }

  void _canvasLogin() {
    final loginUrl =
        "https://canvas.vub.be/login/oauth2/auth?client_id=170000000000044&response_type=code&mobile=1&purpose=TestingStuff&redirect_uri=https://canvas.instructure.com/login/oauth2/auth";
    final tokenUrlBase =
        "https://canvas.vub.be/login/oauth2/token?&redirect_uri=urn:ietf:wg:oauth:2.0:oob&grant_type=authorization_code&client_id=170000000000044&client_secret=3sxR3NtgXRfT9KdpWGAFQygq6O9RzLN021h2lAzhHUZEeSQ5XGV41Ddi5iutwW6f";

    // Clear cookies so that the user can re-login.
    CookieManager().clearCookies();

        Navigator.of(context).push(
          MaterialPageRoute(
        builder: (BuildContext context) {
              return Scaffold(
            appBar: AppBar(title: Text("Login")),
            body: WebView(
              initialUrl: loginUrl,
              javascriptMode: JavascriptMode.unrestricted,
              onPageFinished: (url) {
                if (url.startsWith('https://canvas.instructure.com')) {
                  final code = Uri.parse(url).queryParameters['code'];
                  String tokenUrl = tokenUrlBase + "&code=" + code;
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
                      this._info.userLogin(json['access_token']);
                                  setState(() {
                        this._userName = json['user']['name'];
                                  });
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

  Widget _buildAccountSettings() {
    return SettingsTile(
      title: "Login to canvas",
      subtitle: this._userName,
      leading: Icon(Icons.account_box),
      onTap: () {
        _canvasLogin();
      },
    );
  }

  Widget _buildSettings() {
    return SettingsList(sections: [
      SettingsSection(
        title: "User",
        tiles: [
          _buildAccountSettings(),
          _buildChooseSettings(
              "Color", this._dropDownColor, Icon(Icons.color_lens), ["blue", "orange"],
              (String newval) {
            setState(() {
              this._dropDownColor = newval;
              this._info.setUserColor(this._info.colorStringToInt(newval));
            });
          }),
          _buildChooseSettings("Level of education", this._dropDownEduType, Icon(Icons.menu_book),
              EducationData.keys.toList(), (String newval) {
            setState(() {
              this._dropDownEduType = newval;
              this._info.setUserEduType(newval);
            });
          }),
          _buildChooseSettings("Faculty", this._dropDownFac, Icon(Icons.account_balance),
              EducationData[this._dropDownEduType].keys.toList(), (String newval) {
            setState(() {
              this._dropDownFac = newval;
              this._info.setUserFac(newval);
            });
          }),
          _buildChooseSettings(
              "Education type", this._dropDownEdu, Icon(Icons.school), getEducations(), (val) {
            setState(() {
              this._dropDownEdu = val;
              this._selectedUserGroups = [];
              showLoadingDialog("Loading group data");
              this._info.setUserEdu(val).then((v) {
                setState(() {
                  this._userGroups = this._info.getUserGroups();
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
              this._info.setUserGroups(this._selectedUserGroups);
            });
          }),
        ],
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Settings")), body: _buildSettings());
  }
}
