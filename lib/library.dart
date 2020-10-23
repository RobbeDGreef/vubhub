import 'dart:convert';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import "package:interval_time_picker/interval_time_picker.dart" as interval;
import "package:photo_view/photo_view.dart";
import "package:http/http.dart" as http;

import 'const.dart';
import 'infohandler.dart';
import 'theming.dart';

/// Helper
String _addHalfhourToString(String time) {
  int hour = int.parse(time.substring(0, 2));
  int minute = int.parse(time.substring(3, 5)) + 30;
  if (minute == 60) {
    hour += 1;
    minute = 0;
  }

  return NumberFormat("00").format(hour) + ":" + NumberFormat("00").format(minute);
}

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

class SpotDetailPage extends StatefulWidget {
  Map<String, dynamic> _detailData;
  Function(List<int>) _bookCallback;
  DateTime _date;

  SpotDetailPage(Map<String, dynamic> detailData, Function(List<int>) bookCallback, DateTime date) {
    this._detailData = detailData;
    this._bookCallback = bookCallback;
    this._date = date;
  }

  @override
  _SpotDetailPageState createState() =>
      _SpotDetailPageState(this._detailData, this._bookCallback, this._date);
}

class _SpotDetailPageState extends State<SpotDetailPage> {
  Map<String, dynamic> _detailData;
  Function(List<int>) _bookCallback;
  List<int> _selectedButtons = [];
  DateTime _selectedDate;

  _SpotDetailPageState(
      Map<String, dynamic> detailData, Function(List<int>) bookCallback, DateTime date) {
    this._detailData = detailData;
    this._bookCallback = bookCallback;
    this._selectedDate = date;
  }

  void _toggleSelectedButton(int index) {
    if (this._selectedButtons.contains(index)) {
      this._selectedButtons.remove(index);
      return;
    }

    for (int i = 0; i < this._selectedButtons.length; i++) {
      if (this._selectedButtons[i] > index) {
        this._selectedButtons.insert(i, index);
        return;
      }
    }
    this._selectedButtons.add(index);
  }

  Widget _buildSpotDetailTimeButton(String hour, int index, bool available, String seat) {
    List<Color> colors = [Colors.grey, Colors.white];

    if (available) {
      colors = [Colors.white, Theme.of(context).primaryColor];
    }
    print(this._selectedButtons);
    if (this._selectedButtons.contains(index)) {
      colors = [Theme.of(context).primaryColor, Colors.white];
    }

    return Card(
      child: TextButton(
        child: Text(hour,
            style: TextStyle(
              fontSize: 20,
              color: colors[1],
            )),
        onPressed: () {
          if (available) {
            setState(() {
              _toggleSelectedButton(index);
            });
          } else {
            Flushbar(
              message: seat + " is already booked at " + hour,
              duration: Duration(seconds: 2),
              margin: EdgeInsets.all(8),
              borderRadius: 8,
              animationDuration: Duration(milliseconds: 500),
            ).show(context);
          }
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(colors[0]),
        ),
      ),
    );
  }

  bool _doSelectedTimerangesMerge() {
    int prevIndex = this._selectedButtons[0] - 1;
    for (int index in this._selectedButtons) {
      if (index != prevIndex + 1) {
        return false;
      }
      prevIndex = index;
    }
    return true;
  }

  Widget build(BuildContext context) {
    List<Widget> times = List();
    int buttonIndex = 0;
    Color buttonColor = Colors.grey;
    String selectedTimeText;
    String availableTimeText = "Available times";

    // TODO: i noticed that studyspaces 1 - 58 are not used E.I. plan nummero uno, is never used, but what if they one day are. We need to parse the name and based on that select the correct map
    String imgPath = "assets/studyspaces2.png";

    if (this._selectedButtons.isEmpty) {
      selectedTimeText = "No timerange selected";
    } else if (_doSelectedTimerangesMerge()) {
      selectedTimeText = "Book from " +
          this._detailData["hours"][this._selectedButtons[0]]["hour"] +
          " until " +
          _addHalfhourToString(this._detailData["hours"][this._selectedButtons.last]["hour"]);
      buttonColor = Theme.of(context).primaryColor;
    }

    for (Map<String, dynamic> hour in this._detailData["hours"]) {
      times.add(
        _buildSpotDetailTimeButton(
          hour["hour"],
          buttonIndex,
          (hour["places_available"] == 1),
          this._detailData["resource_name"],
        ),
      );
      buttonIndex++;
    }

    if (times.isEmpty) {
      availableTimeText = "No available times";
    }

    availableTimeText += " at " + DateFormat("d MMMM").format(this._selectedDate);

    return Scaffold(
      backgroundColor: AlmostWhite,
      appBar: AppBar(
        title: Text("Seat details"),
      ),
      body: ListView(
        //crossAxisAlignment: CrossAxisAlignment.start,
        padding: EdgeInsets.all(8),
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8, top: 5),
            child: Text(
              this._detailData["resource_name"],
              style: TextStyle(fontSize: 30, color: AlmostDark),
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.only(left: 8, bottom: 10),
            child: Text(this._detailData["description"], style: TextStyle(fontSize: 15)),
          ),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  // TODO: if there are no available times display "no available times here instead"
                  child: Text(availableTimeText,
                      style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                  padding: EdgeInsets.only(left: 10, top: 10),
                ),
                LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                  return GridView.count(
                    primary: false,
                    padding: EdgeInsets.all(8),
                    crossAxisSpacing: 2,
                    shrinkWrap: true,
                    childAspectRatio: 1.8,
                    mainAxisSpacing: 2,
                    children: times,
                    crossAxisCount: constraints.maxWidth ~/ 80,
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                (selectedTimeText != null)
                    ? Text(selectedTimeText, style: TextStyle(fontSize: 15))
                    : Text(
                        "Selected time ranges do not merge!",
                        style: TextStyle(color: Colors.red, fontSize: 15),
                      ),
                TextButton(
                  child: Text("Book now", style: TextStyle(color: Colors.white)),
                  style:
                      ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(buttonColor)),
                  onPressed: () {
                    if (this._selectedButtons.isNotEmpty && selectedTimeText != null) {
                      this._bookCallback(this._selectedButtons);
                    } else {
                      Flushbar(
                        margin: EdgeInsets.all(8),
                        borderRadius: 8,
                        message: "No valid time range is selected",
                        duration: Duration(seconds: 2),
                        animationDuration: Duration(milliseconds: 500),
                      ).show(context);
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 8, bottom: 4),
            child: Text("Library map", style: TextStyle(fontSize: 15)),
          ),
          Card(
            child: ListTile(
              title: Image(
                image: AssetImage(imgPath),
              ),
              onTap: () {
                // TODO: this transition is bad, the dismiss takes to long and its not pretty
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return Dismissible(
                        key: Key("key?"),
                        onDismissed: (_) => Navigator.pop(context),
                        background: Container(),
                        direction: DismissDirection.vertical,
                        child: PhotoView(
                          imageProvider: AssetImage(imgPath),
                          minScale: 0.1,
                          maxScale: 1.0,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
        _updateSpotList();
      });
    });
  }

  String _formatTimeString(TimeOfDay time) {
    return NumberFormat("00").format(time.hour) + ":" + NumberFormat("00").format(time.minute);
  }

  int _calcAmountOfMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  bool _hasFreeTimeSpot(Map<String, dynamic> spot) {
    for (int i = 0; i < spot["hours"].length; i++) {
      if (spot["hours"][i]["hour"] == _formatTimeString(this._selectedTime) &&
          spot["hours"][i]["places_available"] == 1) {
        bool fits = true;
        for (int hourI = 1; hourI < _calcAmountOfMinutes(this._selectedDuration) ~/ 30; hourI++) {
          if (spot["hours"][i + hourI]["places_available"] != 1) {
            fits = false;
            break;
          }
        }

        if (fits) {
          return true;
        }
      }
    }
    return false;
  }

  bool _doesNameContainFilter(Map<String, dynamic> spot) {
    return this._typedFilter.isNotEmpty &&
        !(spot["resource_name"] as String).toLowerCase().contains(this._typedFilter);
  }

  void _updateSpotList() {
    this._showedSpots.clear();
    int i = 0;
    for (Map<String, dynamic> seat in this._jsonData) {
      bool available = true;
      // The text filter is not found in the name of the seat, do not add
      if (_doesNameContainFilter(seat)) {
        i++;
        continue;
      }

      // The seat is not available for the selected date, time or duration,
      // check if it should be added (with unavailable tag) or should be skipped.
      if (!_hasFreeTimeSpot(seat)) {
        if (this._showUnavailablePlaces) {
          available = false;
        } else {
          i++;
          continue;
        }
      }

      this._showedSpots.add(SpotItem(seat, i, available));
      i++;
    }
  }

  Widget _buildPickerGeneric(String title, String current, Icon icon, Function() onTap) {
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
    return _buildPickerGeneric(
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
    return _buildPickerGeneric(
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
              _updateSpotList();
            });
          }
        });
      },
    );
  }

  Widget _buildTimePicker() {
    return _buildPickerGeneric(
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
              _updateSpotList();
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: "Filter by name"),
                    onChanged: (val) {
                      setState(() {
                        this._typedFilter = val;
                        _updateSpotList();
                      });
                    },
                  ),
                ),
                Row(
                  children: [
                    Text("Show unavailable seats"),
                    Checkbox(
                      value: this._showUnavailablePlaces,
                      onChanged: (val) {
                        setState(() {
                          print("value: $val");
                          this._showUnavailablePlaces = val;
                          _updateSpotList();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _bookSeat(String email, int index, String from, String until) {
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
      "start_time": from,
      "end_time": until,
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

  void _showBookSeatDialog(int index, String from, String until) {
    String email = "";
    if (this.info.user.email != null) {
      email = this.info.user.email;
    }

    final bookstr = this._showedSpots[index].name +
        " from " +
        from +
        " until " +
        until +
        " at " +
        DateFormat("d MMMM").format(this._selectedDate);
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
              initialValue: (email != null) ? email.toLowerCase() : null,
              onChanged: (val) => email = val,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  child: Text("Yes, book now"),
                  onPressed: () => _bookSeat(email, index, from, until),
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

  void _showBookDetailedDialog(int index, List<int> range) {
    return _showBookSeatDialog(
      index,
      this._jsonData[this._showedSpots[index].index]["hours"][range[0]]["hour"],
      _addHalfhourToString(
          this._jsonData[this._showedSpots[index].index]["hours"][range.last]["hour"]),
    );
  }

  void _showUnavailableDialog(int index) {
    Flushbar(
      margin: EdgeInsets.all(8),
      borderRadius: 8,
      message: "This seat is unavailable for the selected date, time or duration.",
      duration: Duration(seconds: 3),
      animationDuration: Duration(milliseconds: 500),
    ).show(context);
  }

  Widget _buildLibrarySpot(BuildContext context, int index) {
    if (this._loading) {
      return Center(
          child: Container(
        margin: EdgeInsets.all(8),
        child: CircularProgressIndicator(),
        width: 50,
        height: 50,
      ));
    }

    Widget _buildBookButton(int index) {
      Widget button;
      if (this._showedSpots[index].isAvailable) {
        button = TextButton(
          child: Text("Book", style: TextStyle(color: Colors.white)),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Theme.of(context).primaryColor),
          ),
          onPressed: () => _showBookSeatDialog(
              index,
              _formatTimeString(this._selectedTime),
              _formatTimeString(TimeOfDay(
                  hour: this._selectedTime.hour + this._selectedDuration.hour,
                  minute: this._selectedTime.minute + this._selectedDuration.minute))),
        );
      } else {
        button = TextButton(
          child: Text("unavailable", style: TextStyle(color: Colors.white)),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.grey),
          ),
          onPressed: () => _showUnavailableDialog(index),
        );
      }
      return button;
    }

    Widget button = _buildBookButton(index);
    return Card(
      child: ListTile(
        title: Text(this._showedSpots[index].name),
        subtitle: Text(this._showedSpots[index].details),
        trailing: button,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => SpotDetailPage(
                this._jsonData[this._showedSpots[index].index],
                (v) {
                  _showBookDetailedDialog(index, v);
                },
                this._selectedDate,
              ),
            ),
          );
        },
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
            style: TextStyle(fontSize: 25, color: AlmostDark),
          ),
        ),
        _buildFilters(),
        Expanded(
          child: ListView.builder(
            itemBuilder: _buildLibrarySpot,
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
      backgroundColor: AlmostWhite,
      body: _buildBooking(),
    );
  }
}
