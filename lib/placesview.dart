import 'package:flutter/material.dart';

import 'infohandler.dart';
import 'library.dart';

class PlacesView extends StatelessWidget {
  InfoHandler _info;

  PlacesView(InfoHandler info) {
    this._info = info;
  }

  void _openLibraryBooking(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => LibraryBookingMenu(this._info),
      ),
    );
  }

  // TODO: Move place stuff in to different file
  Widget _buildPlaceTile(String title, Function(BuildContext) ptr, BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: EdgeInsets.all(5),
        leading: Icon(Icons.library_books),
        title: Text(title),
        onTap: () => ptr(context),
      ),
    );
  }

  List<Widget> _getPlaces(BuildContext context) {
    return [
      _buildPlaceTile("Centrale bibliotheek VUB", _openLibraryBooking, context),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: _getPlaces(context),
    );
  }
}
