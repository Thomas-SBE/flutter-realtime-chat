import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet/main.dart';
import 'package:projet/model/channel.dart';
import 'package:projet/services/api.dart';
import "package:http/http.dart" as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Durant toute la durée des test, je vais utiliser le compte suivant 
  // Identifiant : test@test.gmail.com, mot de passe : widgetTest
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  SharedPreferences.setMockInitialValues({});

  // Valeur recupéré au fur et à mesure des tests;
  String token = "";
  int idTestUser = -1;
  String tokenInviteUser = "";
  int idInviteUser = -1;
  
  // Valeur de la channel crée
  int channel_id = -1;
  String channel_name = "Test Channel";
  ChannelModel channel = ChannelModel(id:channel_id, name: channel_name);
  ChannelModel wrongChannel = ChannelModel(id:19087, name: channel_name);

  // Le groupe de test d'inscription ne fonctionnera que pendant le premier lancement des tests
  // Comme les comptes seront ensuite inscrit, il sera impossible de les inscrire à nouveau
  // Pour le reste, ils peuvent s'éxecuter sans problème (exception avec l'appel a l'API de ChatGPT qui peut provoquer un timeout)
  group("Inscription d'un utilisateur :", () {
    test("L'utilisateur doit être crée sans problème (premier lancement des test sinon echoue car le compte est déjà crée)", () async {
      http.Response? res;

      // On inscrit un autre utilisateur pour faire les tests d'invitations et de kick
      res = await ApiService.register("invite@test.gmail.com", "Invite");
      expect(res.headers[HttpHeaders.authorizationHeader], isNotNull);
      expect(res.statusCode, 200);

      // On inscrit ensuite le compte qui va nous servir pour la plupart des tests
      res = await ApiService.register("test@test.gmail.com", "widgetTest"); 
      expect(res.headers[HttpHeaders.authorizationHeader], isNotNull);
      expect(res.statusCode, 200);
      
    });

    test("L'utilisateur ne doit pas être crée (nom d'utilisateur déjà pris)", () async {
      http.Response? res;
      res = await ApiService.register("test@test.gmail.com", "TestInscription"); 
      expect(res.statusCode, 409);
    });
  });

  group("Connexion d'un utilisateur : ", () {
    test("La connexion de l'utilisateur doit réussir", () async {
      http.Response? res;

      // On recupere le token du compte à inviter
      res = await ApiService.login("invite@test.gmail.com", "Invite"); 

      tokenInviteUser = res.headers[HttpHeaders.authorizationHeader]!;
      expect(res.headers[HttpHeaders.authorizationHeader], isNotNull);
      expect(res.statusCode, 200);

      // On recupere ensuite le token pour le compte de test
      res = await ApiService.login("test@test.gmail.com", "widgetTest"); 
      token = res.headers[HttpHeaders.authorizationHeader]!;
      expect(res.headers[HttpHeaders.authorizationHeader], isNotNull);
      expect(res.statusCode, 200);


    });

    test("La connexion de l'utilisateur ne doit pas réussir (mauvais mot de passe)", () async {
      http.Response? res;
      res = await ApiService.login("test@test.gmail.com", "TestConnexion"); 
      expect(res.statusCode, 404);
    });
  });

  group("Recuperation des informations de l'utilisateur courant : ", () { 

    test("La récupération des informations de l'utilisateur courant doit réussir", () async {

      http.Response? res;

      // On recupère les données du compte à inviter
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', tokenInviteUser);

      res = await ApiService.me();
      expect(res.statusCode, 200);
      Map data = jsonDecode(res.body)["self"];
      expect(data, isNotNull);
      idInviteUser = data["user_id"];

      // On recupère ensuite les données du compte de test
      await prefs.setString('token', token);

      res = await ApiService.me();
      expect(res.statusCode, 200);

      data = jsonDecode(res.body)["self"];
      expect(data, isNotNull);
      idTestUser = data["user_id"];

    });

    test("La récupération des informations de l'utilisateur courant ne doit pas réussir (token de connexion null)", () async {

      // Pour ce test, on retire le token de connexion et on verifie le code de retour
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', "");

      http.Response? res;
      res = await ApiService.me();

      expect(res.statusCode, 401);

    });
  });

  group("Récuperation des données d'un utilisateur avec son id : ", () {

    test("La récupération des données doit réussir", () async {
      http.Response? res;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      res = await ApiService.getUsersInfos(idTestUser);
      Map data = jsonDecode(res.body)["info"];

      expect(res.statusCode, 200);
      expect(data, isNotNull);
      expect(data["user_id"], idTestUser);
    });

    test("La récupération des données ne doit pas réussir (mauvais id)", () async {
      http.Response? res;
      res = await ApiService.getUsersInfos(129281921);
      expect(res.statusCode, 500);
    });
   });

  group("Modification du nom d'utilisateur : ", () { 
    
    test("La modification du nom d'utilisateur doit réussir", () async {
      http.Response? res;
      res = await ApiService.updateUsername("UpdateTest");
      expect(res.statusCode, 200);
    });

    test("La modification du nom d'utilisateur ne doit pas réussir (nouvel nom d'utilisateur vide)", () async {
      http.Response? res;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', "");
      res = await ApiService.updateUsername("NouvelleModifsUsername");
      await prefs.setString('token', token);

      expect(res.statusCode, 401);
      
    });
  });

   group("Création d'une nouvelle discussion : ", () { 
    test("La création de la discussion doit réussir", () async{
      http.Response? res;

      res = await ApiService.new_channel(channel_name, []);
      Map data = jsonDecode(res.body);
      channel_id = data["channel_id"];
      channel = ChannelModel(id:channel_id, name: channel_name);

      expect(res.statusCode, 200);
      expect(data, isNotNull);
    });

    test("La création de la discussion ne doit pas réussir (nom de conversation vide [ normalement geré par le formulaire])", () async{
      http.Response? res;
      res = await ApiService.new_channel("", []);
      expect(res.statusCode, 400);
    });
   });

    

   group("Envoi de message : ", () { 
    test("Envoi de message qui doit réussir",() async{
        http.Response? res;
        res = await ApiService.sendMessage("Message de test",channel);
        expect(res.statusCode,200);
    });

    test("Envoi de message qui ne doit pas réussir (id de conversation inexistant)",() async{
        http.Response? res;
        res = await ApiService.sendMessage("",wrongChannel);
        expect(res.statusCode,401);
    });
   });

   group("Récuperation des informations de la discussion : ", () { 

    test("La récupération doit réussir", () async {
      http.Response? res;
      res = await ApiService.getChannelInformations(channel);
      Map data = jsonDecode(res.body);

      expect(res.statusCode, 200);
      expect(data, isNotNull);
      expect(data["channel_id"], channel.id);
      expect(data["name"], channel.name);
      expect(data["admin"], idTestUser);
    });

    test("La récupération ne doit pas réussir (id de conversation inexistant)", () async {
      http.Response? res;
      res = await ApiService.getChannelInformations(wrongChannel);
      expect(res.statusCode, 404);
    });
   });

   group("Récuperation des messages de la discussion : ", () { 

    test("La récupération doit réussir", () async {
      http.Response? res;
      res = await ApiService.getMessagesFromChannel(channel);
      List<dynamic> data = jsonDecode(res.body);

      expect(res.statusCode, 200);
      expect(data, isNotNull);
    });

    test("La récupération ne doit pas réussir (id de conversation inexistant)", () async {
      http.Response? res;
      res = await ApiService.getMessagesFromChannel(wrongChannel);
      expect(res.statusCode, 401);
    });
   });
   
   group("Appel de ChatGPT : ", () {
    test("L'appel doit réussir", () async{
      http.Response? res;
      res = await ApiService.callChatGPT(channel_id);
      expect(res.statusCode, 200);
    });

    test("L'appel ne doit pas réussir", () async{
      http.Response? res;
      res = await ApiService.callChatGPT(19087);
      expect(res.statusCode, 401);
    });
   });

  group("Mise à jour des informations d'une discussion : ", () { 
    test("La mise à jour doit réussir", () async {
      http.Response? res;
      channel_name = "Update Test Channel";
      res = await ApiService.updateChannelInfo(channel_id, channel_name);
      // Mise a jour de la variable channel
      channel = ChannelModel(id: channel_id, name: channel_name);
      Map data = jsonDecode(res.body);

      expect(res.statusCode, 200);
      expect(data,isNotNull);
      expect(data["channel_id"],channel_id);
      expect(data["name"], channel_name);
      expect(data["admin"], idTestUser);
    });

    test("La mise à jour ne doit pas réussir (id de conversation inexistant)", () async {
      http.Response? res;
      channel_name = "Update Test Channel";
      res = await ApiService.updateChannelInfo(19087, channel_name);
      expect(res.statusCode, 401);
    });
  });

  group("Liste de toutes les utilisateurs non invités dans la conversation : ", () { 

    test("La récupération de la liste doit réussir", () async{
      http.Response? res;
      res = await ApiService.getAllUninvitedUsers(channel);
      expect(res.statusCode, 200);
    });

    test("La récupération de la liste ne doit pas réussir (id de conversation inexistant)", () async{
      http.Response? res;
      res = await ApiService.getAllUninvitedUsers(wrongChannel);
      expect(res.body, isNotNull);
    });
  });

  group("Inviter un utilisateur : ", () {
    test("L'invitation doit réussir", () async {
      http.Response? res;
      res = await ApiService.inviteUser(channel_id, idInviteUser);
      expect(res.statusCode, 200);
    });

    test("L'invitation ne doit pas réussir (id de la conversation inexistant)", () async {
      http.Response? res;
      res = await ApiService.inviteUser(19087, idInviteUser);
      expect(res.statusCode, 404);
    });

    test("L'invitation ne doit pas réussir (id user inexistant)", () async {
      http.Response? res;
      res = await ApiService.inviteUser(channel_id, 2324);
      expect(res.statusCode, 404);
    });
   });

   group("Expulser un utilisateur : ", () { 

    test("L'expulsion doit réussir", () async{ 
      http.Response? res;
      res = await ApiService.kickUser(channel_id, idInviteUser);
      expect(res.statusCode, 200);
    });

    test("L'expulsion ne doit pas réussir (utilisateur déjà exclus)", () async{ 
      http.Response? res;
      res = await ApiService.kickUser(channel_id, idInviteUser);
      expect(res.statusCode, 409);
    });
   });

   group("Quitter une conversation : ", () { 

    test("L'action de quitter la conversation doit réussir", () async{ 
      http.Response? res;
      res = await ApiService.leaveConversation(channel_id, idInviteUser);
      expect(res.statusCode, 200);
    });

    test("L'action de quitter la conversation ne doit pas réussir (conversation déjà quitté)", () async{ 
      http.Response? res;
      res = await ApiService.leaveConversation(channel_id, idInviteUser);
      expect(res.statusCode, 401);
    });
   });
}
