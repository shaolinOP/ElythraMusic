// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:elythra_music/core/theme_data/default.dart';
import 'package:flutter/material.dart';

class SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Function onTap;
  final Widget? trailing;

  const SettingTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: DefaultTheme.primaryColor1, fontSize: 16)
            .merge(DefaultTheme.secondoryTextStyleMedium),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
                color: DefaultTheme.primaryColor1.withValues(alpha: 0.5),
                fontSize: 12)
            .merge(DefaultTheme.secondoryTextStyleMedium),
      ),
      onTap: () {
        onTap();
      },
      dense: true,
      trailing: trailing,
    );
  }
}
