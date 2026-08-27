import 'package:ccc_flutter/models/custom_list.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/services/book_service.dart';
import 'package:flutter/material.dart';

/// Bottom sheet that lets the user add/remove the given song
/// to/from their custom lists (and create a new list on the spot).
class SaveToListSheet extends StatefulWidget {
  final SongSummary song;
  final BookService bookService;

  SaveToListSheet({
    Key? key,
    required this.song,
    required this.bookService,
  }) : super(key: key);

  @override
  _SaveToListSheetState createState() => _SaveToListSheetState();
}

class _SaveToListSheetState extends State<SaveToListSheet> {
  List<CustomList>? _lists;
  Set<String> _memberListIds = {};

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    final lists = await widget.bookService.getCustomLists();
    final memberIds =
        await widget.bookService.getListIdsContaining(widget.song);
    if (mounted) {
      setState(() {
        _lists = lists;
        _memberListIds = memberIds;
      });
    }
  }

  Future<void> _toggleMembership(CustomList list, bool member) async {
    setState(() {
      if (member) {
        _memberListIds.add(list.id);
      } else {
        _memberListIds.remove(list.id);
      }
    });
    if (member) {
      await widget.bookService.addSongToList(list.id, widget.song);
    } else {
      await widget.bookService.removeSongFromList(list.id, widget.song);
    }
  }

  Future<void> _createListAndAdd() async {
    final name = await promptForListName(context, title: "Listă nouă");
    if (name == null || name.trim().isEmpty) {
      return;
    }
    final list = await widget.bookService.createList(name.trim());
    await widget.bookService.addSongToList(list.id, widget.song);
    await _loadLists();
  }

  @override
  Widget build(BuildContext context) {
    final lists = _lists;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(20, 15, 20, 5),
              child: Text(
                "Salvează în listă",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text(
                "Listă nouă",
                style: TextStyle(fontSize: 18),
              ),
              onTap: _createListAndAdd,
            ),
            if (lists == null)
              Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (lists.isEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(20, 5, 20, 20),
                child: Text(
                  "Nu ai încă nicio listă. Creează una ca să salvezi cântarea.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              )
            else
              ...lists.map((list) => CheckboxListTile(
                    title: Text(
                      list.name,
                      style: TextStyle(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondary: Icon(Icons.playlist_play),
                    value: _memberListIds.contains(list.id),
                    onChanged: (value) =>
                        _toggleMembership(list, value ?? false),
                  )),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// Shows a dialog asking for a list name. Returns null if cancelled.
Future<String?> promptForListName(BuildContext context,
    {required String title, String initialValue = ""}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: "Numele listei"),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Anulează"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text("Salvează"),
        ),
      ],
    ),
  );
}
