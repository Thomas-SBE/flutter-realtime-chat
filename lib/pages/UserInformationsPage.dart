import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chat_with_chatgpt/components/error_message.dart';
import 'package:http/http.dart' as http;
import '../services/api.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'dart:convert';
import 'dart:async';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class UserInformationsPage extends StatefulWidget {
  UserInformationsPage({super.key});

  @override
  State<UserInformationsPage> createState() => _UserInformationsPageState();
}

class _UserInformationsPageState extends State<UserInformationsPage> {
  String username = "";
  String? image_url = "https://i.imgur.com/yn1MAbB.jpg";

  final ImagePickerPlatform _picker = ImagePickerPlatform.instance;

  Future<void> pickImageFromGallery() async {
    try {
      PickedFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      await ApiService.sendPersonnalImage((await image.readAsBytes()));

      ApiService.me().then((value) {
        if (value.statusCode != 200) return;
        setState(() {
          var data = jsonDecode(value.body);
          username = data["self"]["username"];
          if (data["self"]["image_url"].toString().startsWith("/"))
            image_url =
                "${ApiService.BASE_URL}${data['self']['image_url']}?v=${ApiService.PROFILEIMAGEVERSIONING}";
          else
            image_url = data["self"]["image_url"];
          usernameController.text = username;
          _errMessage = "Vous avez changé votre photo de profil.";
          _errTitle = "Changement réussi";
          _isErrValid = true;
        });
      });
    } catch (e) {
      callErrorDialog();
      print("Echec dans la recuperation de l'image : $e");
    }
  }

  String _errMessage = "";
  String _errTitle = "";
  bool _isErrValid = false;

  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    usernameController.dispose();
  }

  @override
  void initState() {
    super.initState();
    ApiService.me().then((value) {
      if (value.statusCode != 200) return;
      setState(() {
        var data = jsonDecode(value.body);
        username = data["self"]["username"];
        if (data["self"]["image_url"] != null) {
          if (data["self"]["image_url"].toString().startsWith("/"))
            image_url =
                "${ApiService.BASE_URL}${data['self']['image_url']}?v=${ApiService.PROFILEIMAGEVERSIONING}";
          else
            image_url = data["self"]["image_url"];
        } else {
          image_url = null;
        }

        usernameController.text = username;
      });
    });
  }

  @override
  Widget build(BuildContext build) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 240, 240, 240),
        foregroundColor: const Color.fromARGB(255, 38, 38, 38),
        title: const Text(
          "Modification des informations du compte",
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: "Poppins",
              color: const Color.fromARGB(255, 38, 38, 38)),
        ),
      ),
      body: Container(
        padding: EdgeInsets.only(top: 40),
        color: Colors.white,
        child: ErrorDialogHolder(
          content: _errMessage,
          title: _errTitle,
          displayed: _errMessage.isNotEmpty,
          isValid: _isErrValid,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                    const SizedBox(height: 10),
                    CircleAvatar(
                        radius: 100,
                        backgroundColor: Color.fromARGB(0, 0, 0, 0),
                        backgroundImage: NetworkImage(image_url != null
                            ? image_url!
                            : "https://i.imgur.com/yn1MAbB.jpg")),
                    Material(
                      color: Colors.white,
                      child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 15),
                              Container(
                                constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.7),
                                child: TextButton.icon(
                                  icon: const Icon(
                                    Icons.image_outlined,
                                    color: Color.fromARGB(255, 230, 230, 230),
                                  ),
                                  onPressed: pickImageFromGallery,
                                  style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateColor.resolveWith(
                                              (states) => const Color.fromARGB(
                                                  255, 25, 25, 25))),
                                  label: const Padding(
                                    padding:
                                        EdgeInsets.fromLTRB(20, 10, 20, 10),
                                    child: Text(
                                      "Changer votre image de profil",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 14,
                                        fontFamily: "Poppins",
                                        color:
                                            Color.fromARGB(255, 230, 230, 230),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 75),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.6,
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
                                      hintText: "Entrez un nom d'utilisateur",
                                      hintStyle: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 14,
                                        fontFamily: "Poppins",
                                        color: Color.fromARGB(128, 25, 25, 25),
                                      ),
                                      icon: Icon(Icons.person),
                                      labelText: "Nom d'utilisateur",
                                      labelStyle: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 14,
                                        fontFamily: "Poppins",
                                        color: Color.fromARGB(128, 25, 25, 25),
                                      ),
                                      hoverColor:
                                          Color.fromARGB(128, 25, 25, 25)),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Un nom d'utilisateur doit être renseigné";
                                    }
                                    return null;
                                  },
                                  style: const TextStyle(
                                      fontFamily: "Poppins",
                                      fontWeight: FontWeight.w500),
                                  controller: usernameController,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Container(
                                constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.7),
                                child: TextButton.icon(
                                  icon: const Icon(
                                    Icons.image_outlined,
                                    color: Color.fromARGB(255, 230, 230, 230),
                                  ),
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      final username = usernameController.text;
                                      var res = await ApiService.updateUsername(
                                          username);
                                      setState(() {
                                        usernameController.text =
                                            jsonDecode(res.body)["username"];
                                        _errMessage =
                                            "Vous avez changé votre nom d'utilisateur en: $username.";
                                        _errTitle = "Changement réussi";
                                        _isErrValid = true;
                                      });
                                      // Appeler la methode du Web Service pour modifier les infos de l'utilisateur
                                      print("Nouveau nom d'utilisateur : " +
                                          username);
                                    }
                                  },
                                  style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateColor.resolveWith(
                                              (states) => const Color.fromARGB(
                                                  255, 25, 25, 25))),
                                  label: const Padding(
                                    padding:
                                        EdgeInsets.fromLTRB(20, 10, 20, 10),
                                    child: Text(
                                      "Modifier le nom d'utilisateur",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 14,
                                        fontFamily: "Poppins",
                                        color:
                                            Color.fromARGB(255, 230, 230, 230),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )),
                    )
                  ])),
            ],
          ),
        ),
      ),
    );
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
