import 'dart:async';
import "package:http/http.dart" as http;
import "package:html/parser.dart" as html;

import 'const.dart';

class CrawlRequest {
  String baseUrl;
  String url;
  String type;
  Map<String, String> headers;
  String body = "";
  int redirectCount = 5;

  CrawlRequest({this.type, this.url, this.headers}) {
    baseUrl = url.substring(0, url.indexOf("/", 8));
  }
}

class Crawler {
  String curId;
  String content;
  CrawlRequest _request;

  Crawler() {}

  /// This function basically mimics the browser/server behavior of using redirection
  /// links and set-cookie headers to get a session key and retrieve the correct
  /// server generated response.
  static Future<http.StreamedResponse> makeRequest(CrawlRequest crawlReq,
      [followRedirect = true]) async {
    String cookies = crawlReq.headers["cookie"];

    // Max crawlReq.redirectCount amount of redirections
    for (int i = 0; i < crawlReq.redirectCount; i++) {
      final client = http.Client();

      // Build the http request from our CrawlRequest object
      crawlReq.headers["cookie"] = cookies;
      final req = http.Request(crawlReq.type, Uri.parse(crawlReq.url))
        ..followRedirects = false
        ..headers.clear()
        ..headers.addAll(crawlReq.headers)
        ..body = crawlReq.body;

      // Send the request and check if we need to follow this redirection
      final res = await client.send(req);
      if (!followRedirect) return res;

      print(res.statusCode);
      if (res.statusCode == 302) {
        // Follow redirection
        followRedirect = res.isRedirect;

        // Set new url
        if (res.headers["location"][0] == '/')
          crawlReq.url = crawlReq.baseUrl + res.headers["location"];
        else
          crawlReq.url = res.headers["location"];

        // Check for set-cookie headers and parse them appropriately
        String cookie = res.headers["set-cookie"];
        if (cookie != null) {
          List<String> parts = cookie.split(",");
          for (String cookie in parts) {
            cookies = cookies + cookie.substring(0, cookie.indexOf(";")) + "; ";
          }
        }
      } else if (res.statusCode == 200) {
        {
          // Ok code, we are done
          return res;
        }
      } else {
        // Error
        print(":( ${res.statusCode}");
        return res;
      }
    }
    return null;
  }

  Map<String, String> getDepartmentGroups() {
    if (this.content == null) return {};

    var doc = html.parse(this.content);
    Map<String, String> items = Map();
    // TODO: this has thrown errors since doc is empty sometimes ?
    for (var e in doc.getElementsByClassName("DepartmentFilter").first.children) {
      items.addAll({e.text: e.attributes["value"]});
    }
    print(items);
    return items;
  }

  Future<void> updateConnection() async {
    var postBody = "__EVENTTARGET=tTagClicked&__EVENTARGUMENT=${this.curId}";
    var headers = {
      "host": "",
      "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
      "accept-language": "en-US,en;q=0.5",
      "accept-encoding": "gzip, deflate",
      "connection": "close",
      "cookie": "",
      "upgrade-insecure-requests": "1",
      "cache-control": "max-age=0"
    };

    this._request = CrawlRequest(url: VubTimetablesEntryUrl, headers: headers, type: "GET");
    this._request.headers["host"] =
        this._request.baseUrl.substring(this._request.baseUrl.indexOf("//") + 2);

    var r = await makeRequest(this._request);

    this._request.headers.addAll({"content-type": "application/x-www-form-urlencoded"});
    this._request.type = "POST";
    this._request.body = postBody;

    r = await makeRequest(this._request, false);
    if (r.statusCode == 302 && r.headers["location"].endsWith("Default.aspx")) {
      // Yay
      this._request.url = this._request.baseUrl + r.headers["location"];
      this._request.type = "GET";
      this._request.body = "";
      r = await makeRequest(this._request);
      this.content = await r.stream.bytesToString();
    } else {
      // :(
      print("failure");
    }
  }

  Future waitForContent(Duration interval) {
    var compl = Completer();
    check() {
      if (this.content != null)
        compl.complete();
      else
        Timer(interval, check);
    }

    check();
    return compl.future;
  }

  Future<String> getWeekData(int week, String group) async {
    // get week data
    // TODO: yuk pls find a better way to do this:

    await waitForContent(Duration(seconds: 2));

    String body = "";
    var doc = html.parse(this.content);

    // The site holds various form data to pass for our post request
    // so we need to scrap the site first.
    body +=
        "__VIEWSTATE=" + Uri.encodeComponent(doc.getElementById("__VIEWSTATE").attributes["value"]);
    body += "&__EVENTVALIDATION=" +
        Uri.encodeComponent(doc.getElementById("__EVENTVALIDATION").attributes["value"]);
    body += "&tLinkType=setbytag";
    body += "&tWildcard=&dlObject=" + Uri.encodeComponent(/* "#SPLUS0ABF6A" */ group);
    body += "&lbWeeks=+" + week.toString();
    body += "&lbDays=1%3B2%3B3%3B4%3B5%3B6";
    body +=
        "&dlPeriod=2%3B3%3B4%3B5%3B6%3B7%3B8%3B9%3B10%3B11%3B12%3B13%3B14%3B15%3B16%3B17%3B18%3B19%3B20%3B21%3B22%3B23%3B24%3B25%3B26%3B27%3B28%3B29%3B30%3B31%3B32%3B33";
    body += "&RadioType=reportset_wr%3Breportset_wr%3Breportset_wr";
    body += "&bGetTimetable=Bekijk+het+lesrooster";

    // Make our first request
    this._request.body = body;
    this._request.type = "POST";
    var r = await makeRequest(this._request);
    print("status1: ${r.statusCode}");
    if (r.statusCode != 200) {
      // Retry with new connection
      // @TODO: URGENT: this could deadlock and cause infinite recursion and thus
      // stackoverflows and thus crashes
      await updateConnection();
      return getWeekData(week, group);
    }

    // Save the url for later because we might be running this function many
    // times and don't want to "corrupt" the url.
    String urlTmp = this._request.url;

    // Make the second request
    this._request.url = this._request.baseUrl + "/SWS/v3/evenjr/NL/STUDENTSET/showtimetable.aspx";
    this._request.body = "";
    this._request.type = "GET";
    r = await makeRequest(this._request);
    print("status2: ${r.statusCode}");

    // Reset url
    this._request.url = urlTmp;
    return r.stream.bytesToString();
  }
}
