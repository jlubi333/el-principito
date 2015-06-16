import "dart:html";

import "assets.dart";

void setLevelDone(int w, int l, bool b) {
    window.localStorage["${w * Assets.LEVELS_PER_WORLD + l}"] = b ? "true" : "false";
}

bool isLevelDone(int w, int l) {
    return window.localStorage["${w * Assets.LEVELS_PER_WORLD + l}"] == "true";
}
