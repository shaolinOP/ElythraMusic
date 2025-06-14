// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:elythra_music/core/model/chart_model.dart';
import 'package:elythra_music/core/services/db/bloomee_db_service.dart';
import 'package:elythra_music/core/utils/imgurl_formator.dart';
import 'package:elythra_music/core/utils/load_image.dart';
import 'package:elythra_music/core/utils/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:elythra_music/features/player/screens/widgets/chart_list_tile.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:icons_plus/icons_plus.dart';

class ChartScreen extends StatefulWidget {
  final String chartName;
  const ChartScreen({Key? key, required this.chartName}) : super(key: key);

  @override
  State<ChartScreen> createState() => ChartScreenStateState();
}

class ChartScreenStateState extends State<ChartScreen> {
  Future<ChartModel?> chartModel = Future.value(null);
  Future<ChartModel?> getChart() async {
    return await ElythraDBService.getChart(widget.chartName);
  }

  @override
  void initState() {
    setState(() {
      chartModel = getChart();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: FutureBuilder(
          future: chartModel,
          builder: (context, state) {
            if (state.connectionState == ConnectionState.waiting ||
                state.data == null) {
              return const Center(
                child: SizedBox(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(
                      color: DefaultTheme.accentColor2,
                    )),
              );
            } else if (state.data!.chartItems!.isEmpty) {
              return Center(
                child: Text("Error: No Item in Chart",
                    style: DefaultTheme.secondoryTextStyleMedium.merge(
                        const TextStyle(
                            fontSize: 24,
                            color: Color.fromARGB(255, 255, 235, 251)))),
              );
            } else {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  customDiscoverBar(context, state.data!), //AppBar
                  SliverList(
                      delegate: SliverChildListDelegate([
                    ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(
                        top: 5,
                      ),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.data!.chartItems!.length,
                      itemBuilder: (context, index) {
                        return ChartListTile(
                          title: state.data!.chartItems![index].name!,
                          subtitle: state.data!.chartItems![index].subtitle!,
                          imgUrl: state.data!.chartItems![index].imageUrl!,
                        );
                      },
                    ),
                  ]))
                ],
              );
            }
          },
        ),
        backgroundColor: DefaultTheme.themeColor,
      ),
    );
  }

  SliverAppBar customDiscoverBar(BuildContext context, ChartModel state) {
    return SliverAppBar(
      floating: true,
      surfaceTintColor: DefaultTheme.themeColor,
      backgroundColor: DefaultTheme.themeColor,
      expandedHeight: 200,
      actions: [
        Padding(
          padding: const EdgeInsets.only(
            right: 10,
          ),
          child: IconButton(
            icon: const Icon(MingCute.external_link_line),
            onPressed: () {
              state.url != null ? launchUrlExternal(state.url!) : null;
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding:
            const EdgeInsets.only(left: 8, bottom: 0, right: 0, top: 0),
        title: Text(state.chartName,
            textScaler: const TextScaler.linear(1.0),
            textAlign: TextAlign.start,
            style: DefaultTheme.secondoryTextStyleMedium.merge(const TextStyle(
                fontSize: 24, color: Color.fromARGB(255, 255, 235, 251)))),
        background: Stack(
          children: [
            LayoutBuilder(builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                child: LoadImageCached(
                  imageUrl: formatImgURL(
                      state.chartItems!.first.imageUrl.toString(),
                      ImageQuality.high),
                  fit: BoxFit.cover,
                ),
              );
            }),
            Positioned.fill(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                  DefaultTheme.themeColor.withOpacity(0.8),
                  DefaultTheme.themeColor.withOpacity(0.4),
                  DefaultTheme.themeColor.withOpacity(0.1),
                  DefaultTheme.themeColor.withOpacity(0),
                ]))))
          ],
        ),
      ),
    );
  }
}
