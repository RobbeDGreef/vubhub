class AnnouncementView extends StatelessWidget {
  Announcement _announcement;
  Course _details;
  CanvasApi _canvas;

  AnnouncementView(Announcement ann, Course details, CanvasApi canvas) {
    this._details = details;
    this._announcement = ann;
    this._canvas = canvas;
  }

  @override
  Widget build(BuildContext context) {
    this
        ._canvas
        .put('api/v1/courses/${this._details.id}/discussion_topics/${this._announcement.id}/read');

    Widget avatar = Center(child: Icon(Icons.person));
    try {
      avatar = Image.network(_announcement.author.avatarUrl);
    } catch (e) {}

    return Scaffold(
      appBar: AppBar(
        backgroundColor: this._details.color,
        title: Text(
          this._announcement.title,
          overflow: TextOverflow.fade,
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  clipBehavior: Clip.hardEdge,
                  child: avatar,
                  decoration: BoxDecoration(shape: BoxShape.circle),
                  width: 50,
                  height: 50,
                ),
                SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat("d MMMM H:mm").format(this._announcement.created)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(5),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: htmlParse(this._announcement.message),
            ),
          ),
        ],
      ),
    );
  }
}

