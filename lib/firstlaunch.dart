import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:vubhub/educationdata.dart';

import 'infohandler.dart';
import 'settings/selection.dart';
import 'settings/settings.dart';

class FirstLaunchSetup extends StatefulWidget {
  InfoHandler info;
  Function() close;

  FirstLaunchSetup({this.info, this.close});

  @override
  _FirstLaunchSetupState createState() =>
      _FirstLaunchSetupState(info: this.info, close: this.close);
}

class _FirstLaunchSetupState extends State<FirstLaunchSetup> {
  InfoHandler info;
  Function() close;

  _FirstLaunchSetupState({this.info, this.close});

  Widget _buildSettingTile(String title, String selected, Icon icon, List<String> selectable,
      Function(String) onSelect) {
    return SettingsTile(
      title: title,
      subtitle: selected,
      leading: icon,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SelectionView(
            title: title,
            selected: selected,
            selection: selectable,
            onChosen: onSelect,
          ),
        ),
      ),
    );
  }

  Widget _buildMutliSettingTile(String title, List<String> selected, Icon icon,
      List<String> selectable, Function(bool, String) onSelect) {
    return SettingsTile(
      title: title,
      leading: icon,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SelectMultiMenu(
            title,
            selected,
            selectable,
            onSelect,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 40, left: 16, right: 16),
      child: ListView(
        children: [
          Text(
            "Welcome",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w400, color: Colors.grey[700]),
          ),
          Padding(
            padding: EdgeInsets.only(left: 1),
            child: Text(
              "Please configure the following settings to use the app properly.",
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 8, right: 8, top: 40),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 5.0,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListView(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      _buildSettingTile(
                        "Level of education",
                        this.info.user.educationType,
                        Icon(Icons.menu_book),
                        EducationData.keys.toList(),
                        (edu) => setState(() => this.info.setUserEducationType(edu)),
                      ),
                      Divider(),
                      _buildSettingTile(
                        "Department",
                        this.info.user.faculty,
                        Icon(Icons.account_balance),
                        EducationData[this.info.user.educationType].keys.toList(),
                        (edu) => setState(() => this.info.setUserFaculty(edu)),
                      ),
                      Divider(),
                      _buildSettingTile(
                        "Education",
                        this.info.user.education,
                        Icon(Icons.school),
                        EducationData[this.info.user.educationType][this.info.user.faculty]
                            .keys
                            .toList(),
                        (edu) => setState(() => this.info.setUserEducation(edu)),
                      ),
                      Divider(),
                      _buildMutliSettingTile(
                        "Groups",
                        this.info.user.selectedGroups,
                        Icon(Icons.group),
                        (this.info.groupIds?.keys ?? []).toList(),
                        (valueSet, val) {
                          var selectedGroups = this.info.user.selectedGroups;
                          if (valueSet && selectedGroups.contains(val)) {
                            selectedGroups.add(val);
                          } else if (!valueSet) {
                            selectedGroups.remove(val);
                          }

                          this.info.setUserSelectedGroups(selectedGroups);
                        },
                      ),
                      Divider(thickness: 2),
                      SettingsTile(
                          title: "Log in to canvas (optional)",
                          subtitle: this.info.user.name,
                          leading: Icon(Icons.account_box),
                          onTap: () {
                            canvasLogin(context, this.info);
                          }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: TextButton(
              child: Text("Done"),
              onPressed: () => this.close(),
            ),
          ),
        ],
      ),
    );
  }
}
