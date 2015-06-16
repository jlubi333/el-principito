import "dart:html";

import "assets.dart";
import "world.dart";

void setLevelDone(int w, int l, bool b) {
    int hash = hashLevel(w, l);
    window.localStorage["level${hash}"] = b ? "true" : "false";
}

bool isLevelDone(int w, int l) {
    int hash = hashLevel(w, l);
    if (hash == hashLevel(1, 0)) {
        return true;
    }
    return window.localStorage["level${hash}"] == "true";
}
