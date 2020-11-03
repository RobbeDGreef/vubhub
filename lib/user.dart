import 'dart:convert';

import 'educationdata.dart';

class User {
  String name;
  int id;
  String email;
  String locale;
  String accessToken;
  int rotationColor;
  String educationType;
  String faculty;
  String education;
  List<String> selectedGroups = [];
  bool theme = true;

  User.empty();
  User({this.accessToken});
  User.defaults() {
    this.educationType = EducationData.keys.first;
    this.faculty = EducationData[this.educationType].keys.first;
  }

  static final int stringListSize = 5;

  User.fromJson(Map<String, dynamic> data) {
    this.name = data['name'];
    this.id = data['id'];
    this.email = data['email'];
    this.locale = data['locale'];
    this.accessToken = data['accessToken'];
    this.rotationColor = data['rotationColor'];
    this.educationType = data['educationType'];
    this.faculty = data['faculty'];
    this.education = data['education'];
    this.selectedGroups = [];
    this.theme = data['theme'] ?? true;
    for (String s in data['selectedGroups']) {
      this.selectedGroups.add(s);
    }
  }

  String toJson() {
    Map<String, dynamic> json = {
      'name': this.name,
      'id': this.id,
      'email': this.email,
      'locale': this.locale,
      'accessToken': this.accessToken,
      'rotationColor': this.rotationColor,
      'educationType': this.educationType,
      'faculty': this.faculty,
      'education': this.education,
      'selectedGroups': this.selectedGroups,
      'theme': this.theme,
    };

    return jsonEncode(json);
  }
}
