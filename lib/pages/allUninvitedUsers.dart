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

class UninvitedUsersPage extends StatefulWidget {
  UninvitedUsersPage({super.key, this.onUserSelected, required this.channel});

  Function(UserModel)? onUserSelected;
  ChannelModel channel;

  @override
  State<UninvitedUsersPage> createState() => _UninvitedUsersPageState();
}

class _UninvitedUsersPageState extends State<UninvitedUsersPage> {
  List<UserModel> users = [];
  List<UserModel> displayedUsers = [];

  @override
  void initState() {
    super.initState();
    getList();
  }

  void getList() async {
    var res = await ApiService.getAllUninvitedUsers(widget.channel);
    var data = jsonDecode(res.body);

    setState(() {
      users = [];
      for (Map<String, dynamic> val in data) {
        users.add(UserModel(
            id: val["user_id"],
            username: val["username"],
            image_url: val["image_url"]));
      }
      displayedUsers = List.from(users);
    });
  }

  @override
  Widget build(BuildContext build) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 240, 240, 240),
          foregroundColor: const Color.fromARGB(255, 38, 38, 38),
          shadowColor: Colors.transparent,
          title: const Text(
            "Inviter un nouvel utilisateur",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: "Poppins",
                color: const Color.fromARGB(255, 38, 38, 38)),
          ),
        ),
        body: Stack(children: [
          Column(children: [
            const SizedBox(
              height: 74,
            ),
            Container(
              color: Colors.transparent,
              child: SingleChildScrollView(
                child: Column(
                  children: displayedUsers.map((e) {
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
                                  backgroundImage: NetworkImage(e.image_url !=
                                          null
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
                ),
              ),
            ),
          ]),
          Container(
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 240, 240, 240),
                boxShadow: [
                  BoxShadow(
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: Offset(0, 0),
                      color: Colors.grey.withOpacity(0.5))
                ]),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                decoration: const InputDecoration(
                    border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(128, 25, 25, 25), width: 1)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 25, 25, 25),
                            width: 1.5)),
                    hintText: "Rechercher un utilisateur",
                    hintStyle: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                      fontFamily: "Poppins",
                      color: Color.fromARGB(128, 25, 25, 25),
                    ),
                    icon: Icon(Icons.search),
                    hoverColor: Color.fromARGB(128, 25, 25, 25)),
                style: const TextStyle(
                    fontFamily: "Poppins", fontWeight: FontWeight.w500),
                onChanged: (value) {
                  setState(() {
                    displayedUsers = users
                        .where((element) =>
                            element.username.toLowerCase().contains(value) ||
                            element.id.toString().startsWith(value))
                        .toList();
                  });
                },
              ),
            ),
          ),
        ]));
  }
}
