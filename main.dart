import "dart:html";
import "dart:convert";
import "dart:math";
import "dart:async";
import "dart:web_audio";

const num DT = 1000 / 60;

// 0b01
const int X_COLLISION_MASK = 1;
// 0b10
const int Y_COLLISION_MASK = 2;

const int RENDER_DISTANCE = 20;

const int SPACEBAR_KEY = 32;

const int LEFT_KEY = 37;
const int UP_KEY = 38;
const int RIGHT_KEY = 39;
const int DOWN_KEY = 40;

const int A_KEY = 65;
const int D_KEY = 68;
const int W_KEY = 87;

const int M_KEY = 77;

Map<String, Direction> directionFromString = {
    "UP": Direction.UP,
    "RIGHT": Direction.RIGHT,
    "DOWN": Direction.DOWN,
    "LEFT": Direction.LEFT
};

Random randomizer = new Random();

Map<int, bool> keys = {};

CanvasElement canvas;
CanvasRenderingContext2D ctx;

Level level;

void main() async {
    await startGame();
}

void startGame() async {
    window.onKeyDown.listen((KeyboardEvent e) {
        keys[e.keyCode] = true;

        if (e.keyCode == M_KEY) {
            level.backgroundMusic.toggle();
        }
    });

    window.onKeyUp.listen((KeyboardEvent e) {
        keys[e.keyCode] = false;
    });

    await Assets.load();

    level = Assets.levels[0];
    level.backgroundMusic.play(loop: true);

    canvas = querySelector("#game");
    ctx = canvas.getContext("2d");

    window.onResize.listen((Event e) {
        resizeCanvas();
    });
    resizeCanvas();

    // Update and Render
    Timer updateTimer = new Timer.periodic(new Duration(microseconds: (1000.0 * DT).round()), update);
    window.animationFrame.then(render);
}

void update(Timer timer) {
    level.player.velocity.x = 0;
    if (isKeyPressed(A_KEY)) {
        level.player.moveLeft();
    }
    if (isKeyPressed(D_KEY)) {
        level.player.moveRight();
    }
    if (level.player.grounded && (isKeyPressed(SPACEBAR_KEY) || isKeyPressed(W_KEY))) {
        level.player.jump();
    }
    if (isKeyPressed(LEFT_KEY)) {
        level.player.attack(Direction.LEFT);
    }
    if (isKeyPressed(UP_KEY)) {
        level.player.attack(Direction.UP);
    }
    if (isKeyPressed(RIGHT_KEY)) {
        level.player.attack(Direction.RIGHT);
    }
    if (isKeyPressed(DOWN_KEY)) {
        level.player.attack(Direction.DOWN);
    }

    for (Entity e in level.entities) {
        e.update(DT);
    }
    for (Entity e in level.entitiesPendingRemoval) {
        level.entities.remove(e);
    }
    level.entitiesPendingRemoval.clear();
}

Vector offset = new Vector.zero();
Tile pt;
void render(num timestamp) {
    // Clear
    ctx.save();
    ctx.fillStyle = "#00C6FF";
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.restore();

    // TODO CLAMPING
    if (level.player.boundingBox.cx < scaledCanvasWidth() / 2) {
        offset.x = 0;
    } else if (level.player.boundingBox.cx > worldWidth() - scaledCanvasWidth() / 2) {
        offset.x = scaledCanvasWidth() - worldWidth();
    } else {
        offset.x = scaledCanvasWidth() / 2 - level.player.boundingBox.cx;
    }
    offset.y = 0;

    pt = level.player.tile != null ? level.player.tile : pt;
    for (int r = max(pt.row - RENDER_DISTANCE, 0); r <= min(pt.row + RENDER_DISTANCE, level.map.length - 1); r++) {
        for (int c = max(pt.col - RENDER_DISTANCE, 0); c <= min(pt.col + RENDER_DISTANCE, level.map[r].length - 1); c++) {
            level.map[r][c].render(offset);
        }
    }

    for (Entity e in level.entities) {
        e.render(offset);
    }

    window.animationFrame.then(render);
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

bool isKeyPressed(int keyCode) {
    // Cannot just return keys[keyCode] because it may be null.
    return keys[keyCode] == true;
}

void resizeCanvas() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    num s = canvas.height / worldHeight();
    ctx.scale(s, s);
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

class Assets {
    static const int TILE_COUNT = 3;
    static const int LEVEL_COUNT = 1;

    static final Map<String, Sound> sounds = {};

    static final Map<int, ImageElement> tileSprites = {};

    static final ImageElement playerSprite = new ImageElement();
    static final ImageElement idiotEnemySprite = new ImageElement();

    static final Map<int, Level> levels = {};


    static void load() async {
        // Sounds
        sounds["valse"] = await Sound.loadFromFile("assets/sounds/valse.ogg");

        // Tiles
        for (int i = 1; i <= TILE_COUNT; i++) {
            tileSprites[i] = new ImageElement(src: "assets/tiles/tile${i}.png?v=0");
            await tileSprites[i].onLoad.first;
        }

        // Player
        playerSprite.src = "assets/entities/player.gif?v=0";
        await playerSprite.onLoad.first;

        // Idiot Enemy
        idiotEnemySprite.src = "assets/entities/idiotEnemy.png?v=0";
        await idiotEnemySprite.onLoad.first;

        // Levels
        for (int i = 0; i < LEVEL_COUNT; i++) {
            levels[i] = await Level.loadFromFile("assets/levels/level${i}.json?v=0");
        }
    }
}

class Sound {
    static final AudioContext audioContext = new AudioContext();

    AudioBuffer audioBuffer;
    AudioBufferSourceNode source = null;
    GainNode gainNode = null;
    bool playing = false;

    Sound(this.audioBuffer);

    static Sound loadFromFile(String url) async {
        HttpRequest soundRequest = new HttpRequest();
        soundRequest.open("GET", url);
        soundRequest.responseType = "arraybuffer";
        soundRequest.send();

        await soundRequest.onLoad.first;

        AudioBuffer audioBuffer = await audioContext.decodeAudioData(soundRequest.response);

        return new Sound(audioBuffer);
    }

    void play({num volume: 1, bool loop: false}) {
        if (this.audioBuffer == null) {
            return;
        }
        this.source = audioContext.createBufferSource();
        this.gainNode = audioContext.createGain();

        this.source.buffer = this.audioBuffer;
        this.source.loop = loop;

        this.source.connectNode(gainNode);
        this.gainNode.connectNode(audioContext.destination);

        this.gainNode.gain.value = volume;

        this.source.start(0);
        this.playing = true;
    }

    void stop() {
        if (this.source != null) {
            this.source.stop();
        }
        this.playing = false;
    }

    void toggle({num volume: 1, bool loop: false}) {
        if (this.playing) {
            this.stop();
        } else {
            this.play(volume: volume, loop: loop);
        }
    }
}

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

enum Direction {
    UP, RIGHT, DOWN, LEFT
}

abstract class Entity {
    ImageElement sprite;
    BoundingBox boundingBox;
    Vector velocity;

    Tile get tile => tileFromCoordinate(this.boundingBox.x, this.boundingBox.y);

    Entity(this.sprite, this.boundingBox, this.velocity);

    bool collidesWithMap(int mask) {
        Tile tile;

        for (num modifier in [0.01, 0.5, 0.99]) {
            if ((mask & X_COLLISION_MASK) != 0) {
                if (this.velocity.x < 0) {
                    tile = tileFromCoordinate(this.boundingBox.x,
                                              this.boundingBox.y + this.boundingBox.height * modifier);
                } else if (this.velocity.x > 0) {
                    tile = tileFromCoordinate(this.boundingBox.right,
                                              this.boundingBox.y + this.boundingBox.height * modifier);
                }

                if (tile != null && tile.isBlocked) {
                    return true;
                }
            }

            if ((mask & Y_COLLISION_MASK) != 0) {
                if (this.velocity.y < 0) {
                    tile = tileFromCoordinate(this.boundingBox.x + this.boundingBox.width * modifier,
                                              this.boundingBox.y);
                } else if (this.velocity.y > 0) {
                    tile = tileFromCoordinate(this.boundingBox.x + this.boundingBox.width * modifier,
                                              this.boundingBox.bottom);
                }

                if (tile != null && tile.isBlocked) {
                    return true;
                }
            }
        }

        return false;
    }

    List<Entity> getCollidingEntities() {
        List<Entity> collidingEntities = [];
        for (Entity e in level.entities) {
            if (e == this) {
                continue;
            }
            if (this.boundingBox.intersects(e.boundingBox)) {
                collidingEntities.add(e);
            }
        }
        return collidingEntities;
    }

    num distanceSqToEntity(Entity other) {
        return pow(this.boundingBox.x - other.boundingBox.x, 2) + pow(this.boundingBox.y - other.boundingBox.y, 2);
    }

    void die() {
        level.entitiesPendingRemoval.add(this);
    }

    void update(num delta) {
        this.boundingBox.x += this.velocity.x * (delta / 1000);
        this.boundingBox.y += this.velocity.y * (delta / 1000);
    }

    void render(Vector offset) {
        ctx.drawImage(this.sprite,
                      this.boundingBox.x + offset.x,
                      this.boundingBox.y + offset.y);
    }
}

abstract class LivingEntity extends Entity {
    Direction direction;
    num speed, jumpPower;
    bool grounded;

    LivingEntity(ImageElement sprite,
                 BoundingBox boundingBox,
                 Vector initialVelocity,
                 this.direction,
                 this.speed,
                 this.jumpPower)
        : super(sprite, boundingBox, initialVelocity)
    {
        this.grounded = false;
    }

    void moveLeft() {
        this.velocity.x -= speed;
        this.direction = Direction.LEFT;
    }

    void moveRight() {
        this.velocity.x += speed;
        this.direction = Direction.RIGHT;
    }

    void jump() {
        this.velocity.y -= this.jumpPower;
    }

    void attack(Direction d) {}

    void update(num delta) {
        this.velocity.y += level.gravity * (delta / 1000);

        // Tile Collision
        this.boundingBox.x += this.velocity.x * (delta / 1000);
        if (this.collidesWithMap(X_COLLISION_MASK)) {
            if (this.velocity.x < 0) {
                this.boundingBox.x = (this.boundingBox.x / Tile.SIZE).ceil() * Tile.SIZE;
            } else if (this.velocity.x > 0) {
                this.boundingBox.x = (this.boundingBox.right / Tile.SIZE).floor() * Tile.SIZE - this.boundingBox.width;
            }
            this.velocity.x = 0;
        }

        this.boundingBox.y += this.velocity.y * (delta / 1000);
        this.grounded = false;
        if (this.collidesWithMap(Y_COLLISION_MASK)) {
            if (this.velocity.y < 0) {
                this.boundingBox.y = (this.boundingBox.y / Tile.SIZE).ceil() * Tile.SIZE;
            } else if (this.velocity.y > 0) {
                this.boundingBox.y = (this.boundingBox.bottom / Tile.SIZE).floor() * Tile.SIZE - this.boundingBox.height;
                this.grounded = true;
            }
            this.velocity.y = 0;
        }

        if (this.boundingBox.y > worldHeight()) {
            this.die();
        }
    }
}

class Player extends LivingEntity {
    Vector spawnPosition;
    num attackReach = 1.5 * Tile.SIZE;

    Player(Vector position,
           Direction initialDirection)
        : super(Assets.playerSprite,
                new BoundingBox(position.x, position.y, 1 * Tile.SIZE, 1 * Tile.SIZE),
                new Vector.zero(),
                initialDirection,
                6 * Tile.SIZE,
                15 * Tile.SIZE)
    {
        this.spawnPosition = position;
    }

    void die() {
        this.velocity = new Vector.zero();
        this.boundingBox.x = this.spawnPosition.x;
        this.boundingBox.y = this.spawnPosition.y;
    }

    void attack(Direction d) {
        for (Entity e in level.entities) {
            if (this.distanceSqToEntity(e) < pow(this.attackReach, 2)) {
                if (d == Direction.UP && this.boundingBox.y >= e.boundingBox.bottom
                    || d == Direction.RIGHT && this.boundingBox.right <= e.boundingBox.x
                    || d == Direction.DOWN && this.boundingBox.bottom <= e.boundingBox.y
                    || d == Direction.LEFT && this.boundingBox.x >= e.boundingBox.right) {
                    e.die();
                }
            }
        }
    }

    void update(num delta) {
        super.update(delta);
    }
}

class RebounderEnemy extends LivingEntity {
    bool movingLeft;

    RebounderEnemy(Vector position)
        : super(Assets.idiotEnemySprite,
                new BoundingBox(position.x, position.y, 1 * Tile.SIZE, 1 * Tile.SIZE),
                new Vector.zero(),
                Direction.LEFT,
                0.5 * Tile.SIZE,
                1 * Tile.SIZE)
    {
        this.movingLeft = randomizer.nextInt(2) == 1;
    }

    void attack(Direction d) {
        List<Entity> collidingEntities = this.getCollidingEntities();
        for (Entity e in collidingEntities) {
            if (e == level.player) {
                e.die();
            }
        }
    }

    void update(num delta) {
        if (this.velocity.x == 0) {
            if (this.movingLeft) {
                this.moveRight();
           } else {
                this.moveLeft();
            }
            this.movingLeft = !this.movingLeft;
        }
        this.attack(null);
        super.update(delta);
    }
}

class Vector {
    num x, y;

    Vector(this.x, this.y);
    Vector.zero() : this(0, 0);
}

class BoundingBox {
    num x, y, width, height;

    num get right => this.x + this.width;
    num get bottom => this.y + this.height;
    num get cx => this.x + this.width / 2;
    num get cy => this.y + this.height / 2;

    BoundingBox(this.x, this.y, this.width, this.height);

    void setPosition(num x, num y) {
        this.x = x;
        this.y = y;
    }

    void setSize(num width, num height) {
        this.width = width;
        this.height = height;
    }

    bool intersects(BoundingBox other) {
        return (this.x < other.right
                && this.right > other.x
                && this.y < other.bottom
                && this.bottom > other.y);
    }
}
