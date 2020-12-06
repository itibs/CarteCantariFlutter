import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/helpers.dart';
import 'package:ccc_flutter/services/pitch_sound_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class KeySignature extends StatefulWidget {
  final String pitch;

  KeySignature({this.pitch});

  @override
  KeySignatureState createState() => KeySignatureState();
}

class KeySignatureState extends State<KeySignature>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  FToast _fToast;

  @override
  void initState() {
    super.initState();

    _fToast = FToast();
    _fToast.init(context);

    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 4));
    _animationController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    var strPitch = widget.pitch;
    var pitchSize = 22.0;
    if (strPitch.contains("b")) {
      pitchSize -= 2;
    }
    if (strPitch.contains("#")) {
      pitchSize -= 3;
    }
    if (strPitch.endsWith("m")) {
      pitchSize -= 3;
    }

    final pitchSoundService = context.watch<PitchSoundService>();

    return GestureDetector(
      onTapDown: (_) {
        showToast("Ține apăsat pentru a auzi tonalitatea", _fToast);
        _animationController.forward();
        pitchSoundService.playChord(widget.pitch);
      },
      onTapUp: (tapUpDetails) {
        _animationController.reset();
        pitchSoundService.stopChord(widget.pitch);
      },
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CircularProgressIndicator(
            value: 1.0,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
          CircularProgressIndicator(
            value: _animationController.value,
            valueColor: AlwaysStoppedAnimation<Color>(COLOR_DARKER_BLUE),
          ),
          Text(strPitch,
              style:
                  TextStyle(fontSize: pitchSize, fontWeight: FontWeight.bold))
        ],
      ),
    );
  }
}
