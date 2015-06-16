import "assets.dart";
import "game.dart";
import "local_storage.dart";
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
        int world = int.parse(button.dataset["world"]);
        int level = int.parse(button.dataset["level"]);
        bool open = isLevelDone(world, level - 1);
        bool done = isLevelDone(world, level);
        if (open || done) {
            button.onMouseDown.listen((e) {
                setLevel(world, level);
                startLevel();
                Assets.ui["LevelControls"].show();
            });

            if (done) {
                button.classes.add("done");
            } else if (open) {
                button.classes.add("open");
            }
        } else {
            button.classes.add("locked");
        }
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
