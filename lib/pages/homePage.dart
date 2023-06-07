import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:get_it/get_it.dart';
import 'package:chat_with_chatgpt/components/error_message.dart';
import 'package:chat_with_chatgpt/pages/UserInformationsPage.dart';
import 'package:chat_with_chatgpt/pages/loginPage.dart';
import 'package:chat_with_chatgpt/services/observable_socketio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:chat_with_chatgpt/model/channel.dart';
import 'chatPage.dart';
import '../swatchColor.dart';
import '../services/api.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  // A MODIFIER
  static List<String> names = [
    "Je suis un personnage de fiction",
    "Moi aussi",
    "De même",
    "J'en suis"
  ];

  // Ne pas rajouter des channels car le Webservice clean() celle-ci à chaque refresh de la page
  static List<ChannelModel> channels = [
    /*ChannelModel(name: "Jean, Eudes ...", acronym: "J&E"),
    ChannelModel(
        name: "Mark, Michel, Michelle ...",
        detail: "La semaine dernière nous avons fait !")
     */
  ];

  static int selfUserId = -1;

  static List<String> circleAvatar = ["JE", "MMM", "S", "T"];

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();

  String _errMessage = "";
  String _errTitle = "";
  String username = "";
  String image_url = "https://i.imgur.com/yn1MAbB.jpg";
  int id = 0;

  ObservableSocketIOService socket =
      GetIt.instance<ObservableSocketIOService>();

  // La fonction attempsInformations a pour objectif de récupérer l'ensemble des channels à partir de la route /me ainsi que les données de l'utilisateur
  // Elle s'exécute à chaque fois que la page HomePage est recharché
  void attempsInformations() async {
    http.Response? res;
    String resultMsgErr = "";
    String resultErrTitle = "";

    try {
      res = await ApiService.me();
      if (res.statusCode == 500) {
        // SERVER INTERNAL ERR
        resultMsgErr =
            "Erreur interne au serveur, contactez un administrateur.";
        resultErrTitle = "500 - Internal Server Error";
      } else if (res.statusCode == 401) {
        // SERVER INTERNAL ERR
        resultMsgErr =
            "Vous n'avez pas l'autorisation d'accéder à cette ressource";
        resultErrTitle = "401 - Unauthorized";
      }
    } catch (e) {
      resultMsgErr =
          "Impossible de contacter le serveur, vérifier la connexion vers le réseau ! Dans le cas échéant, contacter un administrateur du service.";
      resultErrTitle = "Erreur fatale - Connexion impossible";
    } finally {
      setState(() {
        if (resultMsgErr.isNotEmpty) {
          _errMessage = resultMsgErr;
          _errTitle = resultErrTitle;
          return;
        }

        if (res != null) {
          // On vient récupérer les channels en format JSON depuis le body de la réponse
          final _channels = jsonDecode(res.body)['channels'];
          // On vient clear l'ancienne liste pour éviter les doublons d'ajouts
          HomePage.channels.clear();
          for (var channel in _channels) {
            var _channel = ChannelModel(
                id: channel['channel_id'],
                name: channel['name'],
                image_url: channel['image_url']);
            HomePage.channels.add(_channel);
          }

          // On vient récupérer aussi les données de l'utilisateur
          Map data = jsonDecode(res.body)["self"];
          this.username = data["username"];
          if (data["image_url"] != null) {
            if (data["image_url"].toString().startsWith("/"))
              image_url =
                  "${ApiService.BASE_URL}${data['image_url']}?v=${ApiService.PROFILEIMAGEVERSIONING}";
            else
              image_url = data["image_url"];
          }
          this.id = data["user_id"];
          HomePage.selfUserId = this.id;
        }
      });
    }
  }

  void onError(dynamic err) {
    setState(() {
      _errMessage = err["message"] == "JWT_AUTH_MISSING"
          ? "Cannot find a correct token to authentificate the user on sockets."
          : "Invalid authentification token given to the socket.";
      _errTitle = "Socket Error";
    });
  }

  void onChannelUpdate(dynamic chan) {
    print("Received an update");
    attempsInformations();
  }

  void onUserUpdate(dynamic data) {
    setState(() {
      this.username = data["username"];
      if (data["image_url"] != null) {
        if (data["image_url"].toString().startsWith("/"))
          image_url =
              "${ApiService.BASE_URL}${data['image_url']}?v=${ApiService.PROFILEIMAGEVERSIONING}";
        else
          image_url = data["image_url"];
      }
      this.id = data["user_id"];
      HomePage.selfUserId = this.id;
    });
  }

  @override
  void initState() {
    super.initState();
    socket.listen(EVENT_TYPE.ERROR, onError);
    socket.listen(EVENT_TYPE.CHANNEL_UPDATE, onChannelUpdate);
    socket.listen(EVENT_TYPE.USER_UPDATE, onUserUpdate);
    attempsInformations(); // On appel le webservice lors de l'initialisation de la HomePage
  }

  int _selectedNavIndex = 0;
  var scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    socket.forget(EVENT_TYPE.ERROR, onError);
    socket.forget(EVENT_TYPE.CHANNEL_UPDATE, onChannelUpdate);
    socket.forget(EVENT_TYPE.USER_UPDATE, onUserUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: ErrorDialogHolder(
          content: _errMessage,
          title: _errTitle,
          displayed: _errMessage.isNotEmpty,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(50)),
                      onTap: () {
                        scaffoldKey.currentState!.openDrawer();
                      },
                      child: CircleAvatar(
                          backgroundColor: const Color.fromARGB(0, 0, 0, 0),
                          backgroundImage: NetworkImage(image_url)),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Text(
                        "Messages",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            fontSize: 36,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: HomePage.channels.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      child: Material(
                        child: Container(
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                          conv: HomePage.channels[index],
                                        )),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: NetworkImage(HomePage
                                                .channels[index].image_url !=
                                            null
                                        ? (HomePage.channels[index].image_url!
                                                .startsWith("/")
                                            ? "${ApiService.BASE_URL}${HomePage.channels[index].image_url}?v=${ApiService.CONVERSATIONVERSIONNING}"
                                            : "${HomePage.channels[index].image_url}")
                                        : "https://i.imgur.com/5W2Ssl0.png"),
                                  ),
                                  const SizedBox(width: 20),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          HomePage.channels[index].name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              fontFamily: "Poppins"),
                                        ),
                                        if (HomePage.channels[index].detail !=
                                                null &&
                                            HomePage.channels[index].detail!
                                                .isNotEmpty)
                                          Text(
                                            HomePage.channels[index].detail!,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.normal,
                                                fontSize: 14,
                                                fontFamily: "Poppins"),
                                          )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
            ],
          )),
      drawer: Drawer(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              child: Container(
                padding: EdgeInsets.only(top: 20, bottom: 20),
                child: Column(
                  children: [
                    CircleAvatar(
                        radius: 40,
                        backgroundColor: Color.fromARGB(0, 0, 0, 0),
                        backgroundImage: NetworkImage(image_url)),
                    const SizedBox(height: 10),
                    Text(
                      this.username,
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "#${HomePage.selfUserId}",
                      style: TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 105, 105, 105),
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
              leading: const Icon(Icons.create),
              title: const Text(
                "Modifier les informations du compte",
                style: TextStyle(fontFamily: "Poppins"),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserInformationsPage()),
                );
              }),
          ListTile(
            leading: const Icon(
              Icons.add_to_queue,
            ),
            title: const Text(
              "Créer un nouveau salon",
              style: TextStyle(fontFamily: "Poppins"),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return CreateChannelDialog();
                },
              );
            },
          ),
          Expanded(
              child: SizedBox(
            width: 10,
          )),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
            title: const Text(
              "Se déconnecter",
              style: TextStyle(color: Colors.red, fontFamily: "Poppins"),
            ),
            onTap: () {
              openConfirmationDialog();
            },
          )
        ],
      )),
    );
  }

  Future openConfirmationDialog() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirmation",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: "Poppins",
              )),
          content: const Text("Êtes-vous sur de vouloir vous déconnecter ?",
              style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                  fontFamily: "Poppins")),
          actions: [
            TextButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateColor.resolveWith(
                      (states) => Colors.transparent)),
              onPressed: logOut,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Text(
                  "Oui",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                    fontFamily: "Poppins",
                    color: Color.fromARGB(255, 26, 26, 26),
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
                    color: Color.fromARGB(255, 240, 240, 240),
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

  // Cette fonction permet de se deconnecter
  // On supprime le token de connexion
  void logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("token");
    setState(() {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
    });
  }
}

// Cette class a pour objectif d'utiliser une formulaire POST pour ajouter un Channel grâce au websersice
class CreateChannelDialog extends StatefulWidget {
  @override
  _CreateChannelDialogState createState() => _CreateChannelDialogState();
}

class _CreateChannelDialogState extends State<CreateChannelDialog> {
  final _formKey = GlobalKey<FormState>();
  String _channelName = '';
  String _errMessage = "";
  String _errTitle = "";

  // La fonction attemptNeChannel va appeler l'API pour créer un nouveau channel
  void attemptNewChannel(String name, dynamic members) async {
    http.Response? res;
    String resultMsgErr = "";
    String resultErrTitle = "";
    try {
      res = await ApiService.new_channel(name, members);
      if (res.statusCode == 500) {
        // SERVER INTERNAL ERR
        resultMsgErr =
            "Erreur interne au serveur, contactez un administrateur.";
        resultErrTitle = "500 - Internal Server Error";
      } else if (res.statusCode == 400) {
        // BAD REQ
        resultMsgErr =
            "Erreur de formatage des données envoyées, contactez un administrateur.";
        resultErrTitle = "400 - Bad Request";
      }
    } catch (e) {
      resultMsgErr =
          "Impossible de contacter le serveur, vérifier la connexion vers le réseau ! Dans le cas échéant, contacter un administrateur du service.";
      resultErrTitle = "Erreur fatale - Connexion impossible";
    } finally {
      setState(() {
        if (resultMsgErr.isNotEmpty) {
          _errMessage = resultMsgErr;
          _errTitle = resultErrTitle;
          return;
        }

        _errMessage = "";
      });
    }
  }

  // On vient créer un Widget de la forme d'une boite de dialogue comportant un formulaire
  // basé sur le AlertDialog, il comportera comme champs :
  // - name (TextFormField)
  // Actuellement le webservice ne permet pas d'ajouter d'autre informations comme les détails et l'acronyme
  // mais il est possible de rajouter des champs
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Créer un nouveau salon',
        style: TextStyle(fontFamily: "Poppins", fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color.fromARGB(128, 25, 25, 25), width: 1)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 25, 25, 25), width: 1.5)),
                hintText: "Nom du salon",
                hintStyle: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                  fontFamily: "Poppins",
                  color: Color.fromARGB(128, 25, 25, 25),
                ),
              ),
              style: const TextStyle(
                  fontFamily: "Poppins", fontWeight: FontWeight.w500),
              onChanged: (value) {
                setState(() {
                  _channelName = value;
                });
              },
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Veuillez entrer un nom de channel';
                }
                return null;
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateColor.resolveWith(
                  (states) => Colors.transparent)),
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Text(
              "Annuler",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
                fontFamily: "Poppins",
                color: Color.fromARGB(255, 26, 26, 26),
              ),
            ),
          ),
        ),
        TextButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateColor.resolveWith(
                  (states) => const Color.fromARGB(255, 25, 25, 25))),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // On vérifie si tous les champs valide et remplis

              // On vient appeler notre fonction pour ajouter le nouveau Channel en donnant en
              // paramètre la valeur du champs name
              attemptNewChannel(_channelName, []);

              // Ferme la boîte de dialogue
              Navigator.of(context).pop();
              // On vient refresh la page HomePage
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(),
                ),
              );
            }
          },
          child: const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Text(
              "Créer",
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
    );
  }
}
