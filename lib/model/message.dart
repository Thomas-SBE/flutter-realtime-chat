class MessageModel {
  int id;
  DateTime sent;
  String content;
  int sentBy;

  MessageModel(
      {required this.id,
      required this.sent,
      required this.content,
      required this.sentBy});
}
