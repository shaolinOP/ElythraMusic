import 'package:elythra_music/core/routes_and_consts/global_str_consts.dart';
import 'package:elythra_music/core/services/db/bloomee_db_service.dart';

enum SourceEngine {
  eng_JIS("JISaavn"),
  eng_YTM("YTMusic"),
  eng_YTV("YTVideo");

  final String value;
  const SourceEngine(this.value);
}

Map<SourceEngine, List<String>> sourceEngineCountries = {
  SourceEngine.eng_JIS: [
    "IN",
    "NP",
    "BT",
    "LK",
  ],
  SourceEngine.eng_YTM: [],
  SourceEngine.eng_YTV: [],
};

Future<List<SourceEngine>> availableSourceEngines() async {
  String country =
      await ElythraDBService.getSettingStr(GlobalStrConsts.countryCode) ?? "IN";
  List<SourceEngine> availSourceEngines = [];
  for (var engine in SourceEngine.values) {
    bool isAvailable =
        await ElythraDBService.getSettingBool(engine.value) ?? true;
    if (isAvailable == true) {
      if (sourceEngineCountries[engine]!.contains(country) ||
          sourceEngineCountries[engine]!.isEmpty) {
        availSourceEngines.add(engine);
      }
    }
  }

  return availSourceEngines;
}
