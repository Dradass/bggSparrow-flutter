import 'package:flutter/material.dart';

int loadTimeoutMs = 2500;
const String bggUri = "https://boardgamegeek.com";

// If false - show warning about not corrent game choice
ValueNotifier<bool> isLoadedGamesPlayersCountInfoNotifier =
    ValueNotifier(false);

ValueNotifier<bool> isLoadedAllGamesImagesNotifier = ValueNotifier(false);

const userNameParamName = "username";
const passwordParamName = "password";

String appVersion = "Loading";

final GlobalKey selectGameButtonKey = GlobalKey();
final GlobalKey recognizeGameButtonKey = GlobalKey();
final GlobalKey swapSearchModeKey = GlobalKey();
final GlobalKey progressBarKey = GlobalKey();

Duration requestTimeout = const Duration(seconds: 10);
int selectedGameId = 0;
dynamic selectedGame;
//bool needUpdatePlaysFromBgg = false;
bool simpleIndicatorMode = false;

int defaultPlayersListId = 0;
int currentPageIndex = 0;

const int messageDuration = 2;
DateTime oldestDate = DateTime(1900);
DateTime lastDate = DateTime(3000);
const int maxColumnPlayerNameLength = 12;
