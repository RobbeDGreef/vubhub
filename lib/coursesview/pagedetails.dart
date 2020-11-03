import 'package:flutter/material.dart';

class PageDetails extends StatefulWidget {
  String title;
  Color color;
  Function() getData;
  String noDataText;
  Widget Function(BuildContext, dynamic) buildTile;
  PageDetails({this.title, this.color, this.getData, this.buildTile, this.noDataText});

  _PageDetailsState createState() =>
      _PageDetailsState(getData: getData, noDataText: this.noDataText);
}

class _PageDetailsState extends State<PageDetails> {
  List<dynamic> _data = [];
  Function() getData;
  bool _loading = true;
  String noDataText;

  void update() async {
    this._loading = true;
    var data = await this.getData();
    setState(() {
      this._data = data;
      this._loading = false;
    });
  }

  _PageDetailsState({this.getData, this.noDataText}) {
    update();
  }

  int _calcItemCount() {
    if (this._data.length == 0) return 1;
    return this._data.length;
  }

  Widget _buildTile(BuildContext context, int index) {
    if (this._loading) {
      return Center(
          child: Container(
              margin: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
              width: 50,
              height: 50));
    }

    if (this._data.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Center(
          child: Text(
            this.noDataText,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return this.widget.buildTile(context, this._data[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.widget.title),
        backgroundColor: this.widget.color,
      ),
      body: ListView.builder(
        itemBuilder: (BuildContext context, int index) => _buildTile(context, index),
        itemCount: _calcItemCount(),
      ),
    );
  }
}
