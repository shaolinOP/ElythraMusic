import 'dart:developer';

import 'package:elythra_music/core/model/chart_model.dart';
import 'package:elythra_music/plugins/ext_charts/chart_defines.dart';
// import 'package:elythra_music/core/services/db/bloomee_db_service.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

const List<String> melonIMGs = [
  "https://cdnimg.melon.co.kr/resource/image/cds/musicstory/imgUrl20240311045333700.jpg",
  "https://cdnimg.melon.co.kr/resource/image/cds/musicstory/imgUrl20240311045344001.jpg",
  "https://cdnimg.melon.co.kr/resource/image/cds/musicstory/imgUrl20240311043032241.jpg",
  "https://cdnimg.melon.co.kr/cm2/artistcrop/images/030/55/146/3055146_20231013113531_org.jpg?0e566ba6e62e36c713375aa363f4b9ef/melon/optimize/90",
  "https://cdnimg.melon.co.kr/resource/image/cds/artist/img_melon_ch_500.jpg/melon/resize/500",
  "https://cdnimg.melon.co.kr/resource/image/cds/musicstory/imgUrl20230509020832655.jpg",
  "https://cdnimg.melon.co.kr/resource/image/cds/musicstory/imgUrl20230628072034417.jpg/melon/optimize/90",
];

final RandomIMGs melonRandomIMGs = RandomIMGs(imgURLs: melonIMGs);

class MelonChartsLinks {
  static const String top100 = 'https://www.melon.com/chart/index.htm';
  static const String hot100 = 'https://www.melon.com/chart/hot100/index.htm';
  static const String genreomicsDaily =
      'https://www.melon.com/chart/day/index.htm?classCd=GN0000';
  static const String domesticDaily =
      'https://www.melon.com/chart/day/index.htm?classCd=DM0000';
  static const String overseasDaily =
      'https://www.melon.com/chart/day/index.htm?classCd=AB0000';
  static const String genreomicsWeekly =
      'https://www.melon.com/chart/week/index.htm?classCd=GN0000';
  static const String domesticWeekly =
      'https://www.melon.com/chart/week/index.htm?classCd=DM0000';
  static const String overseasWeekly =
      'https://www.melon.com/chart/week/index.htm?classCd=AB0000';
  static const String genreomicsMonthly =
      'https://www.melon.com/chart/month/index.htm?classCd=GN0000';
  static const String domesticMonthly =
      'https://www.melon.com/chart/month/index.htm?classCd=DM0000';
  static const String overseasMonthly =
      'https://www.melon.com/chart/month/index.htm?classCd=AB0000';
}

class MelonCharts {
  static final ChartURL top100 =
      ChartURL(title: "Melon\nTop 100", url: MelonChartsLinks.top100);
  static final ChartURL hot100 =
      ChartURL(title: "Melon\nHot 100", url: MelonChartsLinks.hot100);
  static final ChartURL genreomicsDaily = ChartURL(
      title: "Melon\nGenremics Daily", url: MelonChartsLinks.genreomicsDaily);
  static final ChartURL domesticDaily = ChartURL(
      title: "Melon\nDomestic Daily", url: MelonChartsLinks.domesticDaily);
  static final ChartURL overseasDaily = ChartURL(
      title: "Melon\nOverseas Daily", url: MelonChartsLinks.overseasDaily);
  static final ChartURL genreomicsWeekly = ChartURL(
      title: "Melon\nGenremics Weekly",
      url: MelonChartsLinks.genreomicsWeekly);
  static final ChartURL domesticWeekly = ChartURL(
      title: "Melon\nDomestic Weekly", url: MelonChartsLinks.domesticWeekly);
  static final ChartURL overseasWeekly = ChartURL(
      title: "Melon\nOverseas Weekly", url: MelonChartsLinks.overseasWeekly);
  static final ChartURL genreomicsMonthly = ChartURL(
      title: "Melon\nGenremics Monthly",
      url: MelonChartsLinks.genreomicsMonthly);
  static final ChartURL domesticMonthly = ChartURL(
      title: "Melon\nDomestic Monthly", url: MelonChartsLinks.domesticMonthly);
  static final ChartURL overseasMonthly = ChartURL(
      title: "Melon\nOverseas Monthly", url: MelonChartsLinks.overseasMonthly);
}

Future<ChartModel> getMelonChart(ChartURL url) async {
  final client = http.Client();

  try {
    final response = await client.get(Uri.parse(url.url), headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
    });
    if (response.statusCode == 200) {
      final document = parser.parse(response.body);
      final rankList = document.querySelector('#tb_list');
      final allItems50 = rankList!.querySelectorAll('tr.lst50');
      final allItems100 = rankList.querySelectorAll('tr.lst100');
      final allItems = allItems50.toList()..addAll(allItems100);

      List<ChartItemModel> chartItems = [];
      for (final item in allItems) {
        final div = item.querySelector('div.wrap_song_info');
        final title = div!.querySelector('div.ellipsis.rank01 a')?.text.trim();
        final label =
            div.querySelector('div.ellipsis.rank02 span')?.text.trim();
        final img =
            item.querySelector('a.image_typeAll img')!.attributes['src']!;

        chartItems.add(ChartItemModel(
          name: title,
          imageUrl: img.replaceAll(RegExp(r'resize/\d+'), 'resize/350'),
          subtitle: label,
        ));
      }
      final melonChart = ChartModel(
          chartName: url.title,
          chartItems: chartItems,
          url: url.url,
          lastUpdated: DateTime.now());
      // ElythraDBService.putChart(melonChart);
      log('Melon Charts: ${melonChart.chartItems!.length} tracks',
          name: "Melon");
      return melonChart;
    } else {
      // final chart = await ElythraDBService.getChart(url.title);
      // if (chart != null) {
      //   log('Melon Charts: ${chart.chartItems!.length} tracks loaded from cache',
      //       name: "Melon");
      //   return chart;
      // }
      throw Exception(
          'Parsing failed with status code: ${response.statusCode}');
    }
  } catch (e) {
    // final chart = await ElythraDBService.getChart(url.title);
    // if (chart != null) {
    //   log('Melon Charts: ${chart.chartItems!.length} tracks loaded from cache',
    //       name: "Melon");
    //   return chart;
    // }
    throw Exception('Failed to parse page');
  }
}
