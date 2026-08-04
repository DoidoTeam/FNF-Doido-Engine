package doido.objects.system.soundtray;

import flixel.math.FlxMath;
import flixel.system.ui.FlxSoundTray;
import openfl.display.Bitmap;
import openfl.media.Sound;

// based on base game's sound tray implementation, with some modifications
class FunkinSoundTray extends FlxSoundTray
{
	public var timer:Float = 0;
	public var defaultScale:Float = 0.30;
	public var lerpY:Float = 0;
	public var lerpAlpha:Float = 0;

	public var bg:Bitmap;
	public var backing:Bitmap;
	public var bars:Array<Bitmap> = [];

	public var volUp:Sound;
	public var volDown:Sound;
	public var volMax:Sound;

	public function new()
	{
		super();
		removeChildren();

		bg = new Bitmap(Assets.image("ui/soundtray/volumebox", true).bitmap);
		bg.scaleX = defaultScale;
		bg.scaleY = defaultScale;
		bg.smoothing = true;
		addChild(bg);

		backing = new Bitmap(Assets.image("ui/soundtray/bars_10", true).bitmap);
		backing.x = 9;
		backing.y = 5;
		backing.scaleX = defaultScale;
		backing.scaleY = defaultScale;
		backing.smoothing = true;
		addChild(backing);
		backing.alpha = 0.4;

		for (i in 1...11)
		{
			var bar:Bitmap = new Bitmap(Assets.image("ui/soundtray/bars_" + i, true).bitmap);
			bar.x = 9;
			bar.y = 5;
			bar.scaleX = defaultScale;
			bar.scaleY = defaultScale;
			bar.smoothing = true;
			addChild(bar);
			bars.push(bar);
		}

		screenCenter();
		y = -height - 10;

		volUp = Assets.sound("soundtray/up", true);
		volDown = Assets.sound("soundtray/down", true);
		volMax = Assets.sound("soundtray/max", true);
	}

	override public function update(ms:Float):Void
	{
		var elapsed = ms / 1000.0;

		if (timer > 0)
		{
			timer -= elapsed;
			if (timer <= 0)
			{
				lerpY = -height - 10;
				lerpAlpha = 0;
			}
		}
		else if (y <= -height)
		{
			visible = false;
			active = false;
		}

		y = FlxMath.lerp(y, lerpY, elapsed * 6);
		alpha = FlxMath.lerp(alpha, lerpAlpha, elapsed * 6);
		screenCenter();
	}

	override function showIncrement():Void
	{
		showTray();
		playSound(true);
	}

	override function showDecrement():Void
	{
		showTray();
		playSound(false);
	}

	public function playSound(up:Bool = false):Void
	{
		if (silent)
			return;

		FlxG.sound.load(FlxG.sound.volume == 1 ? volMax : (up ? volUp : volDown)).play();
	}

	public function showTray():Void
	{
		timer = 1.5;
		lerpY = 10;
		lerpAlpha = 1;
		visible = true;
		active = true;

		updateBars();
		saveVolume();
	}

	public function updateBars():Void
	{
		var volume:Int = FlxG.sound.muted ? 0 : Math.round(FlxG.sound.volume * 10);
		for (i in 0...bars.length)
			bars[i].visible = i < volume;
	}

	public function saveVolume():Void
	{
		Save.data.volume = FlxG.sound.volume;
		Save.data.muted = FlxG.sound.muted;
		Save.save();
	}
}
