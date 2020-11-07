import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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

  static Widget _buildPreview(CanvasFile file) {
    String ext = file.name.substring(file.name.lastIndexOf('.') + 1).toLowerCase();
    if (ext == 'pdf') {
      return FutureBuilder(
        future: PDFDocument.fromURL(file.url),
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
        future: http.get(file.url),
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

  static Future<String> _download(CanvasFile file, {String path}) async {
    var res = await http.get(file.url);

    //TODO: Change path_provider etc etc u know
    if (path == null) path = "/storage/emulated/0/Download/${file.name}";

    File f = File(path);
    if (await f.exists()) {
      f = File(path + '(1)');
    }
    await f.writeAsBytes(res.bodyBytes);
    return path;
  }

  static void _open(CanvasFile file) async {
    String path = '${(await getTemporaryDirectory()).path}/${file.name}';
    path = await _download(file, path: path);
    OpenFile.open(path);
  }

  static Widget buildFile(CanvasFile file) {
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
              TextButton(child: Text("Download"), onPressed: () => _download(file)),
              TextButton(child: Text("Open"), onPressed: () => _open(file)),
            ],
          ),
          Divider(),
          Expanded(child: _buildPreview(file)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: apiFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          file = CanvasFile(snapshot.data);
          return buildFile(file);
        } else {
          return Center(
            child: Container(child: CircularProgressIndicator(), width: 70, height: 70),
          );
        }
      },
    );
  }
}

class FolderObject extends StatelessWidget {
  Icon icon;
  String name;
  int byteSize;
  int folderCount;
  bool isFolder;
  int id;
  CanvasFile file;

  CanvasApi _canvas;
  Course _details;

  FolderObject(bool folder, Map<String, dynamic> data, CanvasApi canvas, Course details) {
    this.id = data['id'];
    this.isFolder = folder;

    this._details = details;
    this._canvas = canvas;

    if (this.isFolder) {
      this.name = data['name'];
      this.icon = Icon(Icons.folder);
      this.folderCount = data['folders_count'] + data['files_count'];
    } else {
      this.name = data['filename'];
      this.icon = Icon(Icons.insert_drive_file);
      this.byteSize = data['size'];
      this.file = CanvasFile(data);
    }
  }

  String _prettySize() {
    var i = (log(this.byteSize) / log(1024)).floor();
    final suffix = ['B', 'KB', 'MB', 'GB'];
    return "${(this.byteSize / pow(1024, i)).toStringAsFixed(1)} ${suffix[i]}";
  }

  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(this.name),
        leading: this.icon,
        subtitle: Text(
          this.isFolder ? "${this.folderCount} items" : _prettySize(),
        ),
        // TODO: this is quite ugly
        onTap: this.isFolder
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FilesView(
                      this._details,
                      this._canvas,
                      id: this.id,
                    ),
                  ),
                )
            : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(this.name), backgroundColor: this._details.color),
                      body: FileView.buildFile(this.file),
                    ),
                  ),
                ),
      ),
    );
  }
}

class FilesView extends StatelessWidget {
  Course _details;
  CanvasApi _canvas;
  Future<dynamic> _data;

  FilesView(Course details, CanvasApi canvas, {int id}) {
    this._details = details;
    this._canvas = canvas;

    this._data = _loadData(id);
  }

  Future<List<FolderObject>> _loadData(int id) async {
    List<FolderObject> folderObjects = [];

    if (id == null) {
      var data = await this._canvas.get('api/v1/courses/${this._details.id}/folders/root');
      id = data['id'];
    }

    var data = await this._canvas.get('api/v1/folders/$id/folders');
    for (var folder in data) {
      folderObjects.add(FolderObject(true, folder, this._canvas, this._details));
    }

    data = await this._canvas.get('api/v1/folders/$id/files');
    for (var file in data) {
      folderObjects.add(FolderObject(false, file, this._canvas, this._details));
    }

    return folderObjects;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Files",
        ),
        backgroundColor: this._details.color,
      ),
      body: FutureBuilder(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView(
              children: snapshot.data,
            );
          }

          return Center(
            child: Container(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}
