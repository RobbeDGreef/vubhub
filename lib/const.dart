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
final String LibraryApiUrl =
    "https://reservation.affluences.com/api/resources/1625d777-78f9-4085-b276-ce05fe99850f/available?date=";

final String LibraryReserveUrl = "https://reservation.affluences.com/api/reserve/";
final DefaultUserColor = 0;
final DefaultUserEduType = "Bachelor";
final DefaultUserFac = "Science and Bio-engineering Sciences";
final DefaultUserEdu = "Computer Science";

final VubBlue = Color.fromARGB(0xFF, 0, 52, 154);
final VubOrange = Color.fromARGB(0xFF, 251, 106, 16);

final Pattern emailPattern =
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
