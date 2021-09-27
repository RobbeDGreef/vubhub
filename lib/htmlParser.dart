import 'package:flutter/material.dart';
//import 'package:flutter_html/flutter_html.dart';
//import 'package:flutter_html/style.dart';

/// TODO: Create our own html parser, with one large selectable text widget and NO BUGS LIKE <p><a></a></p> is equal to a <p> tag like wth?????

String processHtmlData(String data) {
  return data;
  print(data);
  RegExp exp = new RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
  Iterable<RegExpMatch> matches = exp.allMatches(data);

  int i = 0;
  for (Match m in matches) {
    String url = data.substring(m.start + i, m.end + i);
    data = data.substring(0, m.start + i) +
        " <a href=\"" +
        url +
        "\">" +
        url +
        "</a> " +
        data.substring(m.end + i);
    i += 17 + url.length;
  }
  return data;
}

Widget htmlParse(String data) {
  data = processHtmlData(data);
  /*
  return Html(
    data: data,
    onLinkTap: (String url) => launch(url),
    customRender: {
      'p': (context, child, attr, el) => SelectableText(el.text, style: TextStyle(fontSize: 18)),
      'strong': (context, child, attr, el) =>
          SelectableText(el.text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      'em': (context, child, attr, el) =>
          SelectableText(el.text, style: TextStyle(fontStyle: FontStyle.italic, fontSize: 18)),
    },
    style: {
      'div': Style(display: Display.BLOCK, fontSize: FontSize(18)),
      'li': Style(fontSize: FontSize(18)),
    },
  );
  */
  return Text("Temporarily disabled");
}
