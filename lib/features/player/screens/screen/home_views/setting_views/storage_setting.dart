import 'dart:io';

import 'package:elythra_music/core/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:elythra_music/features/player/screens/widgets/setting_tile.dart';
import 'package:elythra_music/features/player/screens/widgets/snackbar.dart';
import 'package:elythra_music/core/services/db/bloomee_db_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class BackupSettings extends StatelessWidget {
  const BackupSettings({super.key});

  Future<bool> storagePermission() async {
    final DeviceInfoPlugin info =
        DeviceInfoPlugin(); // import 'package:device_info_plus/device_info_plus.dart';
    final AndroidDeviceInfo androidInfo = await info.androidInfo;
    debugPrint('releaseVersion : ${androidInfo.version.release}');
    final int androidVersion = int.parse(androidInfo.version.release);
    bool havePermission = false;

    if (androidVersion >= 13) {
      final request = await [
        Permission.videos,
        Permission.photos,
        //..... as needed
      ].request(); //import 'package:permission_handler/permission_handler.dart';

      havePermission =
          request.toARGB32s.every((status) => status == PermissionStatus.granted);
    } else {
      final status = await Permission.storage.request();
      havePermission = status.isGranted;
    }

    if (!havePermission) {
      // if no permission then open app-setting
      await openAppSettings();
    }

    return havePermission;
  }

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
          'Storage',
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
                title: "Clear History In Every",
                subtitle: "Clear history after every specified Time.",
                trailing: DropdownButton(
                  value: state.historyClearTime,
                  style: const TextStyle(
                    color: DefaultTheme.primaryColor1,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ).merge(DefaultTheme.secondoryTextStyle),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      context
                          .read<SettingsCubit>()
                          .setHistoryClearTime(newValue);
                    }
                  },
                  items: <String>[
                    '3',
                    '7',
                    '14',
                    '30',
                    '60',
                    '90',
                    '180',
                    '365'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        '$value Days',
                      ),
                    );
                  }).toList(),
                ),
                onTap: () {},
              ),
              SettingTile(
                title: "Backup location",
                subtitle: state.backupPath,
                onTap: () async {
                  /*final hasStorageAccess = Platform.isAndroid
                      ? await Permission.storage.isGranted
                      : true;
                  if (!hasStorageAccess) {
@@ -86,7 +117,9 @@ class BackupSettings extends StatelessWidget {
                      SnackbarService.showMessage("Storage permission denied!");
                      return;
                    }
                  }
                  }*/
                  if (Platform.isAndroid) {
                    final permission = await storagePermission();
                    debugPrint('permission : $permission');
                  }
                  FilePicker.platform.getDirectoryPath().then((value) {
                    if (value != null) {
                      context.read<SettingsCubit>().setBackupPath(value);
                    }
                  });
                },
              ),
              SettingTile(
                title: "Create Backup",
                subtitle:
                    "Create a backup of your data and settings in a backup location.",
                onTap: () {
                  ElythraDBService.createBackUp().then((value) {
                    if (value) {
                      SnackbarService.showMessage("Backup Succes!");
                    } else {
                      SnackbarService.showMessage("Backup Failed!");
                    }
                  });
                },
              ),
              SettingTile(
                title: "Restore Backup",
                subtitle:
                    "Restore your data and settings from a backup location.",
                onTap: () {
                  ElythraDBService.backupExists().then((value) {
                    if (value) {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor:
                                  const Color.fromARGB(255, 24, 24, 24),
                              surfaceTintColor:
                                  const Color.fromARGB(255, 24, 24, 24),
                              actions: [
                                TextButton(
                                  child: Text(
                                    "Yes",
                                    style: DefaultTheme.secondoryTextStyle
                                        .merge(const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  onPressed: () {
                                    context.pop();
                                    ElythraDBService.restoreDB().then((value) {
                                      if (value) {
                                        SnackbarService.showMessage(
                                            "Restore Success.");
                                      } else {
                                        SnackbarService.showMessage(
                                            "Restore failed");
                                      }
                                    });
                                  },
                                ),
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            DefaultTheme.accentColor2),
                                    onPressed: () {
                                      context.pop();
                                    },
                                    child: Text(
                                      "No",
                                      style: DefaultTheme.secondoryTextStyle
                                          .merge(const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                    ))
                              ],
                              content: Wrap(
                                children: [
                                  Center(
                                    child: Text(
                                      "Your current data will be removed while importing all previous data from backup file.\nDo you want to proceed?",
                                      textAlign: TextAlign.left,
                                      style: DefaultTheme.secondoryTextStyle
                                          .merge(
                                        const TextStyle(
                                            color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          });
                    } else {
                      SnackbarService.showMessage(
                          "No backup exists. Create backup first.");
                    }
                  });
                },
              ),
              SwitchListTile(
                title: Text("Auto Backup",
                    style: const TextStyle(
                            color: DefaultTheme.primaryColor1, fontSize: 16)
                        .merge(DefaultTheme.secondoryTextStyleMedium)),
                subtitle: Text(
                    "Automatically create a backup of your data on regular basis.",
                    style: TextStyle(
                            color: DefaultTheme.primaryColor1.withValues(alpha: 0.5),
                            fontSize: 12)
                        .merge(DefaultTheme.secondoryTextStyleMedium)),
                value: state.autoBackup,
                onChanged: (value) {
                  context.read<SettingsCubit>().setAutoBackup(value);
                },
              ),
              SwitchListTile(
                  title: Text("Auto Save Lyrics",
                      style: const TextStyle(
                              color: DefaultTheme.primaryColor1, fontSize: 16)
                          .merge(DefaultTheme.secondoryTextStyleMedium)),
                  subtitle: Text(
                      "Automatically save lyrics of the song when played.",
                      style: TextStyle(
                              color:
                                  DefaultTheme.primaryColor1.withValues(alpha: 0.5),
                              fontSize: 12)
                          .merge(DefaultTheme.secondoryTextStyleMedium)),
                  value: state.autoSaveLyrics,
                  onChanged: (value) {
                    context.read<SettingsCubit>().setAutoSaveLyrics(value);
                  }),
            ],
          );
        },
      ),
    );
  }
}
