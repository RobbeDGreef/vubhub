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
          _settingDropdown("Color", ["blue", "orange"], this.dropDownColor, (String newval) {
            setState(() {
              this.dropDownColor = newval;
              this.info.setUserColor(this.info.colorStringToInt(newval));
            });
          }),
          _settingDropdown("Level of education", EducationData.keys.toList(), this.dropDownEduType,
              (String newval) {
            setState(() {
              this.dropDownEduType = newval;
              this.info.setUserEduType(newval);
            });
          }),
          _settingDropdown(
              "Faculty", EducationData[this.dropDownEduType].keys.toList(), this.dropDownFac,
              (String newval) {
            setState(() {
              this.dropDownFac = newval;
              this.info.setUserFac(newval);
            });
          }),
          _settingDropdown("Education type", getEducations(), this.dropDownEdu, (String newval) {
            print("new: $newval");
            setState(() {
              this.dropDownEdu = newval;
              this.info.setUserEdu(newval);
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
