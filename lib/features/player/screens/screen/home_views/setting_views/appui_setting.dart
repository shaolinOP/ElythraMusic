import 'package:elythra_music/core/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:elythra_music/core/model/source_engines.dart';
import 'package:elythra_music/core/repository/LastFM/lastfmapi.dart';
import 'package:elythra_music/features/player/screens/screen/chart/show_charts.dart';
import 'package:elythra_music/features/player/screens/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppUISettings extends StatefulWidget {
  const AppUISettings({super.key});

  @override
  State<AppUISettings> createState() => _AppUISettingsState();
}

class _AppUISettingsState extends State<AppUISettings> {
  List<bool> sourceEngineSwitches =
      SourceEngine.values.map((e) => true).toList();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Default_Theme.themeColor,
      appBar: AppBar(
        backgroundColor: Default_Theme.themeColor,
        foregroundColor: Default_Theme.primaryColor1,
        surfaceTintColor: Default_Theme.themeColor,
        centerTitle: true,
        title: Text(
          'UI & Services Settings',
          style: const TextStyle(
                  color: Default_Theme.primaryColor1,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)
              .merge(Default_Theme.secondoryTextStyle),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: [
              SwitchListTile(
                  value: state.autoSlideCharts,
                  subtitle: Text(
                    "Slide charts automatically in home screen.",
                    style: TextStyle(
                            color: Default_Theme.primaryColor1.withOpacity(0.5),
                            fontSize: 12)
                        .merge(Default_Theme.secondoryTextStyleMedium),
                  ),
                  title: Text(
                    "Auto slide charts",
                    style: const TextStyle(
                            color: Default_Theme.primaryColor1, fontSize: 16)
                        .merge(Default_Theme.secondoryTextStyleMedium),
                  ),
                  onChanged: (value) {
                    context.read<SettingsCubit>().setAutoSlideCharts(value);
                  }),
              SwitchListTile(
                  value: state.lFMPicks,
                  subtitle: Text(
                    "Suggestions from Last.FM will be shown in the home screen. (Login & Restart required)",
                    style: TextStyle(
                            color: Default_Theme.primaryColor1.withOpacity(0.5),
                            fontSize: 12)
                        .merge(Default_Theme.secondoryTextStyleMedium),
                  ),
                  title: Text(
                    "Last.FM Suggested Picks",
                    style: const TextStyle(
                            color: Default_Theme.primaryColor1, fontSize: 16)
                        .merge(Default_Theme.secondoryTextStyleMedium),
                  ),
                  onChanged: (value) {
                    context.read<SettingsCubit>().setLastFMExpore(value);
                    if (value && LastFmAPI.initialized == false) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        context.read<SettingsCubit>().setLastFMExpore(false);
                      });
                      SnackbarService.showMessage(
                          "Please login to Last.FM first.");
                    }
                  }),
              ExpansionTile(
                title: Text(
                  "Source Engines",
                  style: const TextStyle(
                          color: Default_Theme.primaryColor1, fontSize: 16)
                      .merge(Default_Theme.secondoryTextStyleMedium),
                ),
                subtitle: Text(
                  "Manage the source engines you want to use for Music search. (Restart required)",
                  style: TextStyle(
                          color: Default_Theme.primaryColor1.withOpacity(0.5),
                          fontSize: 12)
                      .merge(Default_Theme.secondoryTextStyleMedium),
                ),
                collapsedIconColor: Default_Theme.primaryColor1,
                children: SourceEngine.values.map((e) {
                  if (e == SourceEngine.eng_YTM) return Container();
                  return SwitchListTile(
                      value: state
                          .sourceEngineSwitches[SourceEngine.values.indexOf(e)],
                      title: Text(
                        e.value,
                        style: const TextStyle(
                                color: Default_Theme.primaryColor1,
                                fontSize: 17)
                            .merge(Default_Theme.secondoryTextStyleMedium),
                      ),
                      onChanged: (b) {
                        context.read<SettingsCubit>().setSourceEngineSwitches(
                            SourceEngine.values.indexOf(e), b);
                      });
                }).toList(),
              ),
              ExpansionTile(
                title: Text(
                  "Allowed Chart Sources",
                  style: const TextStyle(
                          color: Default_Theme.primaryColor1, fontSize: 16)
                      .merge(Default_Theme.secondoryTextStyleMedium),
                ),
                subtitle: Text(
                  "Manage the chart sources you want to see in the home screen.",
                  style: TextStyle(
                          color: Default_Theme.primaryColor1.withOpacity(0.5),
                          fontSize: 12)
                      .merge(Default_Theme.secondoryTextStyleMedium),
                ),
                collapsedIconColor: Default_Theme.primaryColor1,
                children: chartInfoList.map((e) {
                  return SwitchListTile(
                      value: state.chartMap[e.title] ?? true,
                      title: Text(
                        e.title,
                        style: const TextStyle(
                                color: Default_Theme.primaryColor1,
                                fontSize: 17)
                            .merge(Default_Theme.secondoryTextStyleMedium),
                      ),
                      onChanged: (b) {
                        context.read<SettingsCubit>().setChartShow(e.title, b);
                      });
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
