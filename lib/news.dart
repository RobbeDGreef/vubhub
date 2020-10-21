import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:palette_generator/palette_generator.dart';
import 'package:url_launcher/url_launcher.dart';

// I really don't like to use two different html packages in one
// project but I also don't want to implement a html parser myself
// so yeah this is the quickfix solution rn.
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';

import 'const.dart';

class Article {
  String title;
  String details;
  String articleUrl;
  String imageUrl;
  String provider = "today.vub.com";
  String body;
  String publishedString;

  Article(Map<String, dynamic> data) {
    this.title = data['title'];
    this.articleUrl = data['articleUrl'];
    this.imageUrl = data['imageUrl'];
    this.details = data['description'];

    this.provider = this.articleUrl.substring(this.articleUrl.indexOf("://") + 3);
    this.provider = this.provider.substring(0, this.provider.indexOf("/"));
  }
}

class ArticleView extends StatefulWidget {
  Article article;
  ArticleView({this.article});

  @override
  _ArticleViewState createState() => _ArticleViewState(article);
}

class _ArticleViewState extends State<ArticleView> {
  bool _loading = true;
  Article _article;

  void _loadArticle() async {
    var res = await http.get(this._article.articleUrl);
    var doc = html.parse(res.body);
    var attr = doc.getElementsByTagName("vub-article")[0].attributes;
    setState(() {
      this._article.body = attr['body'];
      this._article.publishedString = attr['publication-time'];
      this._loading = false;
    });
  }

  _ArticleViewState(Article article) {
    this._article = article;
    _loadArticle();
  }

  Widget _buildBody() {
    if (this._loading) {
      return Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text(this._article.title, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        Padding(
          padding: EdgeInsets.only(top: 15),
          child: Text(this._article.publishedString,
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Divider(),
        this._article.imageUrl != null
            ? Image.network(this._article.imageUrl)
            : Text("No image provided"),
        Html(
          data: this._article.body,
          onLinkTap: (String url) => launch(url),
          style: {
            'p': Style(fontSize: FontSize(18)),
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        this._article.title,
        overflow: TextOverflow.fade,
      )),
      body: _buildBody(),
    );
  }
}

// TODO: does this have to be stateful?
class NewsView extends StatefulWidget {
  _NewsViewState createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  List<Article> _articles = [];
  List<List<dynamic>> _filters = [];
  bool _loading = true;
  int _articlePage = 0;
  List<bool> _selectedFilters = [];

  _NewsViewState() {
    _loadMoreArticles(true);
  }

  // Flutter is a real pain in the ass when it comes to importing html as html
  // (can't access Document class) so I have to let dart's type inference handle this for us.
  void _updateFilters(List<dynamic> filters) {
    this._filters.clear();

    setState(() {
      for (Map<String, dynamic> filter in filters) {
        int subId = int.parse(filter['url'].substring(filter['url'].indexOf("=") + 1));
        this._filters.add([filter['label'] as String, subId]);
      }
      this._selectedFilters = List<bool>.generate(this._filters.length, (index) => false);
    });
  }

  void _loadMoreArticles([bool isInConstructor = false]) async {
    if (!isInConstructor) {
      setState(() {
        this._loading = true;
      });
    }

    print("https://today.vub.be/nl/nieuws?page=${this._articlePage}");
    var res = await http.get("https://today.vub.be/nl/nieuws?page=${this._articlePage}");

    if (res.statusCode != 200) {
      print("News res code: ${res.statusCode}");
      setState(() {
        this._loading = false;
      });
      return;
    }
    this._articlePage += 1;

    var doc = html.parse(res.body);
    var vubArticleOverview = doc.getElementsByTagName("vub-article-overview")[0].attributes;
    var data = jsonDecode(vubArticleOverview[':articles']);

    // Filters don't really change so they only have to be loaded once.
    if (this._filters.isEmpty) {
      _updateFilters(jsonDecode(vubArticleOverview[':filters']));
    }

    setState(() {
      for (Map<String, dynamic> article in data) {
        this._articles.add(Article(article));
      }
      this._loading = false;
    });
  }

  void _selectFilter(int filter) {
    setState(() {
      this._selectedFilters[filter] = !this._selectedFilters[filter];
    });
    // TODO: load new data according to filters.
  }

  Widget _buildCategoryTile(int index) {
    Color fg = Theme.of(context).primaryColor;
    Color bg;

    if (this._selectedFilters[index] == true) {
      bg = fg;
      fg = Colors.white;
    }

    return Padding(
      padding: EdgeInsets.only(left: 4, right: 4),
      child: OutlinedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(bg),
          side: MaterialStateProperty.all<BorderSide>(BorderSide(color: fg)),
        ),
        child: Text(this._filters[index][0], style: TextStyle(color: fg)),
        onPressed: () => _selectFilter(index),
      ),
    );
  }

  Widget _buildCatergories() {
    List<Widget> buttons = List.generate(
      this._filters.length,
      (index) => _buildCategoryTile(index),
    );

    // ListView gave us problems so we implemented it ourselves.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: buttons,
      ),
    );
  }

  Widget _buildArticleTile(BuildContext context, int index) {
    if (index == this._articles.length) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Container(
            child: CircularProgressIndicator(),
            width: 50,
            height: 50,
          ),
        ),
      );
    }

    // TODO: Nicer handling of no image
    Widget img = Text("No image provided");
    if (this._articles[index].imageUrl != null) {
    // Load the network image with a nice circular loading bar
      img = Image.network(
      this._articles[index].imageUrl,
      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.width * 0.677, // Most used aspect ratio
          child: Center(
            child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes
                    : null),
          ),
        );
      },
    );
    }

    // This will change in the future once we load the primary color out of the image
    final fg = Colors.grey[800];
    final fg_darkter = Colors.black54;
    final bg = Colors.white;

    final headLineStyle = TextStyle(color: fg, fontSize: 20, fontWeight: FontWeight.bold);
    final detailStyle = TextStyle(color: fg, fontSize: 15);
    final providerStyle = TextStyle(color: fg_darkter, fontSize: 15);

    // This list is placed outside of the return statement because we need to check
    // if the details field is left empty or not.
    List<Widget> textItems = [
      Text(this._articles[index].title, style: headLineStyle),
    ];

    if (this._articles[index].details != "") {
      textItems.add(Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            this._articles[index].details,
            style: detailStyle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          )));
    }

    textItems.add(Divider(color: fg));
    textItems.add(Padding(
      padding: EdgeInsets.only(left: 5),
      child: Text("from ${this._articles[index].provider}", style: providerStyle),
    ));

    // TODO: get the most prominent dark and light colors from the image and put them as the background and forground of the text maybe look at palette_generator but idk it doesn't seem very great since it uses a async function, which could be annoying.

    return InkWell(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ArticleView(article: this._articles[index]))),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            img,
            Container(
              width: MediaQuery.of(context).size.width,
              color: bg,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: textItems,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleWidget() {
    int articleCount = this._articles.length;

    // TODO: display the progress bar and the text widget in the Fiddle of the screen
    if (this._loading && this._articles.isEmpty) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
          width: 50,
          height: 50,
        ),
      );
    } else if (this._articles.isEmpty) {
      return Center(
        child: Text("Could not retrieve any articles."),
      );
    } else if (this._loading) {
      articleCount++;
    }

    return ListView.builder(
      itemBuilder: _buildArticleTile,
      itemCount: articleCount,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Create scroll controller to listen for onEdge 'events'
    // so that we can update and load more articles.
    ScrollController scrollController = ScrollController();
    scrollController.addListener(
      () {
        if (scrollController.position.atEdge && scrollController.position.pixels != 0) {
          print(this._loading);
          if (this._loading == false) {
            _loadMoreArticles();
          }
        }
      },
    );

    return ListView(
      controller: scrollController,
      children: [
        _buildCatergories(),
        _buildArticleWidget(),
      ],
    );
  }
}
