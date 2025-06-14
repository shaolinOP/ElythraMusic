import 'package:elythra_music/features/player/screens/widgets/sign_board_widget.dart';
import 'package:elythra_music/features/player/screens/widgets/snackbar.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:elythra_music/core/utils/external_list_importer.dart';
import 'package:flutter/material.dart';

class ImporterDialogWidget extends StatefulWidget {
  final Stream<ImporterState> strm;
  const ImporterDialogWidget({super.key, required this.strm});

  @override
  State<ImporterDialogWidget> createState() => ImporterDialogWidgetStateState();
}

class ImporterDialogWidgetStateState extends State<ImporterDialogWidget> {
  String message = "";
  bool isCompleted = false;
  bool isFailed = false;
  @override
  void initState() {
    widget.strm.listen((event) async {
      setState(() {
        message = event.message;
      });
      if (event.isFailed) {
        setState(() {
          isFailed = event.isFailed;
        });
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.of(context).pop();
        SnackbarService.showMessage("Import Failed!");
      } else if (event.isDone) {
        setState(() {
          isCompleted = event.isDone;
        });
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.of(context).pop();
        // SnackbarService.showMessage("Import Completed");
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 200,
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 28, 4, 25),
              Color.fromARGB(255, 14, 0, 24),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: isCompleted
            ? const SignBoardWidget(
                message: "Import Completed",
                icon: Icons.check_circle,
              )
            : isFailed
                ? const SignBoardWidget(
                    message: "Import Failed",
                    icon: Icons.error,
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4.0, top: 4),
                            child: SizedBox(
                                height: 40,
                                width: 40,
                                child: CircularProgressIndicator()),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.85,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 8.0, left: 8.0, top: 8),
                            child: Text(
                              message,
                              style: const TextStyle(
                                      fontSize: 16,
                                      color: DefaultTheme.primaryColor1)
                                  .merge(DefaultTheme.secondoryTextStyle),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
