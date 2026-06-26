import 'package:bloc_test/bloc_test.dart';
import 'package:ccc_flutter/blocs/settings/allow_cor_music_sheets/allow_cor_music_sheets_cubit.dart';
import 'package:ccc_flutter/blocs/settings/allow_jubilate_music_sheets/allow_jubilate_music_sheets_cubit.dart';
import 'package:ccc_flutter/blocs/settings/prioritze_music_sheets/prioritize_music_sheets_cubit.dart';
import 'package:ccc_flutter/blocs/settings/show_key_signatures/show_key_signatures_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ShowKeySignaturesCubit', () {
    test('initial state is false', () {
      expect(ShowKeySignaturesCubit().state, isFalse);
    });

    blocTest<ShowKeySignaturesCubit, bool>(
      'emits true when set to true',
      build: () => ShowKeySignaturesCubit(),
      act: (cubit) => cubit.setValue(true),
      expect: () => [true],
    );

    blocTest<ShowKeySignaturesCubit, bool>(
      'does nothing when set to null',
      build: () => ShowKeySignaturesCubit(),
      act: (cubit) => cubit.setValue(null),
      expect: () => const <bool>[],
    );
  });

  group('PrioritizeMusicSheetsCubit', () {
    test('initial state is false', () {
      expect(PrioritizeMusicSheetsCubit().state, isFalse);
    });

    blocTest<PrioritizeMusicSheetsCubit, bool>(
      'emits the value it is set to',
      build: () => PrioritizeMusicSheetsCubit(),
      act: (cubit) => cubit.setValue(true),
      expect: () => [true],
    );
  });

  group('AllowCorMusicSheetsCubit', () {
    blocTest<AllowCorMusicSheetsCubit, bool>(
      'emits the value it is set to',
      build: () => AllowCorMusicSheetsCubit(),
      act: (cubit) => cubit.setValue(true),
      expect: () => [true],
    );
  });

  group('AllowJubilateMusicSheetsCubit', () {
    blocTest<AllowJubilateMusicSheetsCubit, bool>(
      'emits the value it is set to',
      build: () => AllowJubilateMusicSheetsCubit(),
      act: (cubit) => cubit.setValue(true),
      expect: () => [true],
    );
  });
}
