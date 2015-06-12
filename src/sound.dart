import "dart:html";
import "dart:web_audio";

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
