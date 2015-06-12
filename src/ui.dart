import "dart:html";

typedef void Controller(Element parent);

class UI {
    final Element parent;
    final Controller controller;
    final String html;

    UI(this.parent, this.controller, this.html);

    static UI loadFromFile(Element parent, Controller controller, String url) async {
        String html = await HttpRequest.getString(url);
        return new UI(parent, controller, html);
    }

    UI fill(Map<String, String> map) {
        String newHtml = this.html;
        map.forEach((k, v) {
            newHtml = newHtml.replaceAll("{{${k}}}", v);
        });
        return new UI(this.parent, this.controller, newHtml);
    }

    void show() {
        this.parent.setInnerHtml(this.html, treeSanitizer: new NullTreeSanitizer());
        this.controller(this.parent);
    }

    void hide() {
        this.parent.children.clear();
    }
}

class NullTreeSanitizer implements NodeTreeSanitizer {
    void sanitizeTree(Node node) {}
}
