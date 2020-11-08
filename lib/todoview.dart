import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'canvas/canvasapi.dart';
import 'canvas/canvasobjects.dart';
import 'coursesview/assignments.dart';

class TodoView extends StatelessWidget {
  CanvasApi _canvas;

  TodoView(CanvasApi canvas) {
    this._canvas = canvas;
  }

  Widget _buildTile(String title, String subtitle, Icon icon, Function() onTap) {
    return Card(
        child: ListTile(
      leading: icon,
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Todo")),
      body: FutureBuilder(
        future: this._canvas.get('api/v1/users/self/todo'),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Widget> todo = [];
            for (var el in snapshot.data) {
              if (el['assignment'] != null) {
                Assignment assign = Assignment(el['assignment']);
                todo.add(_buildTile(
                  assign.name,
                  DateFormat("'Due at' d MMMM yyyy 'at' HH:mm").format(assign.dueDate),
                  Icon(Icons.assignment),
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return FutureBuilder(
                          future: this._canvas.get('api/v1/users/self/colors'),
                          builder: (context, snapshot) {
                            Widget child;
                            if (snapshot.hasData) {
                              Course details = Course(id: el['course_id']);
                              for (String key in snapshot.data['custom_colors'].keys) {
                                if (key == 'course_${details.id}') {
                                  details.color = Color(int.parse(
                                      'ff' + snapshot.data["custom_colors"][key].substring(1),
                                      radix: 16));
                                  break;
                                }
                              }

                              child = AssignmentView(assign, details);
                            } else {
                              child = Scaffold(
                                appBar: AppBar(title: Text(assign.name)),
                                body: Center(
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              );
                            }
                            return AnimatedSwitcher(
                              child: child,
                              duration: Duration(
                                milliseconds: 500,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ));
              }
            }

            return ListView(children: todo);
          }

          return Center(
            child: Container(width: 50, height: 50, child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
