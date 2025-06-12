#!/bin/bash

# Fix Billboard chart references
sed -i 's/BillboardChartLinks\.SOCIAL_50/BillboardChartLinks.social50/g' lib/plugins/ext_charts/billboard_charts.dart
sed -i 's/BillboardChartLinks\.STREAMING_SONGS/BillboardChartLinks.streamingSongs/g' lib/plugins/ext_charts/billboard_charts.dart
sed -i 's/BillboardChartLinks\.DIGITAL_SONG_SALES/BillboardChartLinks.digitalSongSales/g' lib/plugins/ext_charts/billboard_charts.dart
sed -i 's/BillboardChartLinks\.RADIO_SONGS/BillboardChartLinks.radioSongs/g' lib/plugins/ext_charts/billboard_charts.dart
sed -i 's/BillboardChartLinks\.TOP_ALBUM_SALES/BillboardChartLinks.topAlbumSales/g' lib/plugins/ext_charts/billboard_charts.dart
sed -i 's/BillboardChartLinks\.CURRENT_ALBUMS/BillboardChartLinks.currentAlbums/g' lib/plugins/ext_charts/billboard_charts.dart
sed -i 's/BillboardChartLinks\.INDEPENDENT_ALBUMS/BillboardChartLinks.independentAlbums/g' lib/plugins/ext_charts/billboard_charts.dart
sed -i 's/BillboardChartLinks\.CATALOG_ALBUMS/BillboardChartLinks.catalogAlbums/g' lib/plugins/ext_charts/billboard_charts.dart
sed -i 's/BillboardChartLinks\.SOUNDTRACKS/BillboardChartLinks.soundtracks/g' lib/plugins/ext_charts/billboard_charts.dart
sed -i 's/BillboardChartLinks\.VINYL_ALBUMS/BillboardChartLinks.vinylAlbums/g' lib/plugins/ext_charts/billboard_charts.dart
sed -i 's/BillboardChartLinks\.HEATSEEKERS_ALBUMS/BillboardChartLinks.heatseekersAlbums/g' lib/plugins/ext_charts/billboard_charts.dart
sed -i 's/BillboardChartLinks\.WORLD_ALBUMS/BillboardChartLinks.worldAlbums/g' lib/plugins/ext_charts/billboard_charts.dart
sed -i 's/BillboardChartLinks\.CANADIAN_HOT_100/BillboardChartLinks.canadianHot100/g' lib/plugins/ext_charts/billboard_charts.dart
sed -i 's/BillboardChartLinks\.JAPAN_HOT_100/BillboardChartLinks.japanHot100/g' lib/plugins/ext_charts/billboard_charts.dart
sed -i 's/BillboardChartLinks\.KOREA_100/BillboardChartLinks.korea100/g' lib/plugins/ext_charts/billboard_charts.dart
sed -i 's/BillboardChartLinks\.INDIA_SONGS/BillboardChartLinks.indiaSongs/g' lib/plugins/ext_charts/billboard_charts.dart
sed -i 's/BillboardChartLinks\.BILLBOARD_GLOBAL_200/BillboardChartLinks.billboardGlobal200/g' lib/plugins/ext_charts/billboard_charts.dart