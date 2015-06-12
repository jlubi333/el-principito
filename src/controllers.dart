import "assets.dart";
import "game.dart";
import "sound.dart";
import "world.dart";

void mainMenuController(Element parent) {
    parent.querySelector("#to-world-select").onMouseDown.listen((e) {
        Assets.ui["WorldSelect"].show();
    });
}

void worldSelectController(Element parent) {
    List<Element> buttons = parent.querySelectorAll(".world-select-button");
    for (Element button in buttons) {
        button.onMouseDown.listen((e) {
            String world = button.dataset["world"];
            Assets.ui["LevelSelect"].fill({"world": world}).show();
        });
    }
}

void levelSelectController(Element parent) {
    List<Element> buttons = parent.querySelectorAll(".level-select-button");
    for (Element button in buttons) {
        button.onMouseDown.listen((e) {
            int world = int.parse(button.dataset["world"]);
            int level = int.parse(button.dataset["level"]);
            startLevel(Assets.levelCreators[world][level]);
            Assets.ui["LevelControls"].show();
        });
    }
}

void levelControlsController(Element parent) {
    parent.querySelector("#mute-button").onMouseDown.listen((e) {
        Sound.toggleMute();
        level.backgroundMusic.toggle();
    });
    parent.querySelector("#to-main-menu").onMouseDown.listen((e) {
        startMainMenu();
    });
}
