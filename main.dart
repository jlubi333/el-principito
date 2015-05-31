import "dart:html";
import "dart:math";
import "dart:async";

const num DT = 1000 / 60;

const num GRAVITY = Tile.SIZE * 30;

// 0b01
const int X_COLLISION_MASK = 1;
// 0b10
const int Y_COLLISION_MASK = 2;

const int RENDER_DISTANCE = 10;

const int SPACEBAR_KEY = 32;
const int A_KEY = 65;
const int D_KEY = 68;
const int W_KEY = 87;

Map<int, bool> keys = {};

CanvasElement canvas;
CanvasRenderingContext2D ctx;

List<List<Tile>> tiles = [];

List<Entity> entities = [];
Player player;

void main() async {
    await startGame();
}

void startGame() async {
    window.onKeyDown.listen((KeyboardEvent e) {
        keys[e.keyCode] = true;
    });

    window.onKeyUp.listen((KeyboardEvent e) {
        keys[e.keyCode] = false;
    });

    await Assets.load();

    canvas = querySelector("#game");
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    ctx = canvas.getContext("2d");

    List<List<int>> map = [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
        [0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0],
        [0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    ];

    for (int r = 0; r < map.length; r++) {
        tiles.add([]);
        for (int c = 0; c < map[r].length; c++) {
            tiles[r].add(new Tile(map[r][c], r, c));
        }
    }

    player = new Player(new BoundingBox(Tile.SIZE, Tile.SIZE, Tile.SIZE, Tile.SIZE), Tile.SIZE * 6, Tile.SIZE * 15);
    entities.add(player);

    // Update and Render
    Timer updateTimer = new Timer.periodic(new Duration(microseconds: (1000.0 * DT).round()), update);
    window.animationFrame.then(render);
}

void update(Timer timer) {
    player.velocity.x = 0;
    if (isKeyPressed(A_KEY)) {
        player.moveLeft();
    }
    if (isKeyPressed(D_KEY)) {
        player.moveRight();
    }
    if (player.grounded && (isKeyPressed(SPACEBAR_KEY) || isKeyPressed(W_KEY))) {
        player.jump();
    }

    for (Entity e in entities) {
        e.update(DT);
    }
}

Vector offset = new Vector.zero();
Tile pt;
void render(num timestamp) {
    // Clear
    ctx.fillStyle = "#00C6FF";
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    offset.x = min(canvas.width / 2 - player.boundingBox.x, 0);
    offset.y = 0;

    pt = player.tile != null ? player.tile : pt;
    for (int r = max(pt.row - RENDER_DISTANCE, 0); r <= min(pt.row + RENDER_DISTANCE, tiles.length - 1); r++) {
        for (int c = max(pt.col - RENDER_DISTANCE, 0); c <= min(pt.col + RENDER_DISTANCE, tiles[r].length - 1); c++) {
            tiles[r][c].render(offset);
        }
    }

    for (Entity e in entities) {
        e.render(offset);
    }

    window.animationFrame.then(render);
}

bool isKeyPressed(int keyCode) {
    // Cannot just return keys[keyCode] because it may be null.
    return keys[keyCode] == true;
}

Tile tileFromCoordinate(num x, num y) {
    int row = y ~/ Tile.SIZE;
    int col = x ~/ Tile.SIZE;

    if (row >= tiles.length || row < 0 || col >= tiles[row].length || col < 0) {
        return null;
    } else {
        return tiles[row][col];
    }
}

class Assets {
    static final int TILE_COUNT = 2;
    static final Map<int, ImageElement> tileSprites = {};
    static final ImageElement playerSprite = new ImageElement();

    static void load() async {
        // Tiles
        for (int i = 1; i <= TILE_COUNT; i++) {
            tileSprites[i] = new ImageElement(src: "assets/tiles/tile${i}.png");
            await tileSprites[i].onLoad.first;
        }

        // Player
        playerSprite.src = "assets/entities/player.gif";
        await playerSprite.onLoad.first;
    }
}

class Tile {
    static const int SIZE = 128;
    static const List<int> BLOCKED_TYPES = const [1];

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

    void update(num delta) {
        this.updatePosition(delta);
    }

    void updatePosition(num delta) {
        this.boundingBox.x += this.velocity.x * (delta / 1000);
        this.boundingBox.y += this.velocity.y * (delta / 1000);
    }

    void render(Vector offset) {
        ctx.drawImage(this.sprite,
                      this.boundingBox.x + offset.x,
                      this.boundingBox.y + offset.y);
    }
}

class LivingEntity extends Entity {
    num speed, jumpPower;
    bool grounded;

    LivingEntity(ImageElement sprite,
                 BoundingBox boundingBox,
                 Vector initialVelocity,
                 this.speed,
                 this.jumpPower)
        : super(sprite, boundingBox, initialVelocity)
    {
        this.grounded = false;
    }

    void moveLeft() {
        this.velocity.x -= speed;
    }

    void moveRight() {
        this.velocity.x += speed;
    }

    void jump() {
        this.velocity.y -= this.jumpPower;
    }

    void update(num delta) {
        this.velocity.y += GRAVITY * (delta / 1000);

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
    }
}

class Player extends LivingEntity {
    Player(BoundingBox boundingBox, num speed, num jumpPower)
        : super(Assets.playerSprite,
                boundingBox,
                new Vector.zero(),
                speed,
                jumpPower);

    void render(Vector offset) {
        ctx.drawImage(this.sprite, min(canvas.width / 2, this.boundingBox.x), this.boundingBox.y);
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
