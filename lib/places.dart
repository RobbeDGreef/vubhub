import 'dart:convert';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'const.dart';
import 'infohandler.dart';
import "package:intl/intl.dart";
import "package:interval_time_picker/interval_time_picker.dart" as interval;

// Debugging
import "package:http/http.dart" as http;

class SpotItem {
  int index = 0;
  bool isAvailable = false;
  String name = "";
  String details = "";

  SpotItem.empty() {}

  SpotItem(Map<String, dynamic> seat, int index, bool isAvailable) {
    this.name = seat["resource_name"];
    this.index = index;
    this.isAvailable = isAvailable;
    this.details = seat["description"];
  }
}

class LibraryBookingMenu extends StatefulWidget {
  InfoHandler info;

  LibraryBookingMenu(InfoHandler info) {
    this.info = info;
  }

  @override
  _LibraryBookingMenuState createState() => _LibraryBookingMenuState(this.info);
}

class _LibraryBookingMenuState extends State<LibraryBookingMenu> {
  List<dynamic> _jsonData;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _selectedDuration = TimeOfDay(hour: 0, minute: 30);
  List<SpotItem> _showedSpots = [SpotItem.empty()];
  String _typedFilter = "";
  bool _showUnavailablePlaces = true;
  InfoHandler info;
  bool _loading = true;

  _LibraryBookingMenuState(InfoHandler info) {
    print("constructed");
    this.info = info;
    _updateJsonData(false);
  }

  void _updateJsonData([shouldSetState = true]) async {
    if (shouldSetState) {
      setState(() {
        this._loading = true;
        // TODO: this is a hack, find a better solution
        this._showedSpots.clear();
        this._showedSpots.add(SpotItem.empty());
      });
    }

    http
        .get(LibraryApiUrl + DateFormat("yyyy-MM-dd").format(this._selectedDate) + "&type=533")
        .then((res) {
      setState(() {
        this._loading = false;
        this._jsonData = jsonDecode(res.body);
        updateList();
      });
    });
  }

  String _makeTimeString(TimeOfDay time) {
    return NumberFormat("00").format(time.hour) + ":" + NumberFormat("00").format(time.minute);
  }

  int getMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  bool _hasFreeTimeSpot(Map<String, dynamic> spot) {
    for (int i = 0; i < spot["hours"].length; i++) {
      if (spot["hours"][i]["hour"] == _makeTimeString(this._selectedTime) &&
          spot["hours"][i]["places_available"] == 1) {
        bool fits = true;
        for (int hourI = 1; hourI < getMinutes(this._selectedDuration) ~/ 30; hourI++) {
          if (spot["hours"][i + hourI]["places_available"] != 1) {
            fits = false;
            break;
          }
        }

        if (!fits) continue;

        return true;
      }
    }
    return false;
  }

  bool _checkName(Map<String, dynamic> spot) {
    return this._typedFilter.isNotEmpty &&
        !(spot["resource_name"] as String).toLowerCase().contains(this._typedFilter);
  }

  void _maybeAddWidget(SpotItem item) {
    if (!item.isAvailable && (!this._showUnavailablePlaces || this._typedFilter.isNotEmpty)) return;

    this._showedSpots.add(item);
  }

  void updateList() {
    this._showedSpots.clear();
    int i = 0;
    for (Map<String, dynamic> seat in this._jsonData) {
      if (_checkName(seat) || !_hasFreeTimeSpot(seat)) {
        _maybeAddWidget(SpotItem(seat, i, false));
        i++;
        continue;
      }
      this._showedSpots.add(SpotItem(seat, i, true));
      i++;
    }
  }

  Widget _buildGenPicker(String title, String current, Icon icon, Function() onTap) {
    return Card(
      child: InkWell(
        onTap: () {
          onTap();
        },
        child: Padding(
          padding: EdgeInsets.all(7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  Text(
                    current,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              SizedBox(width: 10),
              icon,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return _buildGenPicker(
      "Date",
      DateFormat("dd/M/yyyy").format(this._selectedDate),
      Icon(Icons.event),
      () {
        showDatePicker(
          context: context,
          initialDate: this._selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(DateTime.now().add(Duration(days: 365)).year),
        ).then((date) {
          if (date != null) {
            setState(() {
              this._selectedDate = date;
              _updateJsonData();
            });
          }
        });
      },
    );
  }

  Widget _buildDurationPicker() {
    return _buildGenPicker(
      "Duration",
      "${this._selectedDuration.hour}:${this._selectedDuration.minute}",
      Icon(Icons.timer),
      () {
        interval
            .showIntervalTimePicker(
                context: context,
                helpText: "HOW LONG DO YOU WANT TO RESERVE",
                initialTime: this._selectedDuration,
                interval: 30,
                visibleStep: interval.VisibleStep.Thirtieths,
                initialEntryMode: interval.TimePickerEntryMode.input)
            .then((value) {
          if (value != null) {
            setState(() {
              this._selectedDuration = value;
              updateList();
            });
          }
        });
      },
    );
  }

  Widget _buildTimePicker() {
    return _buildGenPicker(
      "Time picker",
      "${this._selectedTime.hour}:${this._selectedTime.minute}",
      Icon(Icons.access_time),
      () {
        interval
            .showIntervalTimePicker(
                context: context,
                helpText: "WHEN DO YOU WANT TO RESERVE",
                initialTime: this._selectedTime,
                interval: 30,
                visibleStep: interval.VisibleStep.Thirtieths,
                initialEntryMode: interval.TimePickerEntryMode.input)
            .then((value) {
          if (value != null) {
            setState(() {
              this._selectedTime = value;
              updateList();
            });
          }
        });
      },
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDatePicker(),
            _buildTimePicker(),
            _buildDurationPicker(),
          ],
        ),
        Card(
          child: Padding(
            padding: EdgeInsets.only(left: 8, right: 8, bottom: 4),
            child: TextField(
              decoration: InputDecoration(labelText: "Filter by name"),
              onChanged: (val) {
                setState(() {
                  this._typedFilter = val;
                  updateList();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  void _bookSeat(String email, int index) {
    Navigator.pop(context);
    // These headers are probably not necessairy but it can't hurt to send them anyway
    // I have no way of testing this part of the system because it makes actual requests
    // So i don't want to risk it
    var headers = {
      "host": "reservation.affluences.com",
      "connection": "close",
      "accept": "application/json, text/plain, */*",
      "accept-language": "en",
      "content-type": "application/json",
      "origin": "https://affluences.com",
      "sec-fetch-site": "same-site",
      "sec-fetch-mode": "cors",
      "sec-fetch-dest": "empty",
      "referer": "https://affluences.com/",
      "accept-encoding": "gzip, deflate",
    };

    var body = jsonEncode({
      "email": email,
      "date": DateFormat("yyyy-MM-dd").format(this._selectedDate),
      "start_time": _makeTimeString(this._selectedTime),
      "end_time": _makeTimeString(TimeOfDay(
          hour: this._selectedTime.hour + this._selectedDuration.hour,
          minute: this._selectedTime.minute + this._selectedDuration.minute)),
      "note": null,
      "user_firstname": null,
      "user_lastname": null,
      "user_phone": null,
      "person_count": null
    });

    http
        .post(LibraryReserveUrl + (this._jsonData[index]["resource_id"] as int).toString(),
            headers: headers, body: body)
        .then((value) {
      var json = jsonDecode(value.body);
      if (json["successMessage"] != null) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: Text("Almost there"),
              contentPadding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
              children: [
                Text(json["successMessage"] + " " + email, style: TextStyle(fontSize: 15)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      child: Text("Ok"),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                )
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: Text("Error :("),
              contentPadding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
              children: [
                Text(json["errorMessage"], style: TextStyle(fontSize: 15)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      child: Text("Ok"),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                )
              ],
            );
          },
        );
      }
    });
  }

  void _bookSeatDialog(int index) {
    String email = this.info.getUserEmail();
    final bookstr = this._showedSpots[index].name +
        " from " +
        _makeTimeString(this._selectedTime) +
        " until " +
        _makeTimeString(TimeOfDay(
            hour: this._selectedTime.hour + this._selectedDuration.hour,
            minute: this._selectedTime.minute + this._selectedDuration.minute));
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text("Quick book"),
          contentPadding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
          children: [
            Text("Are you sure you want to book $bookstr", style: TextStyle(fontSize: 15)),
            TextFormField(
              decoration: InputDecoration(
                icon: Icon(Icons.email_outlined),
                hintText: "Email",
              ),
              initialValue: this.info.getUserEmail().toLowerCase(),
              onChanged: (val) => email = val,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  child: Text("Yes, book now"),
                  onPressed: () => _bookSeat(email, index),
                ),
                TextButton(
                  child: Text("No, discard"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  void _showUnavailable(int index) {
    Flushbar(
      margin: EdgeInsets.all(8),
      borderRadius: 8,
      message: "This seat is unavailable for the selected date, time or duration.",
      duration: Duration(seconds: 3),
      animationDuration: Duration(milliseconds: 500),
    ).show(context);
  }

  Widget _librarySpotBuilder(BuildContext context, int index) {
    if (this._loading) {
      return Center(
          child: Container(
        margin: EdgeInsets.all(8),
        child: CircularProgressIndicator(),
        width: 50,
        height: 50,
      ));
    }

    Widget button;
    if (this._showedSpots[index].isAvailable) {
      button = TextButton(
        child: Text("Book", style: TextStyle(color: Colors.white)),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
        ),
        onPressed: () => _bookSeatDialog(index),
      );
    } else {
      button = TextButton(
        child: Text("unavailable", style: TextStyle(color: Colors.white)),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.grey),
        ),
        onPressed: () => _showUnavailable(index),
      );
    }
    return Card(
      child: ListTile(
        title: Text(this._showedSpots[index].name),
        subtitle: Text(this._showedSpots[index].details),
        trailing: button,
      ),
    );
  }

  Widget _buildBooking() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "Centrale bibliotheek VUB",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
        ),
        _buildFilters(),
        Expanded(
          child: ListView.builder(
            itemBuilder: _librarySpotBuilder,
            itemCount: this._showedSpots.length,
            shrinkWrap: true,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Book a spot at the library")),
      body: _buildBooking(),
    );
  }
}
