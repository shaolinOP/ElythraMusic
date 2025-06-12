import 'package:elythra_music/core/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:elythra_music/features/player/screens/screen/home_views/setting_views/check_update_view.dart';
import 'package:elythra_music/features/player/screens/widgets/setting_tile.dart';
import 'package:flutter/material.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpdatesSettings extends StatelessWidget {
  const UpdatesSettings({super.key});

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
          'Updates',
          style: const TextStyle(
                  color: DefaultTheme.primaryColor1,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)
              .merge(DefaultTheme.secondoryTextStyle),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: [
              SettingTile(
                title: "Check for updates",
                subtitle: "Check for new updates",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CheckUpdateView(),
                    ),
                  );
                },
              ),
              SwitchListTile(
                  value: state.autoUpdateNotify,
                  subtitle: Text(
                    "Get notified when new updates are available in app start up.",
                    style: TextStyle(
                            color: DefaultTheme.primaryColor1.withValues(alpha: 0.5),
                            fontSize: 12.5)
                        .merge(DefaultTheme.secondoryTextStyleMedium),
                  ),
                  title: Text(
                    "Auto update notify",
                    style: const TextStyle(
                            color: DefaultTheme.primaryColor1, fontSize: 17)
                        .merge(DefaultTheme.secondoryTextStyleMedium),
                  ),
                  onChanged: (value) {
                    context.read<SettingsCubit>().setAutoUpdateNotify(value);
                  }),
            ],
          );
        },
      ),
    );
  }
}
