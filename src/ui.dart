import "dart:html";

import "assets.dart";
import "game.dart";
import "graphics.dart";
import "input.dart";
import "metrics.dart";
import "world.dart";

typedef void Action(MouseEvent e);

void displayLoadingScreen() {
    Screen.close();
    Screen.elements.add(new UIText(
        {
            "top": "0%",
            "left": "0%",
            "width": "100%",
            "height": "100%",
        },
        "Loading...",
        center: true
    ));
}

void displayMainMenuScreen() {
    Screen.close();
    Screen.elements.add(new UITextButton(
        {
            "top": "35%",
            "left": "25%",
            "width": "50%",
            "height": "30%"
        },
        "Start Game",
        (e) => startLevel(0)
    ));
}

void displayLevelScreen() {
    Screen.close();
    Screen.elements.add(new UITextButton(
        {
            "left": "10px",
            "top": "10px",
            "width": "5%",
            "height": "5%"
        },
        "Mute",
        (MouseEvent e) {
            Sound.toggleMute();
            level.backgroundMusic.toggle();
        }
    ));
    Screen.elements.add(new UITextButton(
        {
            "right": "10px",
            "top": "10px",
            "width": "10%",
            "height": "5%"
        },
        "Main Menu",
        (e) => startMainMenu()
    ));
}

abstract class Screen {
    static List<UIElement> elements = [];

    static void setBackground(String background) {
        querySelector("body").style.background = background;
    }

    static void close() {
        for (UIElement ui in elements) {
            ui.close();
        }
    }
}

abstract class UIElement {
    DivElement div;

    UIElement(Map<String, String> styleMap) {
        this.div = new DivElement();

        this.div.style.position = "absolute";
        this.div.style.zIndex = "1";

        styleMap.forEach((k, v) => this.div.style.setProperty(k, v));

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

    UITextButton(Map<String, String> styleMap, this.text, this.action)
        : super(styleMap)
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

class UIText extends UIElement {
    DivElement innerDiv;
    String text;

    UIText(Map<String, String> styleMap, this.text, {center: false})
        : super(styleMap)
    {
        this.innerDiv = new DivElement();
        this.innerDiv.text = text;
        this.div.children.add(innerDiv);

        if (center) {
            this.div.classes.add("vertical-center");
            this.div.classes.add("horizontal-center");
            this.div.classes.add("unselectable");
        }
    }
}
