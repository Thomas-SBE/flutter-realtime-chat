import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:chat_with_chatgpt/components/error_message.dart';
import 'package:chat_with_chatgpt/services/observable_socketio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'homePage.dart';
import 'registerPage.dart';
import '../services/api.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String? _email;
  String? _password;
  String _errMessage = "";
  String _errTitle = "";
  bool displayPage = false;

  void notifyError(String title, String content) {}

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    attempSoftLogin();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  void attempSoftLogin() async {
    GetIt.instance<ObservableSocketIOService>().disconnect();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    print("Attempted login to: ${ApiService.BASE_URL}");
    if (token != null) {
      var res = await ApiService.me();
      if (res.statusCode == 200) {
        await GetIt.instance<ObservableSocketIOService>().init();
        setState(() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        });
        return;
      }
    }
    setState(() {
      displayPage = true;
    });
  }

  void attemptLogin() async {
    GetIt.instance<ObservableSocketIOService>().disconnect();
    http.Response? res;
    String resultMsgErr = "";
    String resultErrTitle = "";
    try {
      res = await ApiService.login(_email!, _password!);
      print("${res.statusCode} : ${res.body}");
      final token = res.headers[HttpHeaders.authorizationHeader];
      if (token != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
      }
      if (res.statusCode == 404) {
        // MSG ERR INVALID CREDS..
        resultMsgErr = "Les identifiants / mot de passe donnés n'existent pas.";
        resultErrTitle = "Utilisateur introuvable";
      } else if (res.statusCode == 500) {
        // SERVER INTERNAL ERR
        resultMsgErr =
            "Erreur interne au serveur, contactez un administrateur.";
        resultErrTitle = "500 - Internal Server Error";
      } else if (res.statusCode == 400) {
        // BAD REQ
        resultMsgErr =
            "Erreur de formatage des données envoyées, contactez un administrateur.";
        resultErrTitle = "402 - Bad Request";
      }
    } catch (e) {
      resultMsgErr =
          "Impossible de contacter le serveur, vérifier la connexion vers le réseau ! Dans le cas échéant, contacter un administrateur du service.";
      resultErrTitle = "Erreur fatale - Connexion impossible";
      print(e);
    } finally {
      await GetIt.instance<ObservableSocketIOService>().init();

      setState(() {
        if (resultMsgErr.isNotEmpty) {
          _errMessage = resultMsgErr;
          _errTitle = resultErrTitle;
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!displayPage) return const SizedBox();
    return Scaffold(
      backgroundColor: const Color.fromRGBO(248, 211, 0, 1),
      body: ErrorDialogHolder(
          content: _errMessage,
          title: _errTitle,
          displayed: _errMessage.isNotEmpty,
          child: Form(
            key: _formKey,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    "Connexion",
                    style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 42,
                        fontWeight: FontWeight.w700),
                  ),
                  /*if (_errMessage.isNotEmpty)
                Column(
                  children: [
                    DecoratedBox(
                        decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 225, 12, 12),
                            borderRadius: BorderRadius.all(Radius.circular(5))),
                        child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                            child: Text(
                              _errMessage,
                              style: const TextStyle(
                                  fontFamily: "Poppins",
                                  color: Color.fromARGB(255, 243, 243, 243)),
                            ))),
                    const SizedBox(height: 10)
                  ],
                ),*/

                  const SizedBox(height: 25),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(128, 25, 25, 25),
                                width: 1)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 25, 25, 25),
                                width: 1.5)),
                        hintText: "Identifiant",
                        hintStyle: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                          fontFamily: "Poppins",
                          color: Color.fromARGB(128, 25, 25, 25),
                        ),
                      ),
                      style: const TextStyle(
                          fontFamily: "Poppins", fontWeight: FontWeight.w500),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Veuillez entrer un identifiant';
                        }
                        return null;
                      },
                      onFieldSubmitted: (value) {
                        if (_formKey.currentState?.validate() ?? false) {
                          _formKey.currentState?.save();
                          attemptLogin();
                        }
                      },
                      onSaved: (value) {
                        _email = value;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(128, 25, 25, 25),
                                width: 1)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 25, 25, 25),
                                width: 1.5)),
                        hintText: "Mot de passe",
                        hintStyle: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                          fontFamily: "Poppins",
                          color: Color.fromARGB(128, 25, 25, 25),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Veuillez entrer un mot de passe';
                        }
                        return null;
                      },
                      onFieldSubmitted: (value) {
                        if (_formKey.currentState?.validate() ?? false) {
                          _formKey.currentState?.save();
                          attemptLogin();
                        }
                      },
                      onSaved: (value) {
                        _password = value;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateColor.resolveWith(
                            (states) => const Color.fromARGB(255, 25, 25, 25))),
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState?.save();
                        attemptLogin();
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: Text(
                        "Se connecter",
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
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: goToRegisterPage,
                    child: Text(
                      "Créer un compte",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                        fontFamily: "Poppins",
                        color: Color.fromARGB(255, 25, 25, 25),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )),
    );
  }

  void goToRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }
}
