import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../canvas/canvasobjects.dart';
import '../canvas/canvasapi.dart';
import 'fileview.dart';
import 'pagedetails.dart';

class Modules extends StatelessWidget {
  CanvasApi _canvas;
  Course _details;

  Modules(Course details, CanvasApi canvas) {
    this._canvas = canvas;
    this._details = details;
  }

  Future<List<dynamic>> _getAllModuleItems() async {
    List<dynamic> modules = [];

    int i = 1;
    while (true) {
      print(i);
      List<dynamic> mods = await this
          ._canvas
          .get('api/v1/courses/${this._details.id}/modules?page=$i&include=items');

      modules.addAll(mods);

      if (mods.isEmpty) break;
      i++;
    }

    return modules;
  }

  @override
  Widget build(BuildContext context) {
    return PageDetails(
      title: "Modules",
      color: this._details.color,
      getData: () async {
        List<Module> modules = [];
        print("${this._details.id} ${this._canvas.accessToken}");

        var resp = await _getAllModuleItems();

        for (var mod in resp) {
          modules.add(Module(mod));
        }

        return modules;
      },
      buildTile: (_, mod) {
        Module module = mod;
        return Theme(
          data: Theme.of(context),
          child: ExpansionTile(
            title: Text(module.title),
            initiallyExpanded: true,
            children: module.items.map((e) {
              return Column(
                children: [
                  Divider(),
                  Row(
                    children: [
                      SizedBox(width: e.indent * 30.0),
                      Expanded(
                        child: ListTile(
                          title: Text(e.title),
                          leading: e.icon,
                          onTap: () {
                            Widget widget;
                            if (e.type == 'File') {
                              widget = FileView(e.url, this._canvas);
                            } else {
                              widget = WebView(
                                  initialUrl: e.url, javascriptMode: JavascriptMode.unrestricted);
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                    appBar: AppBar(
                                        title: Text(e.title), backgroundColor: this._details.color),
                                    body: widget),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
      noDataText: "There are no modules for this course",
    );
  }
}
