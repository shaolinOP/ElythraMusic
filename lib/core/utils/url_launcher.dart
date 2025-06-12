import 'dart:developer';

import 'package:url_launcher/url_launcher.dart';

Future<void> launchUrl(_url) async {
  if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
    log('Could not launch $_url', name: "launchUrl");
  }
}
