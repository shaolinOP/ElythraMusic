import 'package:elythra_music/core/routes_and_consts/global_str_consts.dart';
import 'package:elythra_music/core/services/db/bloomee_db_service.dart';

enum SourceEngine {
  engJis("JISaavn"),
  engYtm("YTMusic"),
  engYtv("YTVideo");

  final String value;
  const SourceEngine(this.toARGB32);
}

Map<SourceEngine, List<String>> sourceEngineCountries = {
  SourceEngine.engJis: [
    "IN",
    "NP",
    "BT",
    "LK",
  ],
  SourceEngine.engYtm: [],
  SourceEngine.engYtv: [],
};

Future<List<SourceEngine>> availableSourceEngines() async {
  String country =
      await ElythraDBService.getSettingStr(GlobalStrConsts.countryCode) ?? "IN";
  List<SourceEngine> availSourceEngines = [];
  for (var engine in SourceEngine.toARGB32s) {
    bool isAvailable =
        await ElythraDBService.getSettingBool(engine.toARGB32) ?? true;
    if (isAvailable == true) {
      if (sourceEngineCountries[engine]!.contains(country) ||
          sourceEngineCountries[engine]!.isEmpty) {
        availSourceEngines.add(engine);
      }
    }
  }

  return availSourceEngines;
}
