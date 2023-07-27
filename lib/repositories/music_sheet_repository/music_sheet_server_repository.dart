import 'dart:typed_data';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import 'package:ccc_flutter/repositories/music_sheet_repository/music_sheet_repository.dart';

const String musicSheetURL = 'https://cartecantari-music-sheets.s3.eu-central-1.amazonaws.com';

class MusicSheetServerRepository implements IMusicSheetRepository {
  MusicSheetServerRepository();

  @override
  Future<List<Uint8List>> getMusicSheet(List<String> fileNames, {bool forceResync = false}) async {
    final tasks = fileNames.map((fileName) => fetchFileFromServer(fileName));
    final results = await Future.wait(tasks);
    return results;
  }

  Future<Uint8List> fetchFileFromServer(String fileName) async {
    final response = await http.get(Uri.parse("$musicSheetURL/$fileName"));
    if (response.statusCode == 200) {
      developer.log("${DateTime.now()} Retrieved file $fileName from server");
      return response.bodyBytes;
    } else {
      throw Exception('Failed to fetch file from server');
    }
  }
}