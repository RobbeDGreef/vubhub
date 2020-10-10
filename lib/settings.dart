import "package:flutter/material.dart";
import 'package:fvub/const.dart';
import "infohandler.dart";
import "const.dart";
import "package:settings_ui/settings_ui.dart";

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
  InfoHandler info;

  List<String> getEducations() {
    return EducationData[this.dropDownEduType][this.dropDownFac].keys.toList();
  }

  _SettingsMenuState(InfoHandler info) {
    this.info = info;
    this.dropDownColor = info.colorIntToString(info.getUserColor());
    this.dropDownEduType = info.getUserEduType();
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
              this.info.setUserEdu(val).then((v) {
            setState(() {
                  this.userGroups = this.info.getUserGroups();
                });
              });
            });
          }),
          // TODO
          _settingDropdown("Group", getEducations(), this.dropDownEdu, (String newval) {
            print("new: $newval");
            setState(() {
              this.dropDownEdu = newval;
              this.info.setUserEdu(newval);
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
