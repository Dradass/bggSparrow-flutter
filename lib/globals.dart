int selectedGameId = 0;
dynamic selectedGame;
bool needUpdatePlaysFromBgg = false;
bool simpleIndicatorMode = false;
int defaultPlayersListId = 0;

const int messageDuration = 2;
DateTime oldestDate = DateTime(1900);
DateTime lastDate = DateTime(3000);
const int maxColumnPlayerNameLength = 12;
