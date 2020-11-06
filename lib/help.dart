import 'package:f_logs/f_logs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mailer/flutter_mailer.dart';
import 'package:path_provider/path_provider.dart';

import 'const.dart';

class HelpView extends StatelessWidget {
  String _subject = "";
  String _body = "";

  void _sendEmail() async {
    if (this._subject.isEmpty) this._subject = "I did not provide a subject :/";
    if (this._body.isEmpty) this._body = "I did not provide a body :/";

    FLog.exportLogs();
    final MailOptions mailOptions = MailOptions(
      subject: this._subject,
      body: this._body,
      recipients: ['robbedegreef@gmail.com'],
      attachments: ["${(await getExternalStorageDirectory()).path}/FLogs/flog.txt"],
    );
    FlutterMailer.send(mailOptions);
  }

  @override
  Widget build(BuildContext context) {
    final textStyleHeader = TextStyle(fontSize: 30, fontWeight: FontWeight.w600);
    final textStyleSub = TextStyle(fontSize: 20);
    final textStyleText =
        TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyText1.color);
    final textBoldStyleText = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).textTheme.bodyText1.color,
    );

    return Scaffold(
      appBar: AppBar(title: Text("Help")),
      body: ListView(
        padding: EdgeInsets.all(8),
        children: [
          Text(
            "Help me!",
            textAlign: TextAlign.center,
            style: textStyleHeader,
          ),
          SizedBox(height: 10),
          Text(
            "My class schedule is all messed up?",
            style: textStyleSub,
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: RichText(
              text: TextSpan(
                style: textStyleText,
                children: [
                  TextSpan(text: ClassScheduleMessedUp),
                  TextSpan(text: ClassScheduleMessedUpBold, style: textBoldStyleText),
                ],
              ),
            ),
          ),
          Text(
            "Did you find a bug, thought of a cool feature, or you just want to say hi, then this is the place for you.",
            style: textStyleSub,
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text("The subject"),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.only(left: 8, right: 8),
            child: TextField(
              decoration: InputDecoration(
                  hintText: "The subject",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(5))),
              onChanged: (val) => this._subject = val,
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text("The body"),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.only(left: 8, right: 8),
            child: SizedBox(
              height: 300,
              child: TextField(
                onChanged: (val) => this._body = val,
                maxLines: 99,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "My crazy bug / Your crazy idea / Your friendly hello :)"),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(right: 5),
              child: TextButton(
                child: Text("Send the mail"),
                onPressed: () => _sendEmail(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
