import "package:flutter/material.dart";

final String VubTimetablesEntryUrl =
    "https://splus.cumulus.vub.ac.be/SWS/v3/evenjr/NL/STUDENTSET/studentset.aspx";
final String LibraryApiUrl =
    "https://reservation.affluences.com/api/resources/1625d777-78f9-4085-b276-ce05fe99850f/available?date=";

final String LibraryReserveUrl = "https://reservation.affluences.com/api/reserve/";
final String CanvasUrl = "https://canvas.vub.be/";
final DefaultUserColor = 0;
final DefaultUserEduType = "Bachelor";
final DefaultUserFac = "Science and Bio-engineering Sciences";
final DefaultUserEdu = "Computer Science";

final VubBlue = Color.fromARGB(0xFF, 0, 52, 154);
final VubOrange = Color.fromARGB(0xFF, 251, 106, 16);

final Pattern emailPattern =
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

final VubMapWidth = 3267;
final VubMapHeight = 4000;

final ClassScheduleMessedUp =
    "If your class schedule is not showing the correct data (no data, duplicates, ...), check if you selected the correct groups in Settings > groups. If the groups are correct try removing the app's saved data in your phones settings, ";
final ClassScheduleMessedUpBold =
    "however please first send us a bug report using the forms below, removing the data will also remove the log files we use to identify problems.";

final DeveloperEmail = "robbedg@gmail.com";

final WhoAreWeText =
    "With we I currently actually refer to me (Robbe De Greef), I am a freshman computer science student at the Vrije Universiteit Brussel. I made this app because I found that the VUB was lacking a simple way to access class schedules and afterwards thought it would be fun to add some more functionality. If you like the app, please let me know, I would love to get some feedback and any bug reports or features requests can be requested in the Help tab. I hope you like it :)";

final VubNewsUrl = "https://today.vub.be/nl/nieuws";
final VubNewsPer = 100;

final CanvasLoginUrl =
    "https://canvas.vub.be/login/oauth2/auth?client_id=170000000000044&response_type=code&mobile=1&purpose=VubHub&redirect_uri=https://canvas.instructure.com/login/oauth2/auth";
final CanvasTokenUrlBase =
    "https://canvas.vub.be/login/oauth2/token?&redirect_uri=urn:ietf:wg:oauth:2.0:oob&grant_type=authorization_code&client_id=170000000000044&client_secret=3sxR3NtgXRfT9KdpWGAFQygq6O9RzLN021h2lAzhHUZEeSQ5XGV41Ddi5iutwW6f";

final VubhubServerUrl = 'http://vubhubserver.ddns.net:5000';
final CorsProxyUrl = VubhubServerUrl + '/corsproxy/';

final FileTypeNames = {
  // Programing
  'rkt': 'Dr racket (scheme) source code',
  'c': 'C source code file',
  'cpp': 'C++ source code file',
  'cc': 'C/C++ source code file',
  'h': 'C/C++ header file',
  'java': 'Java source code file',
  'class': 'Java class file',
  'kt': 'Kotlin source code file',
  'py': 'Python script file',
  'js': 'JavaScript source file',
  'php': 'PHP source file',
  'html': 'HTML file',
  'htm': 'HTML file',
  'css': 'Cascading Style Sheet (CSS)',

  'zip': 'Zip compressed file',
  'tar.gz': 'Tarball compressed file',
  'rar': 'RAR file',
  'pkg': 'Package file',
  'deb': 'Debian file',
  '7z': '7-Zip compressed file',

  // Regular documents
  'txt': 'Plain text',
  'tex': 'LaTeX document',
  'doc': 'Microsoft Word document',
  'docx': 'Microsoft Word document',
  'odt': 'OpenOffice Writer document',
  'pdf': 'Portable Document Format file (pdf)',

  'ppt': 'PowerPoint presentation',
  'pps': 'PowerPoint slideshow',
  'pptx': 'PowerPoint Open XML presentation',
  'odp': 'OpenOffice Impress presentation',
  'key': 'Keynote presentation',

  // Spreadsheets
  'ods': 'OpenOffice Calc spreadsheet',
  'xls': 'Microsoft Excel file',
  'xlsm': 'Microsoft Excel file with macros',
  'xlsx': 'Microsoft Excel Open XML spreadsheet',

  // Video and audio
  'mp3': 'MP3 Audio file',
  'mp4': 'MP4 Video file',
};

final FileTypes = FileTypeNames.keys.toList();
final LastPlainTextFileType = FileTypes.indexOf('txt');
final LectureUpdateIntervals = {
  'Every hour': Duration(hours: 1),
  'Every 8 hours': Duration(hours: 8),
  'Every day': Duration(days: 1),
  'Every week': Duration(days: 7),
  'Never': Duration.zero,
};
