import "dart:html";

import "controllers.dart";
import "sound.dart";
import "ui.dart";
import "world.dart";

class Assets {
    static const int TILE_COUNT = 5;
    static const int WORLD_COUNT = 3;
    static const int LEVELS_PER_WORLD = 3;

    static final Map<String, Sound> sounds = {};
    static final Map<String, UI> ui = {};
    static final Map<int, ImageElement> tileSprites = {};
    static final Map<String, ImageElement> entitySprites = {};
    static final Map<int, Map<int, LevelCreator>> levelCreators = {};

    static void load() async {
        // Sounds
        sounds["Valse"] = await Sound.loadFromFile("assets/sounds/Valse.ogg?v=0");
        sounds["Jump"] = await Sound.loadFromFile("assets/sounds/Jump.wav?v=0");
        sounds["Death"] = await Sound.loadFromFile("assets/sounds/Death.wav?v=0");
        sounds["PlayerDeath"] = await Sound.loadFromFile("assets/sounds/PlayerDeath.wav?v=0");

        // UI
        HtmlElement uiParent = querySelector("#ui");
        ui["MainMenu"] = await UI.loadFromFile(uiParent, mainMenuController, "assets/ui/MainMenu.html?v=0");
        ui["WorldSelect"] = await UI.loadFromFile(uiParent, worldSelectController, "assets/ui/WorldSelect.html?v=0");
        ui["LevelSelect"] = await UI.loadFromFile(uiParent, levelSelectController, "assets/ui/LevelSelect.html?v=0");
        ui["LevelControls"] = await UI.loadFromFile(uiParent, levelControlsController, "assets/ui/LevelControls.html?v=0");

        // Tiles
        for (int i = 1; i <= TILE_COUNT; i++) {
            tileSprites[i] = new ImageElement(src: "assets/tiles/Tile${i}.png?v=0");
            await tileSprites[i].onLoad.first;
        }

        // Player
        entitySprites["Player"] = new ImageElement();
        entitySprites["Player"].src = "assets/entities/Player.gif?v=0";
        await entitySprites["Player"].onLoad.first;

        // Idiot Enemy
        entitySprites["RebounderEnemy"] = new ImageElement();
        entitySprites["RebounderEnemy"].src = "assets/entities/RebounderEnemy.png?v=0";
        await entitySprites["RebounderEnemy"].onLoad.first;

        // Levels
        for (int w = 1; w <= WORLD_COUNT; w++) {
            levelCreators[w] = {};
            for (int i = 1; i <= LEVELS_PER_WORLD; i++) {
                levelCreators[w][i] = await Level.loadFromFile("assets/levels/world${w}/Level${i}.json?v=6");
            }
        }
    }
}
