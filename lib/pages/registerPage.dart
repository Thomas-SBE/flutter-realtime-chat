import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:chat_with_chatgpt/components/error_message.dart';
import 'package:chat_with_chatgpt/pages/loginPage.dart';
import 'package:chat_with_chatgpt/services/observable_socketio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'homePage.dart';
import '../services/api.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String? _email;
  String? _password;
  String? _verifPassword;
  String _errMessage = "";
  String _errTitle = "";

  bool _isObscure = true;
  bool _isObscureVerif = true;

  void attemptRegister() async {
    GetIt.instance<ObservableSocketIOService>().disconnect();
    http.Response? res;
    String resultMsgErr = "";
    String resultErrTitle = "";
    try {
      res = await ApiService.register(_email!, _password!);
      final token = res.headers[HttpHeaders.authorizationHeader];
      if (token != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
      }
      print(res.statusCode);
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
      } else if (res.statusCode == 409) {
        resultMsgErr =
            "Erreur de creation de l'utilisateur, l'identifiant est déjà utilisé";
        resultErrTitle = "409 - Conflict";
      }
    } catch (e) {
      resultMsgErr =
          "Impossible de contacter le serveur, vérifier la connexion vers le réseau ! Dans le cas échéant, contacter un administrateur du service.";
      resultErrTitle = "Erreur fatale - Connexion impossible";
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
                    "Créer un compte",
                    style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 42,
                        fontWeight: FontWeight.w700),
                  ),
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
                      onSaved: (value) {
                        _email = value;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: TextFormField(
                      obscureText: _isObscure,
                      decoration: InputDecoration(
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
                        suffixIcon: IconButton(
                          icon: Icon(_isObscure
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(
                              () {
                                _isObscure = !_isObscure;
                              },
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Veuillez entrer un mot de passe';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _password = value;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: TextFormField(
                      obscureText: _isObscureVerif,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(128, 25, 25, 25),
                                width: 1)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 25, 25, 25),
                                width: 1.5)),
                        hintText: "Vérification du mot de passe",
                        hintStyle: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                          fontFamily: "Poppins",
                          color: Color.fromARGB(128, 25, 25, 25),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_isObscureVerif
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(
                              () {
                                _isObscureVerif = !_isObscureVerif;
                              },
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Veuillez entrer un mot de passe';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _verifPassword = value;
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
                        int? lenght = _password?.length;
                        if (_password != _verifPassword) {
                          String resultMsgErr =
                              "Les mots de passe donnés ne sont pas les mêmes.";
                          String resultErrTitle = "Erreur dans le formulaire";
                          setState(() {
                            _errMessage = resultMsgErr;
                            _errTitle = resultErrTitle;
                            return;
                          });
                          return;
                        } else if (lenght! < 4) {
                          String resultMsgErr =
                              "Votre mot de passe doit avoir plus de 4 caractères";
                          String resultErrTitle = "Erreur dans le formulaire";
                          setState(() {
                            _errMessage = resultMsgErr;
                            _errTitle = resultErrTitle;
                            return;
                          });
                          return;
                        }
                        attemptRegister();
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: Text(
                        "Créer son compte",
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
                    onPressed: goToLoginPage,
                    child: Text(
                      "Retour à la connexion",
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

  void goToLoginPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void inversedPasswordView() {
    _isObscure = !_isObscure;
  }
}
