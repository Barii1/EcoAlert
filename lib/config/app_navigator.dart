import 'package:flutter/material.dart';

/// Global navigator key so push handlers (FCM, local notifications) can route
/// without a [BuildContext].
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
