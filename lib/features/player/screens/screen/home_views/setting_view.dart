// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:elythra_music/features/player/screens/screen/home_views/setting_views/about.dart';
import 'package:elythra_music/features/player/screens/screen/home_views/setting_views/appui_setting.dart';
import 'package:elythra_music/features/player/screens/screen/home_views/setting_views/storage_setting.dart';
import 'package:elythra_music/features/player/screens/screen/home_views/setting_views/country_setting.dart';
import 'package:elythra_music/features/player/screens/screen/home_views/setting_views/download_setting.dart';
// import 'package:elythra_music/features/player/screens/screen/home_views/setting_views/lastfm_setting.dart'; // Disabled
import 'package:elythra_music/features/player/screens/screen/home_views/setting_views/player_setting.dart';
import 'package:elythra_music/features/player/screens/screen/home_views/setting_views/updates_setting.dart';
import 'package:flutter/material.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:icons_plus/icons_plus.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultTheme.themeColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: DefaultTheme.themeColor,
        surfaceTintColor: DefaultTheme.themeColor,
        foregroundColor: DefaultTheme.primaryColor1,
        title: Text(
          'Settings',
          style: const TextStyle(
                  color: DefaultTheme.primaryColor1,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)
              .merge(DefaultTheme.secondoryTextStyle),
        ),
      ),
      body: ListView(
        children: [
          settingListTile(
              title: "Updates",
              subtitle: "Check for new updates",
              icon: MingCute.download_3_fill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UpdatesSettings(),
                  ),
                );
              }),
          settingListTile(
              title: "Downloads",
              subtitle: "Download Path,Download Quality and more...",
              icon: MingCute.folder_download_fill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DownloadSettings(),
                  ),
                );
              }),
          settingListTile(
              title: "Player Settings",
              subtitle: "Stream quality, Auto Play, etc.",
              icon: MingCute.airpods_fill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlayerSettings(),
                  ),
                );
              }),
          settingListTile(
              title: "UI Elements & Services",
              subtitle: "Auto slide, Source Engines etc.",
              icon: MingCute.display_fill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppUISettings(),
                  ),
                );
              }),
          settingListTile(
              title: "Last.FM Settings",
              subtitle: "API Key, Secret, and Scrobbling settings.",
              icon: FontAwesome.lastfm_brand,
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => const LastDotFM(),
                //   ),
                // ); // LastDotFM disabled
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Last.fm integration disabled")),
                );
              }),
          settingListTile(
              title: "Storage",
              subtitle: "Backup, Cache, History, Restore and more...",
              icon: MingCute.coin_2_fill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BackupSettings(),
                  ),
                );
              }),
          settingListTile(
              title: "Language & Country",
              subtitle: "Select your language and country.",
              icon: MingCute.globe_fill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CountrySettings(),
                  ),
                );
              }),
          settingListTile(
              title: "About",
              subtitle: "About the app, version, developer, etc.",
              icon: MingCute.github_fill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const About(),
                  ),
                );
              }),
        ],
      ),
    );
  }

  ListTile settingListTile(
      {required String title,
      required String subtitle,
      required IconData icon,
      VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(
        icon,
        size: 27,
        color: DefaultTheme.primaryColor1,
      ),
      title: Text(
        title,
        style: const TextStyle(color: DefaultTheme.primaryColor1, fontSize: 16)
            .merge(DefaultTheme.secondoryTextStyleMedium),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
                color: DefaultTheme.primaryColor1.withOpacity(0.5),
                fontSize: 12)
            .merge(DefaultTheme.secondoryTextStyleMedium),
      ),
      onTap: () {
        if (onTap != null) {
          onTap();
        }
      },
    );
  }
}
