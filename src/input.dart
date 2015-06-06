import "dart:html";

typedef void KeyboardHandler(KeyboardEvent e);
typedef void ClickHandler(KeyboardEvent e);

const int SPACEBAR_KEY = 32;

const int LEFT_KEY = 37;
const int UP_KEY = 38;
const int RIGHT_KEY = 39;
const int DOWN_KEY = 40;

const int A_KEY = 65;
const int D_KEY = 68;
const int W_KEY = 87;

const int M_KEY = 77;

Map<int, bool> keys = {};

void setupInputHandler() {
    window.onKeyDown.listen((KeyboardEvent e) {
        keys[e.keyCode] = true;
    });

    window.onKeyUp.listen((KeyboardEvent e) {
        keys[e.keyCode] = false;
    });
}
