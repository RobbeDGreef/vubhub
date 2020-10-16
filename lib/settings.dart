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

  Widget _buildAccountSettings() {
    return SettingsTile(
      title: "Accounts",
      leading: Icon(Icons.account_box),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext contetx) {
              return Scaffold(
                appBar: AppBar(title: Text("Accounts")),
                body: SettingsList(
                  sections: [
                    SettingsSection(
                      title: "Booking information",
                      tiles: [
                        SettingsTile(
                          title: "VUB email",
                          leading: Icon(Icons.email),
                          trailing: Container(
                            width: 200,
                            child: Form(
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              child: TextFormField(
                                initialValue: this._info.getUserEmail(),
                                onEditingComplete: () => Form.of(primaryFocus.context).save(),
                                validator: (String arg) {
                                  RegExp regex = new RegExp(emailPattern);
                                  if (!regex.hasMatch(arg)) {
                                    return "Please enter valid email!";
                                  } else {
                                    return null;
                                  }
                                },
                                onSaved: (val) {
                                  this._info.setUserEmail(val);
                                  FocusScopeNode curFocus = FocusScope.of(context);
                                  if (!curFocus.hasPrimaryFocus) {
                                    curFocus.unfocus();
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: "Canvas information",
                      tiles: [
                        SettingsTile(
                          title: "Authentication token",
                          subtitle: this._info.getUserCanvasAuthToken() != null
                              ? "User authentication token set"
                              : "No user authentication token loaded",
                          leading: Icon(Icons.vpn_key),
                          trailing: TextButton(
                            child: Text(
                              "Paste from\nclipboard",
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all<Color>(Colors.blue)),
                            onPressed: () {
                              Clipboard.getData('text/plain').then((val) {
                                // TODO: do better checks than this
                                if (val.text.length != 70) {
                                  Flushbar(
                                    title: "Oh oh, that does not seem to be a valid user token.",
                                    message: val.text,
                                    duration: Duration(seconds: 2),
                                    margin: EdgeInsets.all(8),
                                    borderRadius: 8,
                                    animationDuration: Duration(milliseconds: 500),
                                  ).show(context);
                                } else {
                                  Flushbar(
                                    title: "User token set",
                                    message: val.text,
                                    duration: Duration(seconds: 2),
                                    margin: EdgeInsets.all(8),
                                    borderRadius: 8,
                                    animationDuration: Duration(milliseconds: 500),
                                  ).show(context);
                                  setState(() {
                                    this._info.setUserCanvasAuthToken(val.text);
                                  });
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
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
              "Education type", this._dropDownEdu, Icon(Icons.class_), getEducations(), (val) {
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
