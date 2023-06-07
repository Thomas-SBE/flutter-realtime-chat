import 'package:flutter/material.dart';

class ErrorDialogHolder extends StatefulWidget {
  ErrorDialogHolder(
      {super.key,
      required this.content,
      this.title,
      this.child,
      required this.displayed,
      this.isValid = false,
      this.background});

  final String? title;
  final String content;
  final Widget? child;
  bool displayed;
  bool isValid;
  final Color? background;

  @override
  _ErrorDialogHolderState createState() => _ErrorDialogHolderState();
}

class _ErrorDialogHolderState extends State<ErrorDialogHolder>
    with SingleTickerProviderStateMixin {
  void onClickedThePopup(TapDownDetails details) {
    setState(() {
      widget.displayed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color:
          widget.background == null ? Colors.transparent : widget.background!,
      child: Stack(children: [
        if (widget.child != null) widget.child!,
        if (widget.displayed)
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: widget.isValid
                          ? const Color.fromARGB(255, 9, 161, 67)
                          : const Color.fromARGB(255, 228, 30, 30)),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                                onTapDown: onClickedThePopup,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (widget.title != null &&
                                          widget.title!.isNotEmpty)
                                        Text(
                                          widget.title!,
                                          style: const TextStyle(
                                              color: Color.fromARGB(
                                                  255, 223, 223, 223),
                                              fontFamily: "Poppins",
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                      Text(
                                        widget.content,
                                        style: const TextStyle(
                                            color: Color.fromARGB(
                                                255, 223, 223, 223),
                                            fontFamily: "Poppins",
                                            fontWeight: FontWeight.normal,
                                            fontSize: 12),
                                      )
                                    ],
                                  ),
                                ))
                          ]),
                    )
                  ]))),
      ]),
    );
  }
}
