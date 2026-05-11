import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

Route<T> appRoute<T>(WidgetBuilder builder) =>
    defaultTargetPlatform == TargetPlatform.iOS
        ? CupertinoPageRoute<T>(builder: builder)
        : MaterialPageRoute<T>(builder: builder);
