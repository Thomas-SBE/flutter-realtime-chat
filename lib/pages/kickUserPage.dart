import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chat_with_chatgpt/components/error_message.dart';
import 'package:http/http.dart' as http;
import 'package:chat_with_chatgpt/model/channel.dart';
import 'package:chat_with_chatgpt/model/user.dart';
import '../services/api.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class KickUsersPage extends StatefulWidget {
  KickUsersPage({super.key, this.onUserSelected, required this.channel});

  Function(UserModel)? onUserSelected;
  ChannelModel channel;

  @override
  State<KickUsersPage> createState() => _KickUsersPageState();
}

class _KickUsersPageState extends State<KickUsersPage> {
  List<UserModel> users = [];

  @override
  void initState() {
    super.initState();
    getList();
  }

  void getList() async {
    var res = await ApiService.getChannelInformations(widget.channel);
    var data = jsonDecode(res.body);
    var admin = data["admin"];
    data = data["members"];

    setState(() {
      users = [];
      for (Map<String, dynamic> val in data) {
        if (val["user_id"] == admin) continue;
        users.add(UserModel(
            id: val["user_id"],
            username: val["username"],
            image_url: val["image_url"]));
      }
    });
  }

  @override
  Widget build(BuildContext build) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 240, 240, 240),
          foregroundColor: const Color.fromARGB(255, 38, 38, 38),
          title: const Text(
            "Exclure un utilisateur de la conversation",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: "Poppins",
                color: const Color.fromARGB(255, 38, 38, 38)),
          ),
        ),
        body: Column(
          children: users.map((e) {
            return ClipRRect(
              child: Material(
                child: InkWell(
                  onTap: () {
                    if (widget.onUserSelected != null) {
                      widget.onUserSelected!(e);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(e.image_url != null
                              ? (e.image_url!.startsWith("/")
                                  ? "${ApiService.BASE_URL}${e.image_url}?v=${ApiService.PROFILEIMAGEVERSIONING}"
                                  : "${e.image_url}")
                              : "https://i.imgur.com/yn1MAbB.jpg"),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.username,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  fontFamily: "Poppins"),
                            ),
                            Text(
                              "#${e.id}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 14,
                                  fontFamily: "Poppins"),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ));
  }
}
