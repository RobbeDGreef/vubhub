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

final WhereIsAccessTokenText = """
Your canvas access token can be generated at https://canvas.vub.be/profile/settings 
by clicking on the orange 'new accesscode' button. You can then copy the token 
and paste it manually in the app under settings > accounts > authentication token.
"""
    .replaceAll('\n', '');

final IsSketchyText = """
That's because it kinda is, we are currently a bit in legal limbo with Canvas's 
terms of service because of this but since this is still a alpha/beta app, you are not 
a user, you are a tester. Therefor we can ask you to do this, but we are not, if 
anyone over at Canvas is reading this :| . We are simply nudging that manually 
generating this token is something you COULD do, not something you SHOULD do.
"""
    .replaceAll('\n', '');

final WhyAccessTokenText = """
You may have noticed that you cannot login to Canvas directly from within the app. 
This is because we (the developers) need a 'client key' as they are referred to, 
issued by the institution (the VUB in this case) in order for us to be able to use 
canvas's API's. Since this is an unofficial app, we currently do not have a key like 
that. The only other option for us was to use what Canvas refers to as an access token. 
These tokens are normally supposed to be used by developers (us) to test features before 
they have implemented the user login stuff. However telling your users to generate 
these keys manually and add them to your application would be a violation of the Canvas's 
terms of service, so, we are not telling you to do anything. You don't need canvas to 
use this app and you are most likely a tester for this app and therefor partially a developer. 
But, in case you decide on your own that you would like to add some of Canvas's functionality 
to this app, you could do so by going to your VUB canvas profile settings at 
canvas.vub.be/profile/settings and click the 'new access token' button, generate 
one and paste it in the app under settings > accounts > authentication token. """
    .replaceAll('\n', '');

final DeveloperEmail = "robbedg@gmail.com";

final WhoAreWeText =
    "With we I mostly refer to me (Robbe De Greef, currently the lead developer) and more recently also Thomas Vandermotten. We are two first year Computer Science bachelors who (among most of our class) were very annoyed by the VUB's cumbersome class schedule system. So I decided to write an app for it and then thought it would be fun to add some more functionality. If you want to contact us you can do so in the help tab, which you can find in the app drawer. We hope this app can help you in your daily life and please let us know if you want to change something.";

final CurrentAppRelease = "0.0.1 alpha";

final VubNewsUrl = "https://today.vub.be/nl/nieuws";
final VubNewsPer = 100;

final CanvasLoginUrl =
    "https://canvas.vub.be/login/oauth2/auth?client_id=170000000000044&response_type=code&mobile=1&purpose=TestingStuff&redirect_uri=https://canvas.instructure.com/login/oauth2/auth";
final CanvasTokenUrlBase =
    "https://canvas.vub.be/login/oauth2/token?&redirect_uri=urn:ietf:wg:oauth:2.0:oob&grant_type=authorization_code&client_id=170000000000044&client_secret=3sxR3NtgXRfT9KdpWGAFQygq6O9RzLN021h2lAzhHUZEeSQ5XGV41Ddi5iutwW6f";

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
