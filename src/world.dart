import "dart:convert";
import "dart:html";

import "assets.dart";
import "entities.dart";
import "graphics.dart";
import "metrics.dart";

Level level;

class Level {
    String name;
    Sound backgroundMusic;
    num gravity;
    List<List<Tile>> map;
    List<Entity> entities;
    List<Entity> entitiesPendingRemoval = [];
    Player player;

    Level(this.name, this.backgroundMusic, this.gravity, this.map, this.entities, this.player);

    static Level loadFromFile(String url) async {
        String jsonString = await HttpRequest.getString(url);
        Map levelData = JSON.decode(jsonString);

        String name = levelData["name"];
        Sound backgroundMusic = Assets.sounds[levelData["backgroundMusic"]];
        num gravity = levelData["gravity"] * Tile.SIZE;

        List<List<Tile>> map = [];
        for (int r = 0; r < levelData["map"].length; r++) {
            map.add([]);
            for (int c = 0; c < levelData["map"][r].length; c++) {
                map[r].add(new Tile(levelData["map"][r][c], r, c));
            }
        }

        List<Entity> entities = [];

        Entity e;
        for (Map enemyData in levelData["enemies"]) {
            if (enemyData["class"] == "RebounderEnemy") {
                e = new RebounderEnemy(new Vector(
                    enemyData["x"] * Tile.SIZE,
                    enemyData["y"] * Tile.SIZE
                ));
            }
            entities.add(e);
        }

        Player player = new Player(
            new Vector(
                levelData["playerData"]["x"] * Tile.SIZE,
                levelData["playerData"]["y"] * Tile.SIZE
            ),
            directionFromString[levelData["initialDirection"]]
        );
        entities.add(player);

        return new Level(name, backgroundMusic, gravity, map, entities, player);
    }
}

class Tile {
    static const int SIZE = 128;
    static const List<int> BLOCKED_TYPES = const [1, 2];

    final int type;
    final bool isBlocked;
    final ImageElement sprite;
    final BoundingBox boundingBox;
    final int row, col;

    Tile(int type, int row, int col)
        : this.type = type
        , this.row = row
        , this.col = col
        , this.isBlocked = BLOCKED_TYPES.contains(type)
        , this.sprite = Assets.tileSprites[type]
        , this.boundingBox = new BoundingBox(col * Tile.SIZE,
                                             row * Tile.SIZE,
                                             Tile.SIZE,
                                             Tile.SIZE);

    void render(Vector offset) {
        if (this.type > 0) {
            ctx.drawImage(this.sprite,
                          this.boundingBox.x + offset.x,
                          this.boundingBox.y + offset.y);
        }
    }
}

num worldHeight() {
    return level.map.length * Tile.SIZE;
}

num worldWidth() {
    return level.map[0].length * Tile.SIZE;
}

num scaledCanvasWidth() {
    return canvas.width * worldHeight() / canvas.height;
}

Tile tileFromCoordinate(num x, num y) {
    int row = y ~/ Tile.SIZE;
    int col = x ~/ Tile.SIZE;

    if (row >= level.map.length || row < 0 || col >= level.map[row].length || col < 0) {
        return null;
    } else {
        return level.map[row][col];
    }
}
