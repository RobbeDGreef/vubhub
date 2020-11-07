class PageView extends StatelessWidget {
  CanvasPage _page;
  Course _details;
  CanvasApi _canvas;

  PageView(CanvasPage page, Course details, CanvasApi canvas) {
    this._page = page;
    this._details = details;
    this._canvas = canvas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(this._page.name)),
      body: FutureBuilder(
        future: this._canvas.get('api/v1/courses/${this._details.id}/pages/${this._page.url}'),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return htmlParse(snapshot.data['body']);
          }

          return Center(
            child: Container(width: 50, height: 50, child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
