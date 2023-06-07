import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:chat_with_chatgpt/components/error_message.dart';
import 'package:chat_with_chatgpt/model/channel.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:chat_with_chatgpt/model/user.dart';
import 'package:chat_with_chatgpt/pages/allUninvitedUsers.dart';
import 'package:chat_with_chatgpt/pages/chatPage.dart';
import 'package:chat_with_chatgpt/pages/kickUserPage.dart';
import 'package:chat_with_chatgpt/services/api.dart';
import 'package:chat_with_chatgpt/services/observable_socketio_service.dart';

import 'homePage.dart';

class ConvInformationsPage extends StatefulWidget {
  const ConvInformationsPage({super.key, required this.conv});

  final ChannelModel conv;

  @override
  State<ConvInformationsPage> createState() => _ConvInformationsPageState();
}

class _ConvInformationsPageState extends State<ConvInformationsPage> {
  final _formKey = GlobalKey<FormState>();
  final nameConversationController = TextEditingController();

  int uid = -1;

  String _errTitle = "";
  String _errContent = "";
  bool isValidNotError = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImageFromGallery() async {
    try {
      XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      try {
        var res = await ApiService.sendChannelImage(
            (await image.readAsBytes()), widget.conv);
      } catch (e) {
        setState(() {
          _errTitle = "Erreur de communication";
          _errContent =
              "Une erreur est survenue lors de la communication avec le serveur, $e.";
          isValidNotError = false;
        });

        return;
      }
      setState(() {
        _errTitle = "Changement du salon";
        _errContent = "La nouvelle image a bien été appliquée au salon !";
        isValidNotError = true;
      });
    } catch (e) {
      callErrorDialog();
      print("Echec dans la recuperation de l'image : $e");
    }
  }

  void onChannelUpdate(dynamic data) async {
    var res = await ApiService.getChannelInformations(widget.conv);
    var data = jsonDecode(res.body);
    setState(() {
      widget.conv.image_url = data["image_url"];
      widget.conv.name = data["name"];
    });
  }

  @override
  void initState() {
    super.initState();
    GetIt.instance<ObservableSocketIOService>()
        .listen(EVENT_TYPE.CHANNEL_UPDATE, onChannelUpdate);
    nameConversationController.text = widget.conv.name;
    ApiService.me().then((value) {
      if (value.statusCode != 200) return;
      setState(() {
        var data = jsonDecode(value.body);
        uid = data["self"]["user_id"];
        print(uid);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    GetIt.instance<ObservableSocketIOService>()
        .forget(EVENT_TYPE.CHANNEL_UPDATE, onChannelUpdate);
  }

  void onKickingUserSelected(UserModel u) async {
    try {
      var res = await ApiService.kickUser(widget.conv.id, u.id);
    } catch (e) {
      setState(() {
        _errTitle = "Erreur de communication";
        _errContent =
            "Une erreur est survenue lors de la communication avec le serveur, $e.";
        isValidNotError = false;
      });
      return;
    }
    setState(() {
      _errTitle = "Exclusion";
      _errContent =
          "L'utilisateur ${u.username}#${u.id} a été exclu de la conversation ${widget.conv.name} !";
      isValidNotError = true;
    });
  }

  void onInviteUserSelected(UserModel u) async {
    try {
      var res = await ApiService.inviteUser(widget.conv.id, u.id);
    } catch (e) {
      setState(() {
        _errTitle = "Erreur de communication";
        _errContent =
            "Une erreur est survenue lors de la communication avec le serveur, $e.";
        isValidNotError = false;
      });

      return;
    }
    setState(() {
      _errTitle = "Invitation";
      _errContent =
          "L'utilisateur ${u.username}#${u.id} a été invité dans la conversation ${widget.conv.name} !";
      isValidNotError = true;
    });
  }

  @override
  Widget build(BuildContext build) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 240, 240, 240),
        foregroundColor: const Color.fromARGB(255, 38, 38, 38),
        title: const Text(
          "Modification des informations de la conversation",
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: "Poppins",
              color: const Color.fromARGB(255, 38, 38, 38)),
        ),
      ),
      body: ErrorDialogHolder(
        background: Colors.white,
        title: _errTitle,
        content: _errContent,
        isValid: isValidNotError,
        displayed: _errContent.isNotEmpty,
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 40,
                ),
                Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                      const SizedBox(height: 10),
                      CircleAvatar(
                          radius: 100,
                          backgroundImage: NetworkImage(widget.conv.image_url !=
                                  null
                              ? (widget.conv.image_url!.startsWith("/")
                                  ? "${ApiService.BASE_URL}${widget.conv.image_url}?v=${ApiService.CONVERSATIONVERSIONNING}"
                                  : "${widget.conv.image_url}")
                              : "https://i.imgur.com/5W2Ssl0.png")),
                      if (widget.conv.adminId == HomePage.selfUserId)
                        Column(
                          children: [
                            Material(
                              color: Colors.white,
                              child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 15),
                                      Container(
                                        constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.7),
                                        child: TextButton.icon(
                                          icon: const Icon(
                                            Icons.image_outlined,
                                            color: Color.fromARGB(
                                                255, 230, 230, 230),
                                          ),
                                          onPressed: pickImageFromGallery,
                                          style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateColor
                                                      .resolveWith((states) =>
                                                          const Color.fromARGB(
                                                              255,
                                                              25,
                                                              25,
                                                              25))),
                                          label: const Padding(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 10, 20, 10),
                                            child: Text(
                                              "Changer l'image du salon",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.normal,
                                                fontSize: 14,
                                                fontFamily: "Poppins",
                                                color: Color.fromARGB(
                                                    255, 230, 230, 230),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 75),
                                      Container(
                                        constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.7),
                                        child: TextFormField(
                                          decoration: const InputDecoration(
                                              border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Color.fromARGB(
                                                          128, 25, 25, 25),
                                                      width: 1)),
                                              focusedBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 25, 25, 25),
                                                      width: 1.5)),
                                              hintText:
                                                  "Entrez un nom pour la conversation",
                                              hintStyle: TextStyle(
                                                fontWeight: FontWeight.normal,
                                                fontSize: 14,
                                                fontFamily: "Poppins",
                                                color: Color.fromARGB(
                                                    128, 25, 25, 25),
                                              ),
                                              icon: Icon(Icons.person),
                                              labelText:
                                                  "Nom de la conversation",
                                              labelStyle: TextStyle(
                                                fontWeight: FontWeight.normal,
                                                fontSize: 14,
                                                fontFamily: "Poppins",
                                                color: Color.fromARGB(
                                                    128, 25, 25, 25),
                                              ),
                                              hoverColor: Color.fromARGB(
                                                  128, 25, 25, 25)),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Un nom de conversation doit être renseigné";
                                            }
                                            return null;
                                          },
                                          style: const TextStyle(
                                              fontFamily: "Poppins",
                                              fontWeight: FontWeight.w500),
                                          controller:
                                              nameConversationController,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Container(
                                        constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.7),
                                        child: TextButton.icon(
                                          icon: const Icon(
                                            Icons.edit_note,
                                            color: Color.fromARGB(
                                                255, 230, 230, 230),
                                          ),
                                          onPressed: () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              var res = await ApiService
                                                  .updateChannelInfo(
                                                      widget.conv.id,
                                                      nameConversationController
                                                          .text);
                                              setState(() {
                                                _errTitle =
                                                    "Changement du salon";
                                                _errContent =
                                                    "Le nouveau nom du salon est désormais \"${nameConversationController.text}\" !";
                                                isValidNotError = true;
                                              });
                                            }
                                          },
                                          style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateColor
                                                      .resolveWith((states) =>
                                                          const Color.fromARGB(
                                                              255,
                                                              25,
                                                              25,
                                                              25))),
                                          label: const Padding(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 10, 20, 10),
                                            child: Text(
                                              "Changer le nom du salon",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.normal,
                                                fontSize: 14,
                                                fontFamily: "Poppins",
                                                color: Color.fromARGB(
                                                    255, 230, 230, 230),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )),
                            )
                          ],
                        ),
                      if (widget.conv.adminId != HomePage.selfUserId)
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Text(
                            widget.conv.name,
                            style: const TextStyle(
                                fontFamily: "Poppins",
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w900,
                                fontSize: 38),
                          ),
                        )
                    ])),
                const SizedBox(height: 75),
                const Text("Actions",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        fontFamily: "Poppins",
                        color: Color.fromARGB(255, 38, 38, 38))),
                Material(
                  child: ListTile(
                      leading: const Icon(Icons.insert_invitation),
                      tileColor: Colors.white,
                      title: const Text(
                        "Inviter un nouveau membre",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            fontFamily: "Poppins",
                            color: Color.fromARGB(255, 38, 38, 38)),
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UninvitedUsersPage(
                                      channel: widget.conv,
                                      onUserSelected: onInviteUserSelected,
                                    )));
                      }),
                ),
                Material(
                  child: ListTile(
                      leading: const Icon(Icons.logout),
                      tileColor: Colors.white,
                      title: Text(
                        widget.conv.adminId == HomePage.selfUserId
                            ? "Supprimer la conversation"
                            : "Quitter la conversation",
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            fontFamily: "Poppins",
                            color: Color.fromARGB(255, 38, 38, 38)),
                      ),
                      onTap: () {
                        openConfirmationDialog();
                      }),
                ),
                if (this.uid == widget.conv.adminId)
                  Material(
                    child: ListTile(
                        leading: const Icon(Icons.delete),
                        tileColor: Colors.white,
                        title: const Text(
                          "Exclure un membre",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              fontFamily: "Poppins",
                              color: Color.fromARGB(255, 38, 38, 38)),
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => KickUsersPage(
                                        channel: widget.conv,
                                        onUserSelected: onKickingUserSelected,
                                      )));
                        }),
                  ),
                const SizedBox(height: 75),
                const Text("Membres du salon",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        fontFamily: "Poppins",
                        color: Color.fromARGB(255, 38, 38, 38))),
                if (widget.conv.members != null &&
                    widget.conv.members!.isNotEmpty)
                  Column(
                    children: widget.conv.members!.map((e) {
                      return ClipRRect(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (e.id == HomePage.selfUserId)
                                            const Text(
                                              "\uf007  ",
                                              style: TextStyle(
                                                  fontFamily: "FontAwesome",
                                                  fontSize: 14),
                                            ),
                                          if (e.id == widget.conv.adminId)
                                            const Text(
                                              "\uf521  ",
                                              style: TextStyle(
                                                  fontFamily: "FontAwesome",
                                                  fontSize: 14),
                                            ),
                                          Text(
                                            e.username,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                                fontFamily: "Poppins"),
                                          ),
                                        ],
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
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Fonction qui permet d'afficher un dialog
  Future openConfirmationDialog() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirmation",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                fontFamily: "Poppins",
              )),
          content: Text(
              widget.conv.adminId == HomePage.selfUserId
                  ? "Êtes-vous sur de vouloir supprimer la conversation ?\nSupprimer cette conversation retirera tous ses membres et les messages seront perdus."
                  : "Êtes-vous sur de vouloir quitter la conversation ?",
              style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                  fontFamily: "Poppins")),
          actions: [
            TextButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateColor.resolveWith(
                      (states) => Colors.transparent)),
              onPressed: leaveConversation,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Text(
                  "Oui",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                    fontFamily: "Poppins",
                    color: Color.fromARGB(255, 25, 25, 25),
                  ),
                ),
              ),
            ),
            TextButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateColor.resolveWith(
                      (states) => const Color.fromARGB(255, 25, 25, 25))),
              onPressed: quitDialog,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Text(
                  "Non",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                    fontFamily: "Poppins",
                    color: Color.fromARGB(255, 230, 230, 230),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  void quitDialog() {
    Navigator.of(context).pop();
  }

  // Fonction qui permet de quitter la conversation
  void leaveConversation() async {
    await ApiService.leaveConversation(widget.conv.id, uid);
    goToHomePage();
  }

  void goToHomePage() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => HomePage()));
  }

  Future callErrorDialog() => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Cette opération n'est pas disponible pour cette plateforme"),
      actions: [
        TextButton(
          child: const Text("Ok"),
          onPressed: () {
            Navigator.of(context).pop();
            },)
      ],
    ),
  );
}
