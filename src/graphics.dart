import "dart:html";

CanvasElement canvas;
CanvasRenderingContext2D ctx;

void setupGraphics(CanvasElement c) {
    canvas = c;
    ctx = canvas.getContext("2d");
}
