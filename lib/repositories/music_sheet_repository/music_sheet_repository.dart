import 'dart:typed_data';

abstract class IMusicSheetRepository {
  Future<List<Uint8List>> getMusicSheet(List<String> fileNames, {bool forceResync});
}
