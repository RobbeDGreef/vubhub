import 'package:flutter/material.dart';

import '../infohandler.dart';

import 'library.dart';
import 'restaurant.dart';

class PlacesView extends StatelessWidget {
  InfoHandler _info;

  PlacesView(InfoHandler info) {
    this._info = info;
  }

  // TODO: Move place stuff in to different file
  Widget _buildPlaceTile(String title, Function() ptr, BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: EdgeInsets.all(5),
        leading: Icon(Icons.library_books),
        title: Text(title),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ptr())),
      ),
    );
  }

  List<Widget> _getPlaces(BuildContext context) {
    return [
      _buildPlaceTile("Centrale bibliotheek VUB", () => LibraryBookingMenu(this._info), context),
      //_buildPlaceTile("VUB Restaurant menu's", () => RestaurantMenu(), context),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: _getPlaces(context),
    );
  }
}
