import 'dart:html' as html;

bool get browserIsOnline => html.window.navigator.onLine ?? true;
