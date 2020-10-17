import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'const.dart';
import 'theming.dart';

class HelpView extends StatelessWidget {
  String _subject = "";
  String _body = "";

  Widget _openMoreInfo(BuildContext context, String info) {
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
      return Scaffold(
        backgroundColor: AlmostWhite,
        appBar: AppBar(title: Text("More info")),
        body:
            Padding(padding: EdgeInsets.all(12), child: Text(info, style: TextStyle(fontSize: 16))),
      );
    }));
  }

  void _sendEmail() async {
    if (this._subject.isEmpty) this._subject = "I did not provide a subject :/";
    if (this._body.isEmpty) this._body = "I did not provide a body :/";

    var url = 'mailto:$DeveloperEmail?subject=${this._subject}&body=${this._body}';
    if (await canLaunch(url))
      launch(url);
    else
      print("Could not send email :/");
  }

  @override
  Widget build(BuildContext context) {
    final textStyleHeader = TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: AlmostDark);
    final textStyleSub = TextStyle(fontSize: 20, color: AlmostDark);
    final textStyleText = TextStyle(fontSize: 16, color: AlmostDark);

    return ListView(
      padding: EdgeInsets.all(8),
      children: [
        Text(
          "Help me!",
          textAlign: TextAlign.center,
          style: textStyleHeader,
        ),
        SizedBox(height: 10),
        Text(
          "Where do I find my canvas access token?",
          style: textStyleSub,
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(WhereIsAccessTokenText, style: textStyleText),
        ),
        Text(
          "That seems hella sketchy dude.",
          style: textStyleSub,
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(IsSketchyText, style: textStyleText),
              TextButton(
                child: Text("You can read more about it here"),
                onPressed: () => _openMoreInfo(context, WhyAccessTokenText),
              ),
            ],
          ),
        ),
        Text(
          "Did you find a bug, thought of a cool feature, or you just want to say hi, then this is the place for you.",
          style: textStyleSub,
        ),
        SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
              hintText: "The subject",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(5))),
          onChanged: (val) => this._subject = val,
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: TextField(
            onChanged: (val) => this._body = val,
            maxLines: 99,
            decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "My crazy bug / Your crazy idea / Your friendly hello :)"),
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
    );
  }
}
