import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:photo_view/photo_view.dart';

import 'theming.dart';
import 'const.dart';

/// Create an image that is zoomable
/// return location of a tap.
class MapView extends StatefulWidget {
  void update() {
    // TODO ? i think it can be left empty
  }

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  PhotoView _photoView;
  OverlayEntry _sticky;

  Widget _buildPin(BuildContext context, Offset loc) {
    return Positioned(
      child: Center(
        child: Container(width: 10, height: 10, color: Colors.red),
      ),
      top: loc.dy,
      left: loc.dx,
    );
  }

  void _showPin(String text, Offset loc) {
    if (_sticky != null) {
      _sticky.remove();
    }

    _sticky = OverlayEntry(builder: (context) => _buildPin(context, loc));
    Overlay.of(context).insert(_sticky);
  }

  void _onTapped(Offset globLoc, Offset imgLocation) {
    _showPin("Building test", globLoc);
  }

  @override
  Widget build(BuildContext context) {
    this._photoView = PhotoView(
        imageProvider: AssetImage("assets/VubMapNew.png"),
        tightMode: false,
        minScale: PhotoViewComputedScale.contained * 1.0,
        maxScale: PhotoViewComputedScale.covered * 2.0,
        onTapUp: (context, details, controller) {
          // Some calculation is needed to calculate the x,y loc of the tap
          // TODO the height/width ratio stuff needs to rotate one we rotate the device
          RenderBox box = context.findRenderObject();
          double rat = VubMapHeight / VubMapWidth;
          double imgWidth = box.size.width;
          double imgHeight = (box.size.width * rat);
          double yStart = (box.size.height - imgHeight) / 2;

          var xreal = details.localPosition.dx / imgWidth * VubMapWidth;
          var yreal = (details.localPosition.dy - yStart) / imgHeight * VubMapHeight;

          //_onTapped(details.globalPosition, Offset(xreal, yreal));
        });
    return this._photoView;
    /*
    return this._photoView;
    return GestureDetector(
      child: this._photoView,
      onTap: () => print("Tap callback called"),
      onScaleEnd: (ScaleEndDetails details) => print("scale end ${details.velocity}"),
      onScaleUpdate: (ScaleUpdateDetails details) =>
          print("scale update: ${details.focalPoint} ${details.localFocalPoint}"),
      onTapUp: (TapUpDetails details) =>
          print("Tap up: ${details.globalPosition} ${details.localPosition}"),
      onTapDown: (TapDownDetails details) =>
          print("Tap down ${details.globalPosition} ${details.localPosition}"),
    );
    */
    /*
    return GestureDetector(
      //child: Container(height: 500, color: Theme.of(context).primaryColor),
      //child: Image(image: AssetImage("assets/VubMapNew.png")),
      child: this._photoView,
      onTapUp: (TapUpDetails details) => _tapped(details.globalPosition),
    );
    */
  }
}
