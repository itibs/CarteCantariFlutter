import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:flutter/material.dart';

class CategoryList extends StatelessWidget {
  final Future<void> Function(String category, List<Song> songs) onTap;
  final Map<String, List<Song>> categories;

  CategoryList({this.categories, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesList = categories.keys.toList();

    return ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        itemCount: categoriesList.length,
        itemBuilder: (context, i) {
          final index = i;
          return _buildRow(categoriesList[index], isDark);
        });
  }

  Widget _buildRow(String category, bool isDark) {
    final numFont = TextStyle(
      fontSize: 17.0,
      fontWeight: FontWeight.w400,
      color: isDark
          ? COLOR_LIGHT_BLUE.withAlpha(255)
          : COLOR_DARKER_BLUE.withAlpha(140),
    );

    final songTitleFont = const TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w500,
    );

    var categorySongs = categories[category];

    Widget txtNum = Text(
      " (" + categorySongs.length.toString() + ")",
      style: numFont,
    );

    Widget txtTitle = Flexible(
        child: Text(
      category,
      style: songTitleFont,
      overflow: TextOverflow.fade,
      softWrap: false,
    ));

    return ListTile(
      title: Row(
        children: [txtTitle, txtNum],
      ),
      onTap: () async {
        await onTap(category, categorySongs);
      },
      dense: true,
    );
  }
}
