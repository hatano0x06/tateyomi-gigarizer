// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:validators/validators.dart' as validator;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:visibility_detector/visibility_detector.dart';

List<_KeyBoardShortcuts> _keyBoardShortcuts = [];

class KeyBoardShortcuts extends StatefulWidget {
  final Widget child;

  /// You can use shortCut function with BasicShortCuts to avoid write data by yourself
  final List<Set<LogicalKeyboardKey>> keysToPressList;

  /// Function when keys are pressed
  final Function(int shortCutIndex) onKeysPressed;

  const KeyBoardShortcuts({
    required this.keysToPressList, 
    required this.onKeysPressed, 
    required this.child, 
    Key? key
  }) : super(key: key);

  @override
  _KeyBoardShortcuts createState() => _KeyBoardShortcuts();
}

class _KeyBoardShortcuts extends State<KeyBoardShortcuts> {
  final ScrollController _controller = ScrollController();
  bool controllerIsReady = false;
  bool listening = false;
  late Key key;
  
  @override
  void initState() {
    if( kIsWeb ){
      _controller.addListener(() {
        if (_controller.hasClients) setState(() => controllerIsReady = true);
      });
      _attachKeyboardIfDetached();
      key = widget.key ?? UniqueKey();
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _detachKeyboardIfAttached();
  }

  void _attachKeyboardIfDetached() {
    if (listening) return;
    _keyBoardShortcuts.add(this);
    RawKeyboard.instance.addListener(listener);
    listening = true;
  }

  void _detachKeyboardIfAttached() {
    if (!listening) return;
    _keyBoardShortcuts.remove(this);
    RawKeyboard.instance.removeListener(listener);
    listening = false;
  }

  bool _pressedKey(Set<LogicalKeyboardKey> userKeysPressed, Set<LogicalKeyboardKey> commandKeysToPress) {
    if( userKeysPressed.length != commandKeysToPress.length) return false;

    List<LogicalKeyboardKey> _tempCommandKeysPressed = commandKeysToPress.toList();
    for (LogicalKeyboardKey _pressedKey in userKeysPressed) {
      _tempCommandKeysPressed.removeWhere((_matchKey) => _matchKey.keyLabel == _pressedKey.keyLabel);
    }


    return _tempCommandKeysPressed.isEmpty;
  }

  void listener(RawKeyEvent v) async {
    if (!mounted) return;

    Set<LogicalKeyboardKey> userKeysPressed = RawKeyboard.instance.keysPressed;
    if (v.runtimeType == RawKeyDownEvent) {
      // when user type keysToPress

      widget.keysToPressList.asMap().forEach((_keysToPressIndex, _commandKeysToPress) {
        bool _isPressed = _pressedKey(userKeysPressed, _commandKeysToPress);
        if( _isPressed ) widget.onKeysPressed(_keysToPressIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if( !kIsWeb ) return widget.child;
    
    return VisibilityDetector(
      key: key,
      child: PrimaryScrollController(controller: _controller, child: widget.child),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction == 1){
          _attachKeyboardIfDetached();
          return;
        }
        _detachKeyboardIfAttached();
      },
    );
  }
}


String? posStringValidate(String posString){
  if(posString.isEmpty) return "数字を入力してください";
  if(posString == "-") return "数字を入力してください";

  if( !validator.isFloat(posString) ) return "有効な形になっていません";
  if( !validator.isFloat(posString) ) return "有効な形になっていません";

  return null;
}

String? rateStringValidate(String posString){
  if(posString.isEmpty) return "数字を入力してください";

  if( !validator.isFloat(posString) ) return "有効な形になっていません";
  if( !validator.isFloat(posString) ) return "有効な形になっていません";

  return null;
}
