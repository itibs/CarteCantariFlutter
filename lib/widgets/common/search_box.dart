import 'package:ccc_flutter/constants.dart';
import 'package:flutter/material.dart';

class SearchBox extends StatelessWidget {
  final void Function(String) onTextChanged;
  final void Function() onClear;
  final TextEditingController txtController;

  SearchBox({this.onTextChanged, this.onClear, txtController})
      : this.txtController = txtController ?? new TextEditingController();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      enableInteractiveSelection: true,
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.search,
          color: isDark ? COLOR_LIGHT_BLUE : COLOR_DARK_BLUE,
        ),
        suffixIcon: Visibility(
          child: GestureDetector(
            child: Icon(
              Icons.clear,
              color: isDark ? COLOR_LIGHT_BLUE : COLOR_DARK_BLUE,
            ),
            onTap: () {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => txtController.clear());
              onClear();
            },
          ),
          visible: txtController.text != "",
        ),
        hintText: 'Caută...',
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color:
                  isDark ? COLOR_DARKER_BLUE.withOpacity(0.9) : Colors.black12),
          borderRadius: BorderRadius.circular(10.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color:
                  isDark ? COLOR_DARKER_BLUE.withOpacity(0.9) : Colors.black12),
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding: new EdgeInsets.all(0),
      ),
      style: new TextStyle(
        fontSize: 20.0,
      ),
      onChanged: onTextChanged,
      controller: txtController,
    );
  }
}
