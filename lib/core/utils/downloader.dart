import 'dart:developer';
import 'dart:io';
import 'package:elythra_music/core/model/saavnModel.dart';
import 'package:elythra_music/core/model/songModel.dart';
import 'package:elythra_music/core/repository/Youtube/youtube_api.dart';
import 'package:elythra_music/core/routes_and_consts/global_str_consts.dart';
import 'package:elythra_music/features/player/screens/widgets/snackbar.dart';
import 'package:elythra_music/core/services/db/bloomee_db_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

Future<Uint8List?> getSquareImg(Uint8List image) async {
  // Load the original image
  img.Image? originalImage = img.decodeImage(image);

  if (originalImage != null) {
    int maxDimension = originalImage.width > originalImage.height
        ? originalImage.width
        : originalImage.height;

    return img
        .copyResize(
            (img.copyExpandCanvas(originalImage,
                newHeight: maxDimension,
                newWidth: maxDimension,
                position: img.ExpandCanvasPosition.center)),
            width: maxDimension,
            height: maxDimension)
        .toUint8List();
  }
  return null;
}

class ElythraDownloader {
  static Future<Uint8List> getImgBytes(String url) async {
    final client = HttpClient();
    final HttpClientRequest request = await client.getUrl(Uri.parse(url));
    final HttpClientResponse response = await request.close();
    final bytes = await consolidateHttpClientResponseBytes(response);
    return bytes;
  }

  static Future<String?> downloadFile(String url, String fileName) async {
    // download image to app cache directory
    final tempDir = (await getExternalStorageDirectory())!.path;

    final File file = File('$tempDir/$fileName');
    final bool fileExists = file.existsSync();
    if (!fileExists) {
      final client = HttpClient();
      final HttpClientRequest request = await client.getUrl(Uri.parse(url));
      final HttpClientResponse response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);
      await file.writeAsBytes(bytes);
      if (file.existsSync()) {
        log('Downloaded $fileName');
        return "$tempDir/$fileName";
      }
    } else {
      log('File already exists: $fileName');
      try {
        await deleteFile('$tempDir/$fileName');
        return downloadFile(url, fileName);
      } catch (e) {
        log('Failed to get valid file for $fileName');
      }
    }
    return null;
  }

  static Future<bool> alreadyDownloaded(MediaItemModel song) async {
    final tempDB = await ElythraDBService.getDownloadDB(song);
    if (tempDB != null) {
      final File file = File("${tempDB.filePath}/${tempDB.fileName}");
      final isExist = file.existsSync();
      if (isExist) {
        return true;
      } else {
        await ElythraDBService.removeDownloadDB(song);
      }
    }

    return false;
  }

  static Future<String?> downloadSong(MediaItemModel song,
      {required String fileName, required String filePath}) async {
    final String? taskId;
    if (!(await alreadyDownloaded(song))) {
      try {
        String? kURL;
        if (song.extras!['source'] == 'youtube' ||
            (song.extras!['perma_url'].toString()).contains('youtube')) {
          kURL = await latestYtLink(song.id.replaceAll("youtube", ""));
        } else {
          kURL = song.extras!['url'];
          kURL = await getJsQualityURL(kURL!, isStreaming: false);
        }

        taskId = await FlutterDownloader.enqueue(
          url: kURL!,
          savedDir: filePath,
          fileName: fileName,
          showNotification: true,
          openFileFromNotification: false,
        );

        return taskId;
      } catch (e) {
        log("Failed to add ${song.title} to download queue",
            error: e, name: "ElythraDownloader");
      }
    } else {
      log("${song.title} is already downloaded. Skipping download");
      SnackbarService.showMessage("${song.title} is already downloaded");
    }
    return null;
  }

  static Future<void> songTagger(MediaItemModel song, String filePath) async {
    final hasStorageAccess =
        Platform.isAndroid ? await Permission.storage.isGranted : true;
    if (!hasStorageAccess) {
      await Permission.storage.request();
      if (!await Permission.storage.isGranted) {
        return;
      }
    }
    log("Tagging ${song.title} by ${song.artist}", name: "ElythraDownloader");
    // final imgPath =
    //     await downloadFile(song.artUri.toString(), "${song.id}.jpg");
    // log("Image downloaded for ${imgPath}", name: "ElythraDownloader");
    try {
      await MetadataGod.writeMetadata(
          file: filePath,
          metadata: Metadata(
            title: song.title,
            artist: song.artist,
            album: song.album,
            genre: song.genre,
            picture: Picture(
              data: (await getSquareImg(
                  await getImgBytes(song.artUri.toString())))!,
              mimeType: 'image/jpeg',
            ),
          ));
    } catch (e) {
      log("Failed to tag with image ${song.title} by ${song.artist}",
          error: e, name: "ElythraDownloader");
      await MetadataGod.writeMetadata(
          file: filePath,
          metadata: Metadata(
            title: song.title,
            artist: song.artist,
            album: song.album,
            genre: song.genre,
          ));
    }
    // deleteFile(imgPath!);
  }

  static Future<void> deleteFile(String fileName) async {
    final String filePath = fileName;
    final File file = File(filePath);
    await file.delete();
  }

  static Future<String?> latestYtLink(String id) async {
    final vidInfo = await ElythraDBService.getYtLinkCache(id);
    if (vidInfo != null) {
      if ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 350 >
          vidInfo.expireAt) {
        log("Link expired for vidId: $id", name: "ElythraDownloader");
        return await refreshYtLink(id);
      } else {
        log("Link found in cache for vidId: $id", name: "ElythraDownloader");
        String kurl = vidInfo.lowQURL!;
        await ElythraDBService.getSettingStr(GlobalStrConsts.ytDownQuality)
            .then((value) {
          if (value != null) {
            if (value == "High") {
              kurl = vidInfo.highQURL;
            } else {
              kurl = vidInfo.lowQURL!;
            }
          }
        });
        return kurl;
      }
    } else {
      log("No cache found for vidId: $id", name: "ElythraDownloader");
      return await refreshYtLink(id);
    }
  }

  static Future<String?> refreshYtLink(String id) async {
    String quality = "Low";
    await ElythraDBService.getSettingStr(GlobalStrConsts.ytDownQuality)
        .then((value) {
      if (value != null) {
        if (value == "High") {
          quality = "High";
        } else {
          quality = "Low";
        }
      }
    });
    final vidMap = await YouTubeServices().refreshLink(id, quality: quality);
    if (vidMap != null) {
      return vidMap["url"] as String;
    } else {
      return null;
    }
  }

  static Future<String> getValidFileName(
      String fileName, String filePath) async {
    final File file = File('$filePath/$fileName');
    final bool fileExists = file.existsSync();
    if (!fileExists) {
      return fileName;
    } else {
      log('File already exists: $fileName', name: "ElythraDownloader");
      try {
        fileName = fileName
            .replaceAll(".mp4", "(1).mp4")
            .replaceAll(".m4a", "(1).m4a");
        return getValidFileName(fileName, filePath);
      } catch (e) {
        log('Failed to get valid file for $fileName');
      }
    }
    return fileName;
  }
}
