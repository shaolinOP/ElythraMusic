import 'package:elythra_music/core/services/bloomee_updater_tools.dart';
import 'package:flutter/material.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:elythra_music/core/utils/url_launcher.dart';
import 'package:icons_plus/icons_plus.dart';

class CheckUpdateView extends StatelessWidget {
  const CheckUpdateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultTheme.themeColor,
      appBar: AppBar(
        backgroundColor: DefaultTheme.themeColor,
        foregroundColor: DefaultTheme.primaryColor1,
        centerTitle: true,
        title: Text(
          'Check for Updates',
          style: const TextStyle(
                  color: DefaultTheme.primaryColor1,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)
              .merge(DefaultTheme.secondoryTextStyle),
        ),
      ),
      body: Center(
        child: FutureBuilder(
          future: getLatestVersion(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (!snapshot.data?["results"]) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Text(
                      'Elythra🌸 is up-to-date!!!',
                      style: const TextStyle(
                              color: DefaultTheme.accentColor2, fontSize: 20)
                          .merge(DefaultTheme.secondoryTextStyleMedium),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: FilledButton(
                        onPressed: () {
                          launchUrl(Uri.parse(
                              "https://github.com/HemantKArya/ElythraTunes/releases"));
                        },
                        child: SizedBox(
                          // width: 150,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                FontAwesome.github_alt_brand,
                                size: 25,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: Text(
                                  "View Latest Pre-Release",
                                  style: const TextStyle(fontSize: 17).merge(
                                      DefaultTheme.secondoryTextStyleMedium),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        'Current Version: ${snapshot.data?["currVer"]} + ${snapshot.data?["currBuild"]}',
                        style: TextStyle(
                                color: DefaultTheme.primaryColor2
                                    .withValues(alpha: 0.5),
                                fontSize: 12)
                            .merge(DefaultTheme.tertiaryTextStyle),
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Text(
                      'New Version of Elythra🌸 is now available!!',
                      style: const TextStyle(
                              color: DefaultTheme.accentColor2, fontSize: 20)
                          .merge(DefaultTheme.tertiaryTextStyle),
                      textAlign: TextAlign.center,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Version: ${snapshot.data?["newVer"]}+ ${snapshot.data?["newBuild"]}',
                        style: TextStyle(
                                color: DefaultTheme.primaryColor1
                                    .withValues(alpha: 0.8),
                                fontSize: 16)
                            .merge(DefaultTheme.tertiaryTextStyle),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FilledButton(
                        onPressed: () {
                          launchUrl(Uri.parse(snapshot.data?["download_url"]));
                        },
                        child: SizedBox(
                          width: 150,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.open_in_browser_rounded,
                                  size: 25),
                              Text(
                                "Download Now",
                                style: const TextStyle(fontSize: 17).merge(
                                    DefaultTheme.secondoryTextStyleMedium),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        'Current Version: ${snapshot.data?["currVer"]} + ${snapshot.data?["currBuild"]}',
                        style: TextStyle(
                                color: DefaultTheme.primaryColor2
                                    .withValues(alpha: 0.5),
                                fontSize: 12)
                            .merge(DefaultTheme.tertiaryTextStyle),
                      ),
                    ),
                  ],
                );
              }
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: SizedBox(
                        height: 50,
                        width: 50,
                        child: CircularProgressIndicator(
                          color: DefaultTheme.accentColor2,
                        )),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        width: constraints.maxWidth * 0.6,
                        child: Text(
                            'Checking if newer version are availible or not!',
                            style: const TextStyle(
                                    color: DefaultTheme.accentColor2,
                                    fontSize: 20)
                                .merge(DefaultTheme.tertiaryTextStyle),
                            textAlign: TextAlign.center),
                      );
                    },
                  )
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
