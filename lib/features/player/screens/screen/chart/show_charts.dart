import 'package:elythra_music/plugins/ext_charts/billboard_charts.dart';
import 'package:elythra_music/plugins/ext_charts/chart_defines.dart';
import 'package:elythra_music/plugins/ext_charts/last_dot_fm_charts.dart';
import 'package:elythra_music/plugins/ext_charts/melon_charts.dart';
import 'package:elythra_music/plugins/ext_charts/spotify_top50_chart.dart';

final List<ChartInfo> chartInfoList = [
  ChartInfo(
    chartFunction: getSpotifyTop50Chart,
    imgUrl: spotifyRandomIMGs.getImage(),
    title: SpotifyCharts.top50.title,
    url: SpotifyCharts.top50,
  ),
  ChartInfo(
    chartFunction: getLastFmCharts,
    imgUrl: lastfmRandomIMGs.getImage(),
    title: LastFMCharts.TOP_TRACKS.title,
    url: LastFMCharts.TOP_TRACKS,
  ),
  ChartInfo(
    chartFunction: getMelonChart,
    imgUrl: melonRandomIMGs.getImage(),
    title: MelonCharts.domesticDaily.title,
    url: MelonCharts.domesticDaily,
  ),
  ChartInfo(
    chartFunction: getMelonChart,
    imgUrl: melonRandomIMGs.getImage(),
    title: MelonCharts.domesticWeekly.title,
    url: MelonCharts.domesticWeekly,
  ),
  ChartInfo(
    chartFunction: getMelonChart,
    imgUrl: melonRandomIMGs.getImage(),
    title: MelonCharts.domesticMonthly.title,
    url: MelonCharts.domesticMonthly,
  ),
  // ChartInfo(
  //   chartFunction: getMelonChart,
  //   imgUrl: melonRandomIMGs.getImage(),
  //   title: MelonCharts.GENREOMICS_DAILY.title,
  //   url: MelonCharts.GENREOMICS_DAILY,
  // ),
  // ChartInfo(
  //   chartFunction: getMelonChart,
  //   imgUrl: melonRandomIMGs.getImage(),
  //   title: MelonCharts.GENREOMICS_WEEKLY.title,
  //   url: MelonCharts.GENREOMICS_WEEKLY,
  // ),
  // ChartInfo(
  //   chartFunction: getMelonChart,
  //   imgUrl: melonRandomIMGs.getImage(),
  //   title: MelonCharts.GENREOMICS_MONTHLY.title,
  //   url: MelonCharts.GENREOMICS_MONTHLY,
  // ),
  ChartInfo(
      chartFunction: getBillboardChart,
      imgUrl: billboardRandomIMGs.getImage(),
      title: BillboardCharts.HOT_100.title,
      url: BillboardCharts.HOT_100),
  ChartInfo(
      chartFunction: getBillboardChart,
      imgUrl: billboardRandomIMGs.getImage(),
      title: BillboardCharts.BILLBOARD_200.title,
      url: BillboardCharts.BILLBOARD_200),
  ChartInfo(
      chartFunction: getBillboardChart,
      imgUrl: billboardRandomIMGs.getImage(),
      title: BillboardCharts.BILLBOARD_GLOBAL_200.title,
      url: BillboardCharts.BILLBOARD_GLOBAL_200),
  ChartInfo(
      chartFunction: getBillboardChart,
      imgUrl: billboardRandomIMGs.getImage(),
      title: BillboardCharts.KOREA_100.title,
      url: BillboardCharts.KOREA_100),
  ChartInfo(
      chartFunction: getBillboardChart,
      imgUrl: billboardRandomIMGs.getImage(),
      title: BillboardCharts.INDIA_SONGS.title,
      url: BillboardCharts.INDIA_SONGS),
  ChartInfo(
      chartFunction: getBillboardChart,
      imgUrl: billboardRandomIMGs.getImage(),
      title: BillboardCharts.JAPAN_HOT_100.title,
      url: BillboardCharts.JAPAN_HOT_100),
];
