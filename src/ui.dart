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
    new UIText(
        {
            "top": "0%",
            "left": "0%",
            "width": "100%",
            "height": "100%",
        },
        "Loading...",
        center: true
    );
}

void displayMainMenuScreen() {
    Screen.close();
    new UITextButton(
        {
            "top": "35%",
            "left": "25%",
            "width": "50%",
            "height": "30%"
        },
        true,
        "Select World",
        (e) => displayWorldSelectScreen()
    );
}

void displayWorldSelectScreen() {
    Screen.close();
    UIHolder uih = new UIHolder(
        {
            "top": "0",
            "left": "0",
            "width": "100%",
            "height": "100%"
        },
        true,
        verticalCenter: true,
        horizontalCenter: true
    );
    for (int i = 0; i < Assets.levelCreators.length; i++) {
        uih.addInner(new UITextButton(
            {
                "display": "i",
                "width": "80%",
                "height": "${100 / Assets.levelCreators.length - 10}%"
            },
            false,
            "World ${i + 1}",
            (e) => displayLevelSelectScreen(i)
        ));
    }
}

void displayLevelSelectScreen(int world) {
    Screen.close();
    UIHolder uih = new UIHolder(
        {
            "top": "0",
            "left": "0",
            "width": "100%",
            "height": "100%"
        },
        true,
        verticalCenter: true,
        horizontalCenter: true
    );
    for (int i = 0; i < Assets.levelCreators[world].length; i++) {
        uih.addInner(new UITextButton(
            {
                "display": "inline-table",
                "width": "80%",
                "height": "${100 / Assets.levelCreators[world].length}%",
            },
            false,
            "Level ${world + 1}-${i + 1}",
            (e) => startLevel(Assets.levelCreators[world][i])
        ));
    }
}

void displayLevelScreen() {
    Screen.close();
    new UITextButton(
        {
            "left": "10px",
            "top": "10px",
            "width": "5%",
            "height": "5%"
        },
        true,
        "Mute",
        (MouseEvent e) {
            Sound.toggleMute();
            level.backgroundMusic.toggle();
        }
    );
    new UITextButton(
        {
            "right": "10px",
            "top": "10px",
            "width": "10%",
            "height": "5%"
        },
        true,
        "Main Menu",
        (e) => startMainMenu()
    );
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

    UIElement(Map<String, String> styleMap, bool absolute) {
        this.div = new DivElement();

        if (absolute) {
            this.div.style.position = "absolute";
            this.div.style.zIndex = "1";
        }

        styleMap.forEach((k, v) => this.div.style.setProperty(k, v));

        querySelector("body").children.add(this.div);
        Screen.elements.add(this);
    }

    void close() {
        this.div.remove();
    }
}

class UIHolder extends UIElement {
    List<UIElement> inners = [];

    UIHolder(Map<String, String> styleMap, bool absolute, {bool verticalCenter: false, bool horizontalCenter: false})
        : super(styleMap, absolute)
    {
        if (verticalCenter) {
            this.div.classes.add("vertical-center");
        }
        if (horizontalCenter) {
            this.div.classes.add("horizontal-center");
        }
    }

    void addInner(UIElement e) {
        this.inners.add(e);
        this.div.children.add(e.div);
    }

    void close() {
        for (UIElement e in this.inners) {
            e.close();
        }
        super.close();
    }
}

class UITextButton extends UIElement {
    DivElement innerDiv;
    String text;
    Action action;

    UITextButton(Map<String, String> styleMap, bool absolute, this.text, this.action)
        : super(styleMap, absolute)
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

    UIText(Map<String, String> styleMap, bool absolute, this.text, {center: false})
        : super(styleMap, absolute)
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
