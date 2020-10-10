import "package:flutter/material.dart";

final Map<String, Map<String, Map<String, String>>> EducationData = {
  "Bachelor": {
    "Letteren en wijsbegeerde": {"History": "SWS_BA_LW_NL_RS_Geschiedenis_SET"},
    "Recht en criminiologie": {},
    "Psychologie": {},
    "Sociale wetenschappen": {},
    "Ingenieurswetenschappen": {},
    "Science and Bio-engineering Sciences": {
      "Bio-engeneering": "",
      "Biology": "",
      "Chemistry": "",
      "Computer Science": "SWS_BA_WE_NL_RS_Computerwetenschappen_SET"
    }
  },
  "Master": {
    "Letteren en wijsbegeerde": {"Gender en diversiteit": ""},
    "Recht en criminiologie": {},
    "Psychologie": {},
    "Sociale wetenschappen": {},
    "Ingenieurswetenschappen": {},
    "Science and Bio-engineering Sciences": {
      "Bio-engeneering": "",
      "Biology": "",
      "Chemistry": "",
      "Computer Science": ""
    }
  }
};

final String VubTimetablesEntryUrl =
    "https://splus.cumulus.vub.ac.be/SWS/v3/evenjr/NL/STUDENTSET/studentset.aspx";

final DefaultUserColor = 0;
final DefaultUserEduType = "Bachelor";
final DefaultUserFac = "Science and Bio-engineering Sciences";
final DefaultUserEdu = "Computer Science";

final VubBlue = Color.fromARGB(0xFF, 0, 52, 154);
final VubOrange = Color.fromARGB(0xFF, 251, 106, 16);
