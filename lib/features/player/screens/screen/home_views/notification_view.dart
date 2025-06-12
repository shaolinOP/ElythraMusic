import 'package:elythra_music/core/blocs/notification/notification_cubit.dart';
import 'package:elythra_music/features/player/screens/widgets/sign_board_widget.dart';
import 'package:flutter/material.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';

import 'notification_views/notification_tile.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<NotificationCubit>().clearNotification();
        }
      },
      child: Scaffold(
        backgroundColor: DefaultTheme.themeColor,
        appBar: AppBar(
          backgroundColor: DefaultTheme.themeColor,
          foregroundColor: DefaultTheme.primaryColor1,
          surfaceTintColor: DefaultTheme.themeColor,
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                context.read<NotificationCubit>().clearNotification();
              },
              icon: const Icon(
                MingCute.broom_fill,
                color: DefaultTheme.primaryColor1,
              ),
            ),
          ],
          title: Text(
            'Notifications',
            style: const TextStyle(
                    color: DefaultTheme.primaryColor1,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)
                .merge(DefaultTheme.secondoryTextStyle),
          ),
        ),
        body: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            if (state is NotificationInitial || state.notifications.isEmpty) {
              return const Center(
                child: SignBoardWidget(
                    message: "No Notifications yet!",
                    icon: MingCute.notification_off_line),
              );
            }
            return ListView.builder(
              itemCount: state.notifications.length,
              itemBuilder: (context, index) {
                return NotificationTile(
                  notification: state.notifications[index],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
