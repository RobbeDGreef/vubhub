
class AssignmentView extends StatelessWidget {
  Assignment _assignment;
  Course _details;

  AssignmentView(Assignment assignment, Course details) {
    this._details = details;
    this._assignment = assignment;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this._assignment.name),
        backgroundColor: this._details.color,
      ),
      body: ListView(
        padding: EdgeInsets.only(left: 16, right: 16, top: 20),
        children: [
          Text(this._assignment.name, style: TextStyle(fontSize: 25)),
          Row(
            children: [
              this._assignment.hasSubmitted
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : Icon(Icons.clear, color: Colors.red),
              SizedBox(width: 5),
              this._assignment.hasSubmitted
                  ? Text("Submitted", style: TextStyle(color: Colors.green))
                  : Text("Nothing submitted", style: TextStyle(color: Colors.red)),
              SizedBox(width: 10),
              Text('${this._assignment.gradeLimit.truncate()} marks')
            ],
          ),
          Divider(),
          Row(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Due at", style: TextStyle(fontSize: 17)),
                Text("Submission types", style: TextStyle(fontSize: 17)),
              ],
            ),
            SizedBox(width: 25),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat("d MMMM H:mm").format(this._assignment.dueDate),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                Text(this._assignment.submissionTypes.join(', '),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
              ],
            ),
          ]),
          Divider(),
          htmlParse(this._assignment.details),
        ],
      ),
    );
  }
}
