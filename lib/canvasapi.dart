import 'dart:convert';
import 'package:http/http.dart' as http;
import 'const.dart';

class CanvasApi {
  String accessToken;

  CanvasApi(String accessToken) {
    this.accessToken = accessToken;
  }

  Future<dynamic> get(String url, {Map<String, String> headers}) async {
    Map<String, String> allHeaders = {
      "Authorization": "Bearer " + this.accessToken,
    };

    if (headers != null) {
      allHeaders.addAll(headers);
    }

    var res = await http.get(CanvasUrl + url, headers: allHeaders);
    return jsonDecode(res.body);
  }

  Future<dynamic> post(String url, {Map<String, String> headers, String body}) async {
    Map<String, String> allHeaders = {
      "Authorization": "Bearer " + this.accessToken,
    };

    if (headers != null) {
      allHeaders.addAll(headers);
    }

    if (body == null) {
      body = "";
    }

    var res = await http.post(CanvasUrl + url, headers: allHeaders, body: body);
    return jsonDecode(res.body);
  }
}
