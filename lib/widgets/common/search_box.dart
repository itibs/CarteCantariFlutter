import 'package:ccc_flutter/constants.dart';
import 'package:flutter/material.dart';

class SearchBox extends StatefulWidget {
  final void Function(String) onTextChanged;
  final void Function() onClear;
  final TextEditingController txtController;

  SearchBox({onTextChanged, onClear, txtController})
      : this.txtController = txtController ?? new TextEditingController(),
    onTextChanged = onTextChanged ?? (String),
  onClear = onClear ?? VoidCallback;

  @override
  SearchBoxState createState() => SearchBoxState();
}

class SearchBoxState extends State<SearchBox> {
  String? _previousText;

  @override
  void initState() {
    super.initState();

    _previousText = widget.txtController.text;
  }

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
                  .addPostFrameCallback((_) => widget.txtController.clear());
              widget.onClear();
            },
          ),
          visible: widget.txtController.text != "",
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
      onChanged: (newText) {
        if (newText != _previousText) {
          widget.onTextChanged(newText);
          setState(() {
            _previousText = newText;
          });
        }
      },
      controller: widget.txtController,
    );
  }
}
