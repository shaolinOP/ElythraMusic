import 'package:elythra_music/features/player/screens/widgets/sign_board_widget.dart';
import 'package:flutter/material.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:icons_plus/icons_plus.dart';

class DownloadsView extends StatelessWidget {
  const DownloadsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultTheme.themeColor,
      appBar: AppBar(
        backgroundColor: DefaultTheme.themeColor,
        foregroundColor: DefaultTheme.primaryColor1,
        surfaceTintColor: DefaultTheme.themeColor,
        centerTitle: true,
        title: Text(
          'Downloads',
          style: const TextStyle(
                  color: DefaultTheme.primaryColor1,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)
              .merge(DefaultTheme.secondoryTextStyle),
        ),
      ),
      body: const Center(
        child: SignBoardWidget(
            message: "No Downloads Yet", icon: MingCute.download_2_fill),
      ),
    );
  }
}
