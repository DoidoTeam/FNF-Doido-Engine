package doido.song;

import flixel.sound.FlxSound;

// class for handling song files (Inst, Voices)
class AudioHandler
{
	// esse é que é o tal de "encapsulamento?"
    public var inst:FlxSound;
    public var voicesGlobal:FlxSound; // default
	public var voicesOpp:FlxSound; // if the opponent has a voices file, play them too

    public function new(song:String)
    {
        inst = FlxG.sound.load(Assets.inst(song));

		// global voices
		if (Assets.fileExists('songs/${song}/audio/Voices-player', SOUND))
			voicesGlobal = FlxG.sound.load(Assets.voices(song, '-player'));
		else if (Assets.fileExists('songs/${song}/audio/Voices', SOUND))
			voicesGlobal = FlxG.sound.load(Assets.voices(song));

		// opponent voices
		if (Assets.fileExists('songs/${song}/audio/Voices-opp', SOUND))
			voicesOpp = FlxG.sound.load(Assets.voices(song, "-opp"));

		muteVoices = false;
    }

    private function update(func:(snd:FlxSound)->Void)
	{
		func(inst);
		if (voicesGlobal != null) func(voicesGlobal);
		if (voicesOpp != null) func(voicesOpp);
	}

    public function sync()
	{
		if (Math.abs(Conductor.songPos - inst.time) >= 25)
		{
			Logs.print('FIXING DELAYED CONDUCTOR: ${Conductor.songPos} > ${inst.time}', WARNING);
			Conductor.songPos = inst.time;
		}

		update((snd) -> {
			if (snd == inst) return;
			if (Math.abs(Conductor.songPos - snd.time) >= 25)
			{
				Logs.print('FIXING DELAYED MUSIC: ${snd.time} > ${Conductor.songPos}', WARNING);
				update((fixSnd) -> {
					fixSnd.time = Conductor.songPos;
				});
			}
		});
	}

	public function play() {
		update((snd) -> {
			snd.play();
		});
	}

	public function pause() {
		update((snd) -> {
			snd.pause();
		});
	}

	public var playing(get, never):Bool;
	function get_playing():Bool {
		return inst.playing;
	}

	public var time(default, set):Float = 1.0;
	public function set_time(v:Float) {
		trace("before " + inst.time);
		time = v;
		update((snd) -> {
			snd.time = v;
		});
		sync();
		return speed;
	}

	public var speed(default, set):Float = 1.0;
	public function set_speed(v:Float) {
		speed = v;
		update((snd) -> {
			snd.pitch = v;
		});
		return speed;
	}

	public var muteVoices(default, set):Bool;
	function set_muteVoices(val:Bool):Bool {
		if (voicesGlobal != null)
			voicesGlobal.volume = (val ? 0.0 : 1.0);

		muteVoices = val;
		return val;
	}
}