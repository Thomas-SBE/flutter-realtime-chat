import 'package:flutter/painting.dart';
import "package:http/http.dart" as http;
import "package:crypto/crypto.dart";
import "package:chat_with_chatgpt/model/channel.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'package:async/async.dart';
import "dart:convert";

class ApiService {
  static const String BASE_URL = "http://" +
      String.fromEnvironment("REMOTE_SERVER", defaultValue: "localhost:5000");

  static int PROFILEIMAGEVERSIONING = 0;
  static int CONVERSATIONVERSIONNING = 0;

  static Future<http.Response> login(String email, String password) {
    var pass_bytes = utf8.encode(password);
    var pass_digest = sha256.convert(pass_bytes);
    Map<String, dynamic> data = {
      "email": email,
      "password": pass_digest.toString()
    };
    return http.post(Uri.parse("$BASE_URL/auth/login"),
        headers: {"Content-Type": "application/json"}, body: json.encode(data));
  }

  static Future<http.Response> register(String email, String password) {
    var pass_bytes = utf8.encode(password);
    var pass_digest = sha256.convert(pass_bytes);
    Map<String, dynamic> data = {
      "email": email,
      "password": pass_digest.toString()
    };
    return http.post(Uri.parse("$BASE_URL/auth/register"),
        headers: {"Content-Type": "application/json"}, body: json.encode(data));
  }

  static Future<http.Response> me() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      var headers = {'Authorization': token};
      return http.get(Uri.parse("$BASE_URL/me"), headers: headers);
    }

    return http.get(Uri.parse("$BASE_URL/me"));
  }

  static Future<http.Response> getUsersInfos(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      var headers = {'Authorization': token};
      return http.get(Uri.parse("$BASE_URL/user/${id}"), headers: headers);
    }

    return http.get(Uri.parse("$BASE_URL/user/${id}"));
  }

  static Future<http.Response> new_channel(String name, dynamic members) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    Map<String, dynamic> data = {"name": name, "members": []};

    if (token != null) {
      var headers = {'Authorization': token};
      return http.post(Uri.parse("$BASE_URL/channel/new"),
          headers: {"Content-Type": "application/json", "Authorization": token},
          body: json.encode(data));
    }
    return http.post(Uri.parse("$BASE_URL/channel/new"),
        headers: {"Content-Type": "application/json"}, body: json.encode(data));
  }

  static Future<http.Response> getMessagesFromChannel(
      ChannelModel channel) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return http.get(Uri.parse("$BASE_URL/channel/messages/${channel.id}"),
        headers: {"Content-Type": "application/json", "Authorization": token!});
  }

  static Future<http.Response> sendMessage(
      String content, ChannelModel channel) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return http.post(Uri.parse("$BASE_URL/channel/send/${channel.id}"),
        headers: {"Content-Type": "application/json", "Authorization": token!},
        body: json.encode({"content": content}));
  }

  static Future<http.Response> getChannelInformations(
      ChannelModel channel) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return http.get(Uri.parse("$BASE_URL/channel/info/${channel.id}"),
        headers: {"Content-Type": "application/json", "Authorization": token!});
  }

  static Future<http.Response> callChatGPT(int channel_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      var headers = {'Authorization': token};
      return http.post(
          Uri.parse("$BASE_URL/channel/messages/${channel_id}/gpt"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": token
          });
    }
    return http.post(Uri.parse("$BASE_URL/channel/messages/${channel_id}/gpt"),
        headers: {"Content-Type": "application/json"});
  }

  static Future<http.Response> updateChannelInfo(int id, String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    Map<String, dynamic> data = {"name": name};

    if (token != null) {
      var headers = {'Authorization': token};
      return http.patch(Uri.parse("$BASE_URL/channel/info/${id}"),
          headers: {"Content-Type": "application/json", "Authorization": token},
          body: json.encode(data));
    }

    return http.patch(Uri.parse("$BASE_URL/channel/messages/${id}"),
        headers: {"Content-Type": "application/json"}, body: json.encode(data));
  }

  static Future<http.StreamedResponse> sendPersonnalImage(
      List<int> image) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    PROFILEIMAGEVERSIONING++;
    var request =
        http.MultipartRequest("POST", Uri.parse("$BASE_URL/upload_image/user"));
    request.headers["Authorization"] = token!;
    request.files.add(
        http.MultipartFile.fromBytes('file', image, filename: "_tempfilename"));
    return request.send();
  }

  static Future<http.StreamedResponse> sendChannelImage(
      List<int> image, ChannelModel channel) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    CONVERSATIONVERSIONNING++;
    var request = http.MultipartRequest(
        "POST", Uri.parse("$BASE_URL/upload_image/channel/${channel.id}"));
    request.headers["Authorization"] = token!;
    request.files.add(
        http.MultipartFile.fromBytes('file', image, filename: "_tempfilename"));
    return request.send();
  }

  static Future<http.Response> updateUsername(String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    Map<String, dynamic> data = {"username": username};
    var headers = {'Authorization': token};
    return http.patch(Uri.parse("$BASE_URL/me"),
        headers: {"Content-Type": "application/json", "Authorization": token!},
        body: json.encode(data));
  }

  static Future<http.Response> getAllUninvitedUsers(
      ChannelModel channel) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    var headers = {'Authorization': token};
    return http.get(Uri.parse("$BASE_URL/invite/userlist/${channel.id}"),
        headers: {"Content-Type": "application/json", "Authorization": token!});
  }

  static Future<http.Response> inviteUser(int channel_id, int uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    return http.post(Uri.parse("$BASE_URL/channel/invite/${channel_id}/${uid}"),
        headers: {"Content-Type": "application/json", "Authorization": token!});
  }

  static Future<http.Response> kickUser(int channel_id, int uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    return http.post(Uri.parse("$BASE_URL/channel/kick/${channel_id}/${uid}"),
        headers: {"Content-Type": "application/json", "Authorization": token!});
  }

  static Future<http.Response> leaveConversation(
      int channel_id, int uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    return http.post(Uri.parse("$BASE_URL/channel/leave/${channel_id}"),
        headers: {"Content-Type": "application/json", "Authorization": token!});
  }
}
