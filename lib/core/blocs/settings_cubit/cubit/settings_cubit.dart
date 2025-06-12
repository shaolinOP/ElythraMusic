import 'dart:convert';
import 'dart:developer';
import 'package:elythra_music/core/model/source_engines.dart';
import 'package:elythra_music/core/routes_and_consts/global_str_consts.dart';
import 'package:elythra_music/core/services/db/bloomee_db_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsInitial()) {
    initSettings();
    autoUpdate();
  }

// Initialize the settings from the database
  void initSettings() {
    ElythraDBService.getSettingBool(GlobalStrConsts.autoUpdateNotify)
        .then((value) {
      emit(state.copyWith(autoUpdateNotify: value ?? false));
    });

    ElythraDBService.getSettingBool(GlobalStrConsts.autoSlideCharts)
        .then((value) {
      emit(state.copyWith(autoSlideCharts: value ?? true));
    });

    // Directory dir = Directory('/storage/emulated/0/Music');
    String? path;

    ElythraDBService.getSettingStr(GlobalStrConsts.downPathSetting)
        .then((value) async {
      await getDownloadsDirectory().then((value) {
        if (value != null) {
          path = value.path;
        }
      });
      emit(state.copyWith(
          downPath: (value ?? path) ??
              (await getApplicationDocumentsDirectory()).path));
    });

    ElythraDBService.getSettingStr(GlobalStrConsts.downQuality,
            defaultValue: '320 kbps')
        .then((value) {
      emit(state.copyWith(downQuality: value ?? "320 kbps"));
    });

    ElythraDBService.getSettingStr(GlobalStrConsts.ytDownQuality).then((value) {
      emit(state.copyWith(ytDownQuality: value ?? "High"));
    });

    ElythraDBService.getSettingStr(
      GlobalStrConsts.strmQuality,
    ).then((value) {
      emit(state.copyWith(strmQuality: value ?? "96 kbps"));
    });

    ElythraDBService.getSettingStr(GlobalStrConsts.ytStrmQuality).then((value) {
      if (value == "High" || value == "Low") {
        emit(state.copyWith(ytStrmQuality: value ?? "Low"));
      } else {
        ElythraDBService.putSettingStr(GlobalStrConsts.ytStrmQuality, "Low");
        emit(state.copyWith(ytStrmQuality: "Low"));
      }
    });

    ElythraDBService.getSettingStr(GlobalStrConsts.historyClearTime)
        .then((value) {
      emit(state.copyWith(historyClearTime: value ?? "30"));
    });

    ElythraDBService.getSettingBool(GlobalStrConsts.lFMScrobbleSetting)
        .then((value) {
      emit(state.copyWith(lastFMScrobble: value ?? false));
    });

    ElythraDBService.getSettingBool(
      GlobalStrConsts.autoPlay,
    ).then((value) {
      emit(state.copyWith(autoPlay: value ?? true));
    });

    ElythraDBService.getSettingBool(GlobalStrConsts.lFMUIPicks).then((value) {
      emit(state.copyWith(lFMPicks: value ?? false));
    });

    ElythraDBService.getSettingStr(GlobalStrConsts.backupPath)
        .then((value) async {
      if (value == null || value == "") {
        await ElythraDBService.putSettingStr(GlobalStrConsts.backupPath,
            (await getApplicationDocumentsDirectory()).path);
        emit(state.copyWith(
            backupPath: (await getApplicationDocumentsDirectory()).path));
      } else {
        emit(state.copyWith(backupPath: value));
      }
    });

    ElythraDBService.getSettingBool(GlobalStrConsts.autoBackup).then((value) {
      emit(state.copyWith(autoBackup: value ?? false));
    });

    ElythraDBService.getSettingBool(GlobalStrConsts.autoGetCountry)
        .then((value) {
      emit(state.copyWith(autoGetCountry: value ?? false));
    });

    ElythraDBService.getSettingStr(GlobalStrConsts.countryCode).then((value) {
      emit(state.copyWith(countryCode: value ?? "IN"));
    });

    ElythraDBService.getSettingBool(GlobalStrConsts.autoSaveLyrics)
        .then((value) {
      emit(state.copyWith(autoSaveLyrics: value ?? false));
    });

    for (var eg in SourceEngine.toARGB32s) {
      ElythraDBService.getSettingBool(eg.toARGB32).then((value) {
        List<bool> switches = List.from(state.sourceEngineSwitches);
        switches[SourceEngine.toARGB32s.indexOf(eg)] = value ?? true;
        emit(state.copyWith(sourceEngineSwitches: switches));
        log(switches.toString(), name: 'SettingsCubit');
      });
    }

    Map chartMap = Map.from(state.chartMap);
    ElythraDBService.getSettingStr(GlobalStrConsts.chartShowMap).then((value) {
      if (value != null) {
        chartMap = jsonDecode(value);
      }
      emit(state.copyWith(chartMap: Map.from(chartMap)));
    });
  }

  void setChartShow(String title, bool value) {
    Map chartMap = Map.from(state.chartMap);
    chartMap[title] = value;
    ElythraDBService.putSettingStr(
        GlobalStrConsts.chartShowMap, jsonEncode(chartMap));
    emit(state.copyWith(chartMap: Map.from(chartMap)));
  }

  Future<void> setAutoPlay(bool value) async {
    await ElythraDBService.putSettingBool(GlobalStrConsts.autoPlay, value);
    emit(state.copyWith(autoPlay: value));
  }

  void autoUpdate() {
    ElythraDBService.getSettingBool(GlobalStrConsts.autoBackup).then((value) {
      if (value != null || value == true) {
        ElythraDBService.createBackUp();
      }
    });
  }

  void setCountryCode(String value) {
    ElythraDBService.putSettingStr(GlobalStrConsts.countryCode, value);
    emit(state.copyWith(countryCode: value));
  }

  void setAutoSaveLyrics(bool value) {
    ElythraDBService.putSettingBool(GlobalStrConsts.autoSaveLyrics, value);
    emit(state.copyWith(autoSaveLyrics: value));
  }

  void setLastFMScrobble(bool value) {
    ElythraDBService.putSettingBool(GlobalStrConsts.lFMScrobbleSetting, value);
    emit(state.copyWith(lastFMScrobble: value));
  }

  void setLastFMExpore(bool value) {
    ElythraDBService.putSettingBool(GlobalStrConsts.lFMUIPicks, value);
    emit(state.copyWith(lFMPicks: value));
  }

  void setAutoGetCountry(bool value) {
    ElythraDBService.putSettingBool(GlobalStrConsts.autoGetCountry, value);
    emit(state.copyWith(autoGetCountry: value));
  }

  void setAutoUpdateNotify(bool value) {
    ElythraDBService.putSettingBool(GlobalStrConsts.autoUpdateNotify, value);
    emit(state.copyWith(autoUpdateNotify: value));
  }

  void setAutoSlideCharts(bool value) {
    ElythraDBService.putSettingBool(GlobalStrConsts.autoSlideCharts, value);
    emit(state.copyWith(autoSlideCharts: value));
  }

  void setDownPath(String value) {
    ElythraDBService.putSettingStr(GlobalStrConsts.downPathSetting, value);
    emit(state.copyWith(downPath: value));
  }

  void setDownQuality(String value) {
    ElythraDBService.putSettingStr(GlobalStrConsts.downQuality, value);
    emit(state.copyWith(downQuality: value));
  }

  void setYtDownQuality(String value) {
    ElythraDBService.putSettingStr(GlobalStrConsts.ytDownQuality, value);
    emit(state.copyWith(ytDownQuality: value));
  }

  void setStrmQuality(String value) {
    ElythraDBService.putSettingStr(GlobalStrConsts.strmQuality, value);
    emit(state.copyWith(strmQuality: value));
  }

  void setYtStrmQuality(String value) {
    ElythraDBService.putSettingStr(GlobalStrConsts.ytStrmQuality, value);
    emit(state.copyWith(ytStrmQuality: value));
  }

  void setBackupPath(String value) {
    ElythraDBService.putSettingStr(GlobalStrConsts.backupPath, value);
    emit(state.copyWith(backupPath: value));
  }

  void setAutoBackup(bool value) {
    ElythraDBService.putSettingBool(GlobalStrConsts.autoBackup, value);
    emit(state.copyWith(autoBackup: value));
  }

  void setHistoryClearTime(String value) {
    ElythraDBService.putSettingStr(GlobalStrConsts.historyClearTime, value);
    emit(state.copyWith(historyClearTime: value));
  }

  void setSourceEngineSwitches(int index, bool value) {
    List<bool> switches = List.from(state.sourceEngineSwitches);
    switches[index] = value;
    ElythraDBService.putSettingBool(SourceEngine.toARGB32s[index].toARGB32, value);
    emit(state.copyWith(sourceEngineSwitches: List.from(switches)));
  }

  Future<void> resetDownPath() async {
    String? path;

    await getDownloadsDirectory().then((value) {
      if (value != null) {
        path = value.path;
        log(path.toString(), name: 'SettingsCubit');
      }
    });

    if (path != null) {
      ElythraDBService.putSettingStr(GlobalStrConsts.downPathSetting, path!);
      emit(state.copyWith(downPath: path));
      log(path.toString(), name: 'SettingsCubit');
    } else {
      log("Path is null", name: 'SettingsCubit');
    }
  }
}
