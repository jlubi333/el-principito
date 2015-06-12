import "dart:html";
import "dart:web_audio";

import "world.dart";

class Assets {
    static const int TILE_COUNT = 3;
    static const int WORLD_COUNT = 1;
    static const int LEVELS_PER_WORLD = 1;

    static final Map<String, Sound> sounds = {};
    static final Map<int, ImageElement> tileSprites = {};
    static final Map<String, ImageElement> entitySprites = {};
    static final Map<int, Map<int, LevelCreator>> levelCreators = {};

    static void load() async {
        // Sounds
        sounds["Valse"] = await Sound.loadFromFile("assets/sounds/Valse.ogg");
        sounds["Jump"] = await Sound.loadFromFile("assets/sounds/Jump.wav");
        sounds["Death"] = await Sound.loadFromFile("assets/sounds/Death.wav");
        sounds["PlayerDeath"] = await Sound.loadFromFile("assets/sounds/PlayerDeath.wav");

        // Tiles
        for (int i = 1; i <= TILE_COUNT; i++) {
            tileSprites[i] = new ImageElement(src: "assets/tiles/Tile${i}.png?v=0");
            await tileSprites[i].onLoad.first;
        }

        // Player
        entitySprites["Player"] = new ImageElement();
        entitySprites["Player"].src = "assets/entities/Player.gif?v=0";
        await entitySprites["Player"].onLoad.first;

        // Idiot Enemy
        entitySprites["RebounderEnemy"] = new ImageElement();
        entitySprites["RebounderEnemy"].src = "assets/entities/RebounderEnemy.png?v=0";
        await entitySprites["RebounderEnemy"].onLoad.first;

        // Levels
        for (int w = 0; w < WORLD_COUNT; w++) {
            levelCreators[w] = {};
            for (int i = 0; i < LEVELS_PER_WORLD; i++) {
                levelCreators[w][i] = await Level.loadFromFile("assets/levels/world${w + 1}/Level${i + 1}.json?v=0");
            }
        }
    }
}

class Sound {
    static final AudioContext audioContext = new AudioContext();

    static bool mute = false;

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

    static void toggleMute() {
        mute = !mute;
    }

    void play({num volume: 1, bool loop: false}) {
        if (this.audioBuffer == null || mute) {
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
