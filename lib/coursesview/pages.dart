import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../canvas/canvasapi.dart';
import '../canvas/canvasobjects.dart';
import '../htmlParser.dart';
import 'pagedetails.dart';

class PageView extends StatelessWidget {
  CanvasPage _page;
  Course _details;
  CanvasApi _canvas;

  PageView(CanvasPage page, Course details, CanvasApi canvas) {
    this._page = page;
    this._details = details;
    this._canvas = canvas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(this._page.name)),
      body: FutureBuilder(
        future: this._canvas.get('api/v1/courses/${this._details.id}/pages/${this._page.url}'),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return htmlParse(snapshot.data['body']);
          }

          return Center(
            child: Container(width: 50, height: 50, child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

class PagesView extends StatelessWidget {
  Course _details;
  CanvasApi _canvas;
  Future<dynamic> _pagesFuture;

  PagesView(Course details, CanvasApi canvas) {
    this._details = details;
    this._canvas = canvas;
  }

  @override
  Widget build(BuildContext context) {
    return PageDetails(
      color: this._details.color,
      title: "Pages",
      noDataText: "There are no pages for this course",
      getData: () async {
        List<dynamic> data = await this._canvas.get('api/v1/courses/${this._details.id}/pages');
        List<CanvasPage> pages = [];
        for (Map<String, dynamic> e in data) {
          pages.add(CanvasPage(e));
        }

        return pages;
      },
      buildTile: (context, item) {
        CanvasPage page = item;
        return Card(
          child: ListTile(
            title: Text(page.name),
            subtitle: Text(DateFormat("d MMMM yyyy 'at' HH:mm").format(page.created)),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PageView(page, this._details, this._canvas))),
          ),
        );
      },
    );
  }
}
