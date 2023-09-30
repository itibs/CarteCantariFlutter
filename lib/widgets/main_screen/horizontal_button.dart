import 'package:flutter/material.dart';

class HorizontalButton extends StatelessWidget {
  final VoidCallback callback;
  final bool visible;
  final String text;
  final Color color;
  final Color darkColor;

  HorizontalButton({Key? key, required this.callback, required this.visible, required this.text, required this.color, required this.darkColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lyricSearchButtonColor = isDark ? darkColor : color;
    if (visible) {
      return TextButton(
          onPressed: callback,
          style: ButtonStyle(
            shape: MaterialStateProperty.all(RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(10.0),
              side: BorderSide(color: lyricSearchButtonColor),
            )),
            backgroundColor: MaterialStateProperty.all(lyricSearchButtonColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.search,
                color: Colors.white,
              ),
              Text(
                text,
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.white,
                ),
              ),
            ],
          )
      );
    }
    return Container();
  }
}