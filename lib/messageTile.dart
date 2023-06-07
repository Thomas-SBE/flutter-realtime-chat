import 'package:flutter/material.dart';
import 'package:chat_with_chatgpt/services/api.dart';

class MessageTile extends StatefulWidget {
  final String message;
  final bool sendByUser;
  final String? username;
  final String? image_url;

  const MessageTile({
    Key? key,
    required this.message,
    required this.sendByUser,
    this.username,
    this.image_url,
  }) : super(key: key);

  @override
  State<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends State<MessageTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment:
          widget.sendByUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
          mainAxisAlignment: widget.sendByUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!widget.sendByUser)
              Row(
                mainAxisAlignment: widget.sendByUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(this.widget.image_url !=
                                null &&
                            this.widget.image_url!.isNotEmpty
                        ? "${ApiService.BASE_URL}${widget.image_url}?v=${ApiService.PROFILEIMAGEVERSIONING}"
                        : "https://i.imgur.com/yn1MAbB.jpg"),
                  ),
                  SizedBox(
                    width: 10,
                  )
                ],
              ),
            Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 150),
              margin: widget.sendByUser
                  ? const EdgeInsets.only(
                      left: 80, right: 5, top: 7, bottom: 10)
                  : const EdgeInsets.only(
                      right: 80, left: 5, top: 7, bottom: 10),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: widget.sendByUser
                    ? const BorderRadius.only(
                        topRight: Radius.circular(20),
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      )
                    : const BorderRadius.only(
                        topRight: Radius.circular(20),
                        topLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                color: widget.sendByUser
                    ? const Color.fromARGB(255, 254, 212, 0)
                    : const Color.fromARGB(255, 229, 229, 229),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.username != null)
                    Text(widget.username!,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: Color.fromARGB(125, 38, 38, 38),
                            decoration: TextDecoration.underline,
                            fontFamily: "Poppins")),
                  Text(
                    widget.message,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Color.fromARGB(255, 38, 38, 38),
                        fontFamily: "Poppins"),
                  )
                ],
              ),
            ),
            if (widget.sendByUser)
              Row(
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  CircleAvatar(
                    radius: 15,
                    backgroundImage: NetworkImage(this.widget.image_url !=
                                null &&
                            this.widget.image_url!.isNotEmpty
                        ? (widget.image_url!.startsWith("/")
                            ? "${ApiService.BASE_URL}${widget.image_url}?v=${ApiService.PROFILEIMAGEVERSIONING}"
                            : "${widget.image_url}")
                        : "https://i.imgur.com/yn1MAbB.jpg"),
                  ),
                  SizedBox(
                    width: 10,
                  )
                ],
              ),
          ]),
    );
  }
}
