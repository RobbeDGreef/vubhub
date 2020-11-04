import 'dart:convert';

import 'package:f_logs/model/flog/flog.dart';
import 'package:http/http.dart' as http;

import '../const.dart';

class CanvasApi {
  String accessToken;

  CanvasApi(String accessToken) {
    this.accessToken = accessToken;
  }

  Future<dynamic> get(String url, {Map<String, String> headers}) async {
    return jsonDecode(await (await request(url, headers: headers)).stream.bytesToString());
  }

  Future<dynamic> post(String url, {Map<String, String> headers, String body}) async {
    return jsonDecode(await (await request(url, headers: headers, body: body, method: 'POST'))
        .stream
        .bytesToString());
  }

  Future<void> put(String url, {Map<String, String> headers, String body}) async {
    return await (await request(url, headers: headers, body: body, method: 'PUT'))
        .stream
        .bytesToString();
  }

  Future<http.StreamedResponse> request(String url,
      {Map<String, String> headers, String body, String method = 'GET'}) async {
    Map<String, String> allHeaders = {
      "Authorization": "Bearer " + this.accessToken,
    };

    if (headers != null) {
      allHeaders.addAll(headers);
    }

    var req = http.Request(method, Uri.parse(CanvasUrl + url));
    req.headers.addAll(allHeaders);

    if (body != null) {
      req.body = body;
    }

    try {
      return await req.send();
    } catch (e) {
      FLog.error(text: 'CanvasApi request exception $e');
      return null;
    }
  }
}
