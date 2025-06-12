import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:icons_plus/icons_plus.dart';
// import 'package:elythra_music/features/player/screens/widgets/mini_player_widget.dart'; // Disabled
import 'package:responsive_framework/responsive_framework.dart';
import '../../theme_data/default.dart';

class GlobalFooter extends StatelessWidget {
  const GlobalFooter({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        body: ResponsiveBreakpoints.of(context).isMobile
            ? navigationShell
            : Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: VerticalNavBar(navigationShell: navigationShell),
                  ),
                  Expanded(child: navigationShell),
                ],
              ),
        backgroundColor: DefaultTheme.themeColor,
        drawerScrimColor: DefaultTheme.themeColor,
        bottomNavigationBar: SafeArea(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(), // MiniPlayerWidget disabled
            Container(
              color: Colors.transparent,
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: ResponsiveBreakpoints.of(context).isMobile
                  ? HorizontalNavBar(navigationShell: navigationShell)
                  : const Wrap(),
            ),
          ],
        )),
      ),
    );
  }
}

class VerticalNavBar extends StatelessWidget {
  const VerticalNavBar({
    super.key,
    required this.navigationShell,
  });
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      backgroundColor: DefaultTheme.themeColor.withOpacity(0.3),
      destinations: const [
        NavigationRailDestination(
            icon: Icon(MingCute.home_4_fill), label: Text('Home')),
        NavigationRailDestination(
            icon: Icon(MingCute.book_5_fill), label: Text('Library')),
        NavigationRailDestination(
            icon: Icon(MingCute.search_2_fill), label: Text('Search')),
        NavigationRailDestination(
            icon: Icon(MingCute.folder_download_fill), label: Text('Offline')),
      ],
      selectedIndex: navigationShell.currentIndex,
      minWidth: 65,

      onDestinationSelected: (value) {
        navigationShell.goBranch(value);
      },
      groupAlignment: 0.0,
      // selectedIconTheme: IconThemeData(color: DefaultTheme.accentColor2),
      unselectedIconTheme:
          const IconThemeData(color: DefaultTheme.primaryColor2),
      indicatorColor: DefaultTheme.accentColor2,
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
    );
  }
}

class HorizontalNavBar extends StatelessWidget {
  const HorizontalNavBar({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return GNav(
      gap: 7.0,
      tabBackgroundColor: DefaultTheme.accentColor2.withOpacity(0.22),
      color: DefaultTheme.primaryColor2,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      activeColor: DefaultTheme.accentColor2,
      textStyle: DefaultTheme.secondoryTextStyleMedium.merge(
          const TextStyle(color: DefaultTheme.accentColor2, fontSize: 18)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      backgroundColor: DefaultTheme.themeColor.withOpacity(0.3),
      tabs: const [
        // GButton(
        //   icon: MingCute.home_4_fill,
        //   iconSize: 27,
        //   text: "Test",
        // ),
        GButton(
          icon: MingCute.home_4_fill,
          text: "Home",
        ),
        GButton(
          icon: MingCute.book_5_fill,
          text: "Library",
        ),
        GButton(
          icon: MingCute.search_2_fill,
          text: "Search",
        ),
        GButton(
          icon: MingCute.folder_download_fill,
          text: "Offline",
        ),
      ],
      selectedIndex: navigationShell.currentIndex,
      onTabChange: (value) {
        navigationShell.goBranch(value);
      },
    );
  }
}
