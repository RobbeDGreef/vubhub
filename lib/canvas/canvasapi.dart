import 'dart:convert';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../const.dart';

class CanvasApi {
  String accessToken;

  CanvasApi(String accessToken) {
    this.accessToken = accessToken;
  }

  Future<dynamic> get(String url, {Map<String, String> headers}) async {
    var res = (await request(url, headers: headers));
    if (res == null) return null;
    return jsonDecode(await res.stream.bytesToString());
  }

  Future<dynamic> post(String url, {Map<String, String> headers, String body}) async {
    var res = (await request(url, headers: headers, body: body, method: 'POST'));
    if (res == null) return null;
    return jsonDecode(await res.stream.bytesToString());
  }

  Future<void> put(String url, {Map<String, String> headers, String body}) async {
    var res = (await request(url, headers: headers, body: body, method: 'PUT'));
    if (res == null) return null;

    return await res.stream.bytesToString();
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
      if (kIsWeb)
        print('CanvasAPI request exception $e');
      else
        FLog.error(text: 'CanvasApi request exception $e');
      return null;
    }
  }
}
