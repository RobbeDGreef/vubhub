import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:open_file/open_file.dart';

import '../canvas/canvasobjects.dart';
import '../canvas/canvasapi.dart';

import '../const.dart';

class FileView extends StatelessWidget {
  CanvasFile file;
  Future<dynamic> apiFuture;

  FileView(String url, CanvasApi canvas) {
    apiFuture = canvas.get(url.substring(url.indexOf('.be') + 3));
  }

  Widget _buildPreview(String ext) {
    if (ext == 'pdf') {
      return FutureBuilder(
        future: PDFDocument.fromURL(this.file.url),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return PDFViewer(document: snapshot.data);
          }
          return Center(
            child: Container(child: CircularProgressIndicator(), width: 70, height: 70),
          );
        },
      );
    } else if (FileTypes.indexOf(ext) <= LastPlainTextFileType && FileTypes.indexOf(ext) != -1) {
      return FutureBuilder(
        future: http.get(this.file.url),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text(snapshot.data.body);
          }
          return Center(
            child: Container(child: CircularProgressIndicator(), width: 70, height: 70),
          );
        },
      );
    }

    return Center(child: Text("Cannot preview this filetype"));
  }

  Future<String> _download({String path}) async {
    var res = await http.get(file.url);

    if (path == null)
      path = "${(await DownloadsPathProvider.downloadsDirectory).path}/${file.name}";

    File f = File(path);
    if (await f.exists()) {
      f = File(path + '(1)');
    }
    await f.writeAsBytes(res.bodyBytes);
    return path;
  }

  void _open() async {
    String path = '${(await getTemporaryDirectory()).path}/${file.name}';
    path = await _download(path: path);
    OpenFile.open(path);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: apiFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          file = CanvasFile(snapshot.data);
          String ext = file.name.substring(file.name.lastIndexOf('.') + 1).toLowerCase();
          return Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name, style: TextStyle(fontSize: 25)),
                SizedBox(height: 10),
                Text(FileTypeNames[ext] ?? ext, style: TextStyle(fontSize: 16)),
                Text(DateFormat("'Last updated at' d MMMM yyyy HH:mm").format(file.updated),
                    style: TextStyle(fontSize: 16)),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(child: Text("Download"), onPressed: () => _download()),
                    TextButton(child: Text("Open"), onPressed: () => _open()),
                  ],
                ),
                Divider(),
                Expanded(child: _buildPreview(ext)),
              ],
            ),
          );
        } else {
          return Center(
            child: Container(child: CircularProgressIndicator(), width: 70, height: 70),
          );
        }
      },
    );
  }
}

class FilesView {}
