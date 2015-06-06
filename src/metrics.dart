Map<String, Direction> directionFromString = {
    "UP": Direction.UP,
    "RIGHT": Direction.RIGHT,
    "DOWN": Direction.DOWN,
    "LEFT": Direction.LEFT
};

enum Direction {
    UP, RIGHT, DOWN, LEFT
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
