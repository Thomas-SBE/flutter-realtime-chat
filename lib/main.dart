import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:chat_with_chatgpt/services/observable_socketio_service.dart';
import 'swatchColor.dart';
import 'pages/chatPage.dart';
import 'pages/homePage.dart';
import 'pages/loginPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    GetIt.instance.registerSingleton<ObservableSocketIOService>(
        ObservableSocketIOService());

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Chat with ChatGPT",
      theme: ThemeData(
        primarySwatch: swatchColor.kToDark,
      ),
      home: LoginPage(),
    );
  }
}
