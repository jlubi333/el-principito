import "dart:html";

import "graphics.dart";
import "input.dart";
import "metrics.dart";
import "world.dart";

typedef void Action(MouseEvent e);

Screen screen;

class Screen {
    List<UIElement> elements;

    Screen(this.elements);

    void close() {
        for (UIElement ui in elements) {
            ui.close();
        }
    }
}

abstract class UIElement {
    DivElement div;

    UIElement(String xStyle, String yStyle, String widthStyle, String heightStyle) {
        this.div = new DivElement();

        this.div.style.position = "absolute";
        this.div.style.left = xStyle;
        this.div.style.top = yStyle;

        this.div.style.width = widthStyle;
        this.div.style.height = heightStyle;

        this.div.style.zIndex = "1";

        querySelector("body").children.add(this.div);
    }

    void close() {
        this.div.remove();
    }
}

class UITextButton extends UIElement {
    DivElement innerDiv;
    String text;
    Action action;

    UITextButton(this.text,
                 String xStyle, String yStyle,
                 String widthStyle, String heightStyle,
                 this.action)
        : super(xStyle, yStyle, widthStyle, heightStyle)
    {
        this.innerDiv = new DivElement();
        this.innerDiv.text = text;
        this.div.children.add(innerDiv);

        this.div.classes.add("vertical-center");
        this.div.classes.add("horizontal-center");
        this.div.classes.add("unselectable");

        this.div.style.color = "#FFFFFF";
        this.div.style.border = "1px solid #FFFFFF";
        this.div.style.cursor = "pointer";

        this.div.onMouseDown.listen(this.action);
    }
}
