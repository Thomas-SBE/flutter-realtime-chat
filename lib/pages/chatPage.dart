import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:chat_with_chatgpt/messageTile.dart';
import 'package:chat_with_chatgpt/model/channel.dart';
import 'package:chat_with_chatgpt/model/message.dart';
import 'package:chat_with_chatgpt/model/user.dart';
import 'package:chat_with_chatgpt/pages/allUninvitedUsers.dart';
import 'package:chat_with_chatgpt/pages/kickUserPage.dart';
import 'package:chat_with_chatgpt/pages/ConvInformationsPage.dart';
import 'package:chat_with_chatgpt/services/api.dart';
import 'package:chat_with_chatgpt/services/observable_socketio_service.dart';
import 'homePage.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.conv});

  final ChannelModel conv;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<MessageModel> messages = [];
  String _sendVal = "";
  Map<int, UserModel> userById = {};

  bool doesDropToEndOfList = true;

  bool canAskGPT = true;

  final _formKeyModifs = GlobalKey<FormState>();
  final nameConversationController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  void _scrollDown() {
    if (!doesDropToEndOfList) return;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
    });
  }

  void _forceScrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 1), curve: Curves.easeInOut);
    });
  }

  updateMessagesList() async {
    var resp = await ApiService.getMessagesFromChannel(widget.conv);
    if (resp.statusCode != 200) {
      return;
    }
    var data = jsonDecode(resp.body);
    setState(() {
      messages.clear();
      for (var msg in data) {
        messages.add(MessageModel(
            id: msg["message_id"],
            sent: DateTime.parse(msg["sent"].toString()),
            content: msg["content"].startsWith("∞")
                ? msg["content"].substring(1)
                : msg["content"],
            sentBy: msg["sent_by"]));
      }
    });
  }

  getChannelInformations() async {
    var resp = await ApiService.getChannelInformations(widget.conv);
    if (resp.statusCode != 200) {
      return;
    }
    setState(() {
      var data = jsonDecode(resp.body);
      widget.conv.name = data["name"];
      widget.conv.image_url = data["image_url"];
      widget.conv.adminId = data["admin"];
      widget.conv.members = [];
      userById = {0: UserModel(id: 0, username: "ChatGPT", image_url: "")};
      for (var mem in data["members"]) {
        var user = UserModel(
            id: mem["user_id"],
            username: mem["username"],
            image_url: mem["image_url"]);
        widget.conv.members!.add(user);
        userById[user.id] = user;
      }
    });
  }

  Function(dynamic)? callbackMessageUpdate;
  Function(dynamic)? callbackChannelUpdated;
  Function(dynamic)? callbackUserUpdated;
  Function(dynamic)? errorCatcher;

  initGatheringInformations() async {
    await getChannelInformations();
    await updateMessagesList();
    setState(() {
      _forceScrollDown();
    });
  }

  @override
  void initState() {
    ApiService.PROFILEIMAGEVERSIONING++;
    super.initState();
    initGatheringInformations();
    callbackMessageUpdate = (data) {
      setState(() {
        messages.add(MessageModel(
            id: data["message_id"],
            sent: DateTime.parse(data["sent"].toString()),
            content: data["content"].startsWith("∞")
                ? data["content"].substring(1)
                : data["content"],
            sentBy: data["sent_by"]));
        _scrollDown();
      });
    };

    callbackChannelUpdated = (data) {
      getChannelInformations();
      ApiService.PROFILEIMAGEVERSIONING++;
    };

    errorCatcher = (data) {
      print(data);
    };

    callbackUserUpdated = (data) {
      setState(() {
        userById[data["user_id"]]!.image_url = data["image_url"];
        userById[data["user_id"]]!.username = data["username"];
        ApiService.PROFILEIMAGEVERSIONING++;
      });
    };

    GetIt.instance<ObservableSocketIOService>()
        .listen(EVENT_TYPE.MESSAGE_UPDATE, callbackMessageUpdate!);
    GetIt.instance<ObservableSocketIOService>()
        .listen(EVENT_TYPE.ERROR, errorCatcher!);
    GetIt.instance<ObservableSocketIOService>()
        .listen(EVENT_TYPE.CHANNEL_UPDATE, callbackChannelUpdated!);
    GetIt.instance<ObservableSocketIOService>()
        .listen(EVENT_TYPE.USER_UPDATE, callbackUserUpdated!);
    nameConversationController.text = widget.conv.name;
  }

  @override
  void dispose() {
    super.dispose();
    GetIt.instance<ObservableSocketIOService>()
        .forget(EVENT_TYPE.MESSAGE_UPDATE, callbackMessageUpdate!);
    GetIt.instance<ObservableSocketIOService>()
        .forget(EVENT_TYPE.ERROR, errorCatcher!);
    GetIt.instance<ObservableSocketIOService>()
        .forget(EVENT_TYPE.CHANNEL_UPDATE, callbackChannelUpdated!);
    GetIt.instance<ObservableSocketIOService>()
        .forget(EVENT_TYPE.USER_UPDATE, callbackUserUpdated!);
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
            appBar: AppBar(
                leading: BackButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(),
                      ),
                    );
                  },
                ),
                backgroundColor: Color.fromARGB(255, 240, 240, 240),
                foregroundColor: const Color.fromARGB(255, 38, 38, 38),
                title: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ConvInformationsPage(conv: widget.conv)),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(widget
                                              .conv.image_url !=
                                          null &&
                                      widget.conv.image_url!.isNotEmpty
                                  ? (widget.conv.image_url!.startsWith("/")
                                      ? "${ApiService.BASE_URL}${widget.conv.image_url}?v=${ApiService.CONVERSATIONVERSIONNING}"
                                      : "${widget.conv.image_url}")
                                  : "https://i.imgur.com/5W2Ssl0.png"),
                            ),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                widget.conv.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "Poppins",
                                    color:
                                        const Color.fromARGB(255, 38, 38, 38)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Row(
                      children: [
                        Text(
                          "Demander à\nChatGPT",
                          style: TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 9,
                              color: const Color.fromARGB(255, 38, 38, 38)),
                          textAlign: TextAlign.right,
                        ),
                        IconButton(
                            onPressed: canAskGPT
                                ? () async {
                                    setState(() {
                                      canAskGPT = false;
                                    });
                                    await ApiService.callChatGPT(
                                        widget.conv.id);
                                    setState(() {
                                      canAskGPT = true;
                                    });
                                  }
                                : null,
                            icon: const Icon(
                              Icons.assistant,
                            )),
                        SizedBox(width: 20),
                        Text(
                          "Scroller\nauto.",
                          style: TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 9,
                              color: const Color.fromARGB(255, 38, 38, 38)),
                          textAlign: TextAlign.right,
                        ),
                        Checkbox(
                            value: doesDropToEndOfList,
                            onChanged: (value) {
                              setState(() {
                                doesDropToEndOfList = value!;
                              });
                            }),
                      ],
                    )
                  ],
                )),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                          children: messages.map((e) {
                        return MessageTile(
                          message: e.content,
                          sendByUser: e.sentBy == HomePage.selfUserId,
                          username:
                              "${userById[e.sentBy]?.username ?? 'Utilisateur exclu'}#${userById[e.sentBy] != null ? e.sentBy : '????'}",
                          image_url: userById[e.sentBy] != null
                              ? userById[e.sentBy]!.image_url
                              : null,
                        );
                      }).toList())),
                ),
                SizedBox(
                  height: 75,
                  child: Container(
                    color: const Color.fromARGB(255, 38, 38, 38),
                    child: Form(
                      key: _formKey,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              cursorColor: Colors.white,
                              onChanged: (value) => _sendVal = value,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return "Veuillez entrer un message";
                                }
                                return null;
                              },
                              onFieldSubmitted: (value) {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  _formKey.currentState?.save();
                                  ApiService.sendMessage(_sendVal, widget.conv);
                                  _formKey.currentState!.reset();
                                }
                              },
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: "Poppins",
                                  fontSize: 16),
                              decoration: const InputDecoration(
                                  hintText: "Send a message",
                                  border: InputBorder.none,
                                  hintStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: "Poppins"),
                                  contentPadding: const EdgeInsets.all(20)),
                            ),
                          ),
                          IconButton(
                              onPressed: () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  _formKey.currentState?.save();
                                  ApiService.sendMessage(_sendVal, widget.conv);
                                  _formKey.currentState!.reset();
                                }
                              },
                              icon: const Icon(
                                Icons.send,
                                color: Colors.white,
                              )),
                          SizedBox(width: 20),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            )));
  }
}
