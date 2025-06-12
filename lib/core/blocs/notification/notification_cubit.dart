import 'dart:async';
import 'dart:developer';

import 'package:elythra_music/core/services/bloomee_updater_tools.dart';
import 'package:elythra_music/core/services/db/global_db.dart';
import 'package:elythra_music/core/services/db/bloomee_db_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  StreamSubscription? _subscription;
  NotificationCubit() : super(NotificationInitial()) {
    getLatestVersion().then((value) {
      if (value["results"]) {
        if (int.parse(value["currBuild"]) < int.parse(value["newBuild"])) {
          ElythraDBService.putNotification(
            title: "Update Available",
            body:
                "New Version of Elythra🌸 is now available!! Version: ${value["newVer"]} + ${value["newBuild"]}",
            type: "app_update",
            unique: true,
          );
        }
      }
    });
    getNotification();
  }
  void getNotification() async {
    List<NotificationDB> notifications =
        await ElythraDBService.getNotifications();
    emit(NotificationState(notifications: notifications));
  }

  void clearNotification() {
    ElythraDBService.clearNotifications();
    log("Notification Cleared");
    getNotification();
  }

  Future<void> watchNotification() async {
    _subscription =
        (await ElythraDBService.watchNotification()).listen((event) {
      getNotification();
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
