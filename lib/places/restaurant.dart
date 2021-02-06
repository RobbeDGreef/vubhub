import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

class RestaurantMenu extends StatefulWidget {
  @override
  _RestaurantMenuState createState() => _RestaurantMenuState();
}

class _RestaurantMenuState extends State<RestaurantMenu> {
  List<dynamic> parseRestaurantData(http.Response res) {
    List<dynamic> data = [];
    var document = html.parse(res.body);

    for (var element in document.getElementsByClassName('rd-content-holder js-extra-content')) {
      /*
      if (element.parent.parent.className ==
          "pg-text rd-content js-extra rd-extra-right rd-intro") {
        section['notification'] = 
        data.add(section);
      }
      */

      var section = {};

      var h4 = element.getElementsByTagName('h4');
      section['title'] = h4[0].text;

      try {
        for (var li in element.getElementsByTagName('ul')[0].children) {
          if (section['items'] == null) section['items'] = [];

          section['items'].add(li.text);
        }
      } catch (e) {}

      data.add(section);
    }

    return data;
  }

  Widget _buildMenu() {
    return FutureBuilder(
      future: http.get("https://student.vub.be/en/menu-vub-student-restaurant#menu-etterbeek-nl"),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data.statusCode != 200) {
            return Center(child: Text("Something went wrong while getting the week menu :("));
          }

          List<Widget> widgets = [];
          List<dynamic> data = parseRestaurantData(snapshot.data);

          for (var item in data) {
            widgets.add(
              Card(
                child: Column(
                  children: [
                    Text(item['title'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(item)
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: widgets.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return widgets[index];
            },
          );
        }
        return Center(child: Container(child: CircularProgressIndicator(), height: 50, width: 50));
      },
    );
  }

  Widget _buildChooseRestaurantTile() {
    return DropdownButton(
      items: [
        "Etterbeek",
        "Jette",
      ].map<DropdownMenuItem<String>>((String val) {
        return DropdownMenuItem(child: Text(val), onTap: () => print(val));
      }).toList(),
      onChanged: (selected) => print(selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Week menu")),
      body: ListView(
        children: [
          _buildChooseRestaurantTile(),
          Divider(),
          _buildMenu(),
        ],
      ),
    );
  }
}
