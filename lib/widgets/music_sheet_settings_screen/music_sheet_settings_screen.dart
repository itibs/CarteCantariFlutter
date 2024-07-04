import 'package:ccc_flutter/blocs/settings/allow_cor_music_sheets/allow_cor_music_sheets.dart';
import 'package:ccc_flutter/blocs/settings/allow_jubilate_music_sheets/allow_jubilate_music_sheets.dart';
import 'package:ccc_flutter/services/music_sheet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import '../../helpers.dart';
import '../../models/song.dart';

class MusicSheetSettingsScreen extends StatefulWidget {
  final Future<Set<Song>> songs;
  final MusicSheetService musicSheetService;

  MusicSheetSettingsScreen({
    Key? key,
    required this.songs,
  })  : musicSheetService = MusicSheetService(),
        super(key: key);

  @override
  _MusicSheetSettingsScreenState createState() =>
      _MusicSheetSettingsScreenState();
}

class _MusicSheetSettingsScreenState extends State<MusicSheetSettingsScreen> {
  var _downloadedFiles = 0;
  var _totalFiles = 0;
  FToast _fToast;

  _MusicSheetSettingsScreenState() : _fToast = FToast();

  @override
  void initState() {
    super.initState();

    _fToast.init(context);

    _getMusicSheetFileNames(widget.songs).then((fileNames) {
      _totalFiles = fileNames.length;
      widget.musicSheetService
          .getDownloadedFilesCount(fileNames)
          .then((value) => setState(() => _downloadedFiles = value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final allowJubilateMusicSheets =
        context.watch<AllowJubilateMusicSheetsCubit>();
    final allowCorMusicSheets = context.watch<AllowCorMusicSheetsCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Opțiuni partituri",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          ListTile(
            title: Text(
              'Descarcă local toate partiturile',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            subtitle: Text(
              'Dacă descarci toate partiturile, vei avea acces la ele și atunci când nu ai internet.\nAcestea ocupă ~200MB din memoria telefonului.',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
            onTap: () async {
              try {
                await for (var downloadedFilesCount in widget.musicSheetService
                    .downloadAllFiles(
                        await _getMusicSheetFileNames(widget.songs))) {
                  setState(() {
                    _downloadedFiles = downloadedFilesCount;
                  });
                }
                showToast("Partiturile au fost descărcate", _fToast);
              } catch (e) {
                showToast(
                    "A apărut o eroare la descărcarea partiturilor", _fToast);
              }
            },
          ),
          ListTile(
            title: Text(
              'Șterge toate partiturile',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            subtitle: Text(
              'Vei putea vizualiza partiturile doar dacă ai conexiune la internet.',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
            onTap: () {
              widget.musicSheetService.deleteAllFiles().then((value) {
                setState(() {
                  _downloadedFiles = 0;
                });
                showToast("Partiturile au fost șterse", _fToast);
              },
                  onError: (error, stackTrace) => showToast(
                      "A apărut o eroare la ștergerea partiturilor", _fToast));
            },
          ),
          Divider(),
          !allowJubilateMusicSheets.state
              ? ListTile(
                  title: Text(
                    'Obține acces pentru Jubilate',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  subtitle: Text(
                    'Pentru a obține un cod de acces trebuie să demonstrezi că deții culegerile (vol 1 & 2).',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    _showObtainAccessModalDialog(context,
                        "Trimite un e-mail la adresa tiberiu.irg@gmail.com în care să demonstrezi că deții culegerile Jubilate.",
                        () {
                      allowJubilateMusicSheets.setValue(true);
                      showToast(
                          "Partiturile Jubilate au fost activate", _fToast);
                    });
                  },
                )
              : Container(),
          !allowCorMusicSheets.state
              ? ListTile(
                  title: Text(
                    'Obține acces pentru Cor',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  subtitle: Text(
                    'Pentru a obține un cod de acces trebuie să faci parte din Corul Evanghelic.',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    _showObtainAccessModalDialog(context,
                        "Trimite un e-mail la adresa tiberiu.irg@gmail.com în care să ceri cod pentru deblocare dacă faci parte din Corul Evanghelic.",
                        () {
                      allowCorMusicSheets.setValue(true);
                      showToast("Partiturile de Cor au fost activate", _fToast);
                    });
                  },
                )
              : Container(),
          (!allowCorMusicSheets.state || !allowJubilateMusicSheets.state)
              ? Divider()
              : Container(),
          ListTile(
              title: Text(_totalFiles == 0
                  ? "Partituri descărcate: (se încarcă...)"
                  : "Partituri descărcate: ${_downloadedFiles.toString()}/$_totalFiles"))
        ],
      ),
    );
  }

  _showObtainAccessModalDialog(
      context, String message, void Function() callback) {
    final tokenVerifierUrl =
        "https://jtqw98uksa.execute-api.eu-central-1.amazonaws.com/music_sheet_token/";
    final textController = TextEditingController();

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text("Obținere acces partituri"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      textScaleFactor: 0.7,
                    ),
                    // OutlinedButton(
                    //   child: Text("Trimite email pentru a obține cod"),
                    //   onPressed: () async {
                    //     // try {
                    //     //   await FlutterEmailSender.send(email);
                    //     //   setState(() => _errorOpeningEmail = false);
                    //     // } catch (e) {
                    //     //   setState(() => _errorOpeningEmail = true);
                    //     // }
                    //   },
                    // ),
                    // _errorOpeningEmail ? Text(
                    //   "A apărut o eroare la deschiderea aplicației de e-mail.\nPoți trimite un e-mail la adresa tiberiu.irg@gmail.com în care să demonstrezi că deții culegerile Jubilate.",
                    //   textScaleFactor: 0.7,
                    //   style: TextStyle(
                    //     color: Colors.red,
                    //     fontStyle: FontStyle.italic,
                    //   ),
                    // ) : Container(),
                    Padding(
                        padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                        child: Text(
                          "Introdu codul de acces:",
                          textScaleFactor: 0.7,
                        )),
                    TextField(
                      controller: textController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: Text("Trimite"),
                    onPressed: () {
                      final url = tokenVerifierUrl + textController.value.text;
                      http.get(Uri.parse(url)).then((response) {
                        if (response.statusCode == 200) {
                          callback();
                        } else {
                          showToast("Cod incorect", _fToast);
                        }
                      }).onError((error, stackTrace) {
                        showToast(
                            "A apărut o eroare, încearcă mai târziu", _fToast);
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        });
  }

  Future<List<String>> _getMusicSheetFileNames(Future<Set<Song>> songs) async {
    final songsSet = await songs;
    return songsSet.fold<Set<String>>(Set<String>(), (previousValue, song) {
      if (song.musicSheet == null) {
        return previousValue;
      }
      previousValue.addAll(song.musicSheet!);
      return previousValue;
    }).toList();
  }
}
