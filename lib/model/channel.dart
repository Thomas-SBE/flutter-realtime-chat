import 'package:chat_with_chatgpt/model/user.dart';

class ChannelModel {
  ChannelModel(
      {required this.id,
      required this.name,
      this.detail,
      this.acronym,
      this.image_url,
      this.adminId});

  int id;
  String name;
  String? detail;
  String? acronym;
  String? image_url;
  int? adminId;
  List<UserModel>? members;
}
