import 'dart:developer';

import 'package:url_launcher/url_launcher.dart';

Future<void> launchUrlExternal(String _url) async {
  final uri = Uri.parse(_url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    log('Could not launch $_url', name: "launchUrl");
  }
}
