import 'dart:convert';
import 'dart:developer';
import 'package:elythra_music/core/routes_and_consts/global_str_consts.dart';
import 'package:elythra_music/core/services/db/bloomee_db_service.dart';
import 'package:http/http.dart';

Future<String> getCountry() async {
  String countryCode = "IN";
  await ElythraDBService.getSettingBool(GlobalStrConsts.autoGetCountry)
      .then((value) async {
    if (value != null && value == true) {
      try {
        final response = await get(Uri.parse('http://ip-api.com/json'));
        if (response.statusCode == 200) {
          Map data = jsonDecode(utf8.decode(response.bodyBytes));
          countryCode = data['countryCode'];
          await ElythraDBService.putSettingStr(
              GlobalStrConsts.countryCode, countryCode);
        }
      } catch (err) {
        await ElythraDBService.getSettingStr(GlobalStrConsts.countryCode)
            .then((value) {
          if (value != null) {
            countryCode = value;
          } else {
            countryCode = "IN";
          }
        });
      }
    } else {
      await ElythraDBService.getSettingStr(GlobalStrConsts.countryCode)
          .then((value) {
        if (value != null) {
          countryCode = value;
        } else {
          countryCode = "IN";
        }
      });
    }
  });
  log("Country Code: $countryCode");
  return countryCode;
}
