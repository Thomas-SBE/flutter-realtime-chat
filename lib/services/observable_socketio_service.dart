import 'dart:convert';

import "package:crypto/crypto.dart";
import 'package:chat_with_chatgpt/services/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

enum EVENT_TYPE {
  ERROR,
  MESSAGE_UPDATE,
  NEW_CHANNEL,
  MESSAGE_DELETE,
  CHANNEL_UPDATE,
  USER_UPDATE
}

class ObservableSocketIOService {
  late IO.Socket _socket;

  init() async {
    print("Connecting to websocket: ${ApiService.BASE_URL}");
    try {
      String? token =
          (await SharedPreferences.getInstance()).getString('token');

      _socket.io.options["query"] = "token=${token!.split(' ')[1]}";

      _socket.disconnect();
      _socket.close();
      _socket.destroy();
      _socket.dispose();

      if (_socket.connected) {
        print("Socket is still connected :/");
      }

      _socket.connect();

      _socket.onConnect((data) => print("Websocket is connected !"));
      _socket.onError((data) => print("Error during socket connection: $data"));
      _socket.onDisconnect((data) => print("Websocket is disconnected !"));

      _socket.on("error", (data) => _callEvent(EVENT_TYPE.ERROR, data));
      _socket.on(
          "new_channel", (data) => _callEvent(EVENT_TYPE.NEW_CHANNEL, data));
      _socket.on("message_deletion",
          (data) => _callEvent(EVENT_TYPE.MESSAGE_DELETE, data));
      _socket.on("message_update",
          (data) => _callEvent(EVENT_TYPE.MESSAGE_UPDATE, data));
      _socket.on("channel_update",
          (data) => _callEvent(EVENT_TYPE.CHANNEL_UPDATE, data));
      _socket.on(
          "user_update", (data) => _callEvent(EVENT_TYPE.USER_UPDATE, data));
    } catch (e) {
      print(e);
    }
  }

  disconnect() {
    try {
      _socket.disconnect();
      _socket.close();
      _socket.destroy();
      _socket.dispose();
    } catch (e) {
      print(e);
    }
  }

  Map<EVENT_TYPE, List<Function(dynamic)>> callbacks = {};

  ObservableSocketIOService() {
    callbacks[EVENT_TYPE.ERROR] = [];
    callbacks[EVENT_TYPE.MESSAGE_UPDATE] = [];
    callbacks[EVENT_TYPE.MESSAGE_DELETE] = [];
    callbacks[EVENT_TYPE.NEW_CHANNEL] = [];
    callbacks[EVENT_TYPE.CHANNEL_UPDATE] = [];
    callbacks[EVENT_TYPE.USER_UPDATE] = [];

    _socket = IO.io(
        ApiService.BASE_URL,
        IO.OptionBuilder()
            .disableAutoConnect()
            .disableReconnection()
            .enableForceNewConnection()
            .enableForceNew()
            .setTransports(["websocket"]).build());
  }

  listen(EVENT_TYPE event, Function(dynamic) callback) {
    if (callbacks[event]!.contains(callback)) return;
    callbacks[event]!.add(callback);
  }

  forget(EVENT_TYPE event, Function(dynamic) callback) {
    if (!callbacks[event]!.contains(callback)) return;
    callbacks[event]!.remove(callback);
  }

  _callEvent(EVENT_TYPE name, dynamic data) {
    for (var element in callbacks[name]!) {
      element(data);
    }
  }
}
