import "package:flutter/material.dart";
import 'package:fvub/const.dart';
import "infohandler.dart";
import "const.dart";
import "package:settings_ui/settings_ui.dart";

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
  String dropDownColor;
  String dropDownEduType = EducationData.keys.first;
  String dropDownFac = EducationData[EducationData.keys.first].keys.first;
  String dropDownEdu;
  String dropDownUserGroup;
  List<String> userGroups = [];
  InfoHandler info;
  List<String> selectedUserGroups;

  List<String> getEducations() {
    return EducationData[this.dropDownEduType][this.dropDownFac].keys.toList();
  }

  _SettingsMenuState(InfoHandler info) {
    this.info = info;
    this.dropDownColor = info.colorIntToString(info.getUserColor());
    this.dropDownEduType = info.getUserEduType();
    this.dropDownFac = info.getUserFac();
    this.dropDownEdu = info.getUserEdu();
    this.selectedUserGroups = info.getSelectedUserGroups();
    this.userGroups = info.getUserGroups();
  }

  Widget _selectionScreen(
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

  SettingsTile _settingChoose(
      String title, String selected, Icon icon, List<String> selection, Function(String) ptr) {
    return SettingsTile(
        title: title,
        subtitle: selected,
        leading: icon,
        //trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) =>
                  _selectionScreen(title, selection, selected, ptr)));
        });
  }

  SettingsTile _settingChooseMulti(String title, List<String> selected, Icon icon,
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

  SettingsTile _settingDropdown(
      String title, List<String> items, String item, Function(String) ptr) {
    return SettingsTile(
        title: title,
        trailing: DropdownButton(
            items: items.map<DropdownMenuItem<String>>((String item) {
              return DropdownMenuItem(child: Text(item), value: item);
            }).toList(),
            value: item,
            onChanged: ptr));
  }

  String tosay = "hello";
  Widget _buildSettings() {
    return SettingsList(sections: [
      SettingsSection(
        title: "User",
        tiles: [
          _settingChoose("Color", this.dropDownColor, Icon(Icons.color_lens), ["blue", "orange"],
              (String newval) {
            setState(() {
              this.dropDownColor = newval;
              this.info.setUserColor(this.info.colorStringToInt(newval));
            });
          }),
          _settingChoose("Level of education", this.dropDownEduType, Icon(Icons.menu_book),
              EducationData.keys.toList(), (String newval) {
            setState(() {
              this.dropDownEduType = newval;
              this.info.setUserEduType(newval);
            });
          }),
          _settingChoose("Faculty", this.dropDownFac, Icon(Icons.domain),
              EducationData[this.dropDownEduType].keys.toList(), (String newval) {
            setState(() {
              this.dropDownFac = newval;
              this.info.setUserFac(newval);
            });
          }),
          _settingChoose("Education type", this.dropDownEdu, Icon(Icons.class_), getEducations(),
              (val) {
            setState(() {
              this.dropDownEdu = val;
              this.selectedUserGroups = [];
              this.info.setUserEdu(val).then((v) {
                setState(() {
                  this.userGroups = this.info.getUserGroups();
                });
              });
            });
          }),
          _settingChooseMulti("Groups", this.selectedUserGroups, Icon(Icons.group), this.userGroups,
              (valueSet, val) {
            setState(() {
              // TODO: maybe use a Set() for this ?
              if (valueSet && !this.selectedUserGroups.contains(val)) {
                this.selectedUserGroups.add(val);
              } else if (!valueSet) {
                this.selectedUserGroups.remove(val);
              }

              // TODO: this is probably inefficient
              this.info.setUserGroups(this.selectedUserGroups);
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
