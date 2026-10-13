import 'package:flutter/foundation.dart';

/// `true` na iOS/macOS. Komponenty `App*` przełączają na tej podstawie
/// zachowanie (feedback dotyku, kontrolki), nie wygląd — design jest wspólny.
bool get isApplePlatform =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;
