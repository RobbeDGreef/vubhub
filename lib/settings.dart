import "package:flutter/material.dart";
import "classinfo.dart";
import "package:settings_ui/settings_ui.dart";

class SettingsMenu extends StatefulWidget {
  ClassInfo info;

  SettingsMenu(ClassInfo info) {
    this.info = info;
  }

  @override
  _SettingsMenuState createState() => _SettingsMenuState(this.info);
}

class _SettingsMenuState extends State<SettingsMenu> {
  String dropDownVal;
  ClassInfo info;

  _SettingsMenuState(ClassInfo info) {
    this.info = info;
    dropDownVal = info.getUserColorString();
  }

  String tosay = "hello";
  Widget _buildSettings() {
    return SettingsList(sections: [
      SettingsSection(
        title: "Common",
        tiles: [
          SettingsTile(
              title: "Color",
              trailing: DropdownButton(
                  items: <String>["blue", "orange"]
                      .map<DropdownMenuItem<String>>((String item) {
                    return DropdownMenuItem(child: Text(item), value: item);
                  }).toList(),
                  value: this.dropDownVal,
                  onChanged: (String newval) {
                    setState(() {
                      this.dropDownVal = newval;
                      this.info.updateColorFromString(newval);
                    });
                  })),
        ],
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Settings")), body: _buildSettings());
  }
}
