import "dart:html";
import "dart:math";

import "assets.dart";
import "graphics.dart";
import "metrics.dart";
import "world.dart";

// 0b01
const int X_COLLISION_MASK = 1;
// 0b10
const int Y_COLLISION_MASK = 2;

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
        Assets.sounds["Death"].play(volume: 0.1);
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
        : super(Assets.entitySprites["Player"],
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
        Assets.sounds["PlayerDeath"].play(volume: 0.1);
    }

    void jump() {
        super.jump();
        Assets.sounds["Jump"].play(volume: 0.1);
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
}

class RebounderEnemy extends LivingEntity {
    static Random random = new Random();
    bool movingLeft;

    RebounderEnemy(Vector position)
        : super(Assets.entitySprites["RebounderEnemy"],
                new BoundingBox(position.x, position.y, 1 * Tile.SIZE, 1 * Tile.SIZE),
                new Vector.zero(),
                Direction.LEFT,
                0.5 * Tile.SIZE,
                1 * Tile.SIZE)
    {
        this.movingLeft = random.nextInt(2) == 1;
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
