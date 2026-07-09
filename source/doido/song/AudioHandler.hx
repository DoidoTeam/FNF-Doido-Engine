package doido.song;

import flixel.sound.FlxSound;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;

class AudioHandler extends FlxTypedGroup<FlxSound>
{
	static final audioResync:Int = 30;
	static final conductorResync:Int = 1000;

	public var inst:FlxSound;
	public var voicesGlobal:FlxSound;
	public var voicesOpp:FlxSound;

	public var songLength:Float = -1;
	public var playing(get, never):Bool;
	public var time(get, set):Float;
	public var speed(get, set):Float;

	public var muteVoices(default, set):Bool;
	public var muteOpponent(default, set):Bool;
	public var muteInst(default, set):Bool;

	public function new(song:String, postfix:String = "normal")
	{
		super();
		reload(song, postfix);
	}

	public function reload(song:String, postfix:String = "")
	{
		killMembers();

		inst = createStem(song, postfix, ['Inst']);
		add(inst);

		voicesGlobal = createStem(song, postfix, ['Voices-player', 'Voices']);
		add(voicesGlobal);

		voicesOpp = createStem(song, postfix, ['Voices-opp', 'Voices-opponent']);
		add(voicesOpp);

		muteVoices = false;
		muteOpponent = false;
		muteInst = false;
	}

	public function createStem(song:String, postfix:String, variants:Array<String>)
	{
		var snd:FlxSound = null;

		for (variant in variants)
		{
			var path = 'songs/$song/audio/${buildPath(song, postfix, variant)}';
			if (Assets.fileExists(path, SOUND))
			{
				snd = FlxG.sound.load(Assets.getAsset(path, SOUND, true));
				if (snd?.length < songLength || songLength == -1)
					songLength = snd.length;

				break;
			}
		}

		return snd;
	}

	public function buildPath(song:String, postfix:String, variant:String)
	{
		var i = variant.indexOf('-');
		var base = i == -1 ? variant : variant.substring(0, i);
		var rest = i == -1 ? "" : variant.substring(i);
		var suff = postfix == "" ? "" : '-$postfix';
		return '${base}$suff$rest';
	}

	inline public function checkSync(timeA:Float, timeB:Float, audio:Bool)
		return Math.abs(timeA - timeB) >= (audio ? audioResync : conductorResync) * speed;

	public function sync(elapsed:Float)
	{
		Conductor.songPos += elapsed * 1000 * speed;

		if (Conductor.songPos < 0 || Conductor.songPos > songLength - 2000)
			return;

		Conductor.songPos = FlxMath.lerp(inst.time, Conductor.songPos, Math.exp(-elapsed * 5));
		if (checkSync(Conductor.songPos, inst.time, false))
			Conductor.songPos = inst.time;

		forEachAlive((snd) ->
		{
			if (snd == inst)
				return;

			if (checkSync(Conductor.songPos, snd.time, true))
				snd.time = Conductor.songPos;
		});
	}

	override function destroy()
	{
		stop();
		super.destroy();
	}

	override function clear()
	{
		stop();
		super.clear();
	}

	public function play(?time:Float)
	{
		forEachAlive((snd) ->
		{
			snd.play();
			if (time != null)
				snd.time = time;
		});
	}

	public function stop()
		forEachAlive((snd) -> snd.stop());

	public function pause()
		forEachAlive((snd) -> snd.pause());

	public function get_time():Float
		return inst?.time ?? 0;

	public function set_time(v:Float)
	{
		forEachAlive((snd) -> snd.time = v);
		sync(0);
		return v;
	}

	public function get_speed():Float
		return inst?.pitch ?? 1;

	public function set_speed(v:Float)
	{
		forEachAlive((snd) -> snd.pitch = v);
		return v;
	}

	public function get_playing():Bool
		return inst?.playing ?? false;

	public function set_muteVoices(val:Bool):Bool
	{
		if (voicesGlobal != null)
			voicesGlobal.volume = (val ? 0.0 : 1.0);

		muteVoices = val;
		return val;
	}

	public function set_muteOpponent(val:Bool):Bool
	{
		if (voicesOpp != null)
			voicesOpp.volume = (val ? 0.0 : 1.0);

		muteOpponent = val;
		return val;
	}

	public function set_muteInst(val:Bool):Bool
	{
		if (inst != null)
			inst.volume = (val ? 0.0 : 1.0);

		muteInst = val;
		return val;
	}
}
