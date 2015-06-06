import "dart:html";

CanvasElement canvas;
CanvasRenderingContext2D ctx;

void setupGraphics(String canvasSelector) {
    canvas = querySelector(canvasSelector);
    ctx = canvas.getContext("2d");
}
