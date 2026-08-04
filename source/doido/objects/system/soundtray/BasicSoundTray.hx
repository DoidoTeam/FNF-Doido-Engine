package doido.objects.system.soundtray;

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import flixel.system.ui.FlxSoundTray;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import flixel.math.FlxMath;
import openfl.media.Sound;

// very old
class BasicSoundTray extends FlxSoundTray
{
	public final newSounds:Bool = true;

	public var timer:Float = 0;
	public var defaultWidth:Int = 80;
	public var defaultHeight:Int = 30;
	public var defaultScale:Float = 2.0;
	public var defaultFontSize:Int = 10;
	public var defaultColor:FlxColor = FlxColor.WHITE;
	public var bgWidth:Float = 0;

	public var lerpY:Float = 0;
	public var lerpAlpha:Float = 0;

	public var bg:Bitmap;
	public var text:TextField;
	public var bars:Array<Bitmap>;

	public var volUp:Sound;
	public var volDown:Sound;
	public var volMax:Sound;

	@:keep
	public function new()
	{
		super();
		removeChildren(); // yikes!

		scaleX = defaultScale;
		scaleY = defaultScale;

		bg = new Bitmap(new BitmapData(defaultWidth, defaultHeight, true, 0x7F000000));
		screenCenter();
		addChild(bg);

		text = new TextField();
		text.width = defaultWidth;
		text.multiline = true;
		text.selectable = false;
		var dtf:TextFormat = new TextFormat(Main.globalFont, defaultFontSize, defaultColor);
		dtf.align = TextFormatAlign.CENTER;
		text.defaultTextFormat = dtf;
		addChild(text);
		text.text = "VOLUME";
		text.y = 16;

		var bar:Bitmap;
		bars = new Array();

		for (i in 0...10)
		{
			bar = new Bitmap(new BitmapData(4, i + 1, false, defaultColor));
			addChild(bar);
			bars.push(bar);
		}

		traySize();
		screenCenter();
		y = -height;
		visible = false;

		if (newSounds)
		{
			volUp = Assets.sound("soundtray/up", true);
			volDown = Assets.sound("soundtray/down", true);
			volMax = Assets.sound("soundtray/max", true);
		}
		else
			volUp = Assets.sound("scroll", true);
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

		if (newSounds)
			FlxG.sound.load(FlxG.sound.volume == 1 ? volMax : (up ? volUp : volDown)).play();
		else
			FlxG.sound.load(volUp).play();
	}

	public function showTray(label:String = "VOLUME"):Void
	{
		timer = 1.5;
		lerpY = 0;
		lerpAlpha = 1;
		visible = true;
		active = true;

		text.text = label;
		traySize();

		updateBars();
		saveVolume();
	}

	public function updateBars():Void
	{
		var volume:Int = FlxG.sound.muted ? 0 : Math.round(FlxG.sound.volume * 10);
		for (i in 0...bars.length)
			bars[i].alpha = i < volume ? 1.0 : 0.5;
	}

	public function saveVolume():Void
	{
		Save.data.volume = FlxG.sound.volume;
		Save.data.muted = FlxG.sound.muted;
		Save.save();
	}

	override public function screenCenter():Void
	{
		scaleX = defaultScale;
		scaleY = defaultScale;

		x = (0.5 * (Lib.current.stage.stageWidth - bgWidth * defaultScale) - FlxG.game.x);
	}

	public function traySize()
	{
		if (text.textWidth + 10 > bg.width)
			text.width = text.textWidth + 10;

		bg.width = text.textWidth + 10 > defaultWidth ? text.textWidth + 10 : defaultWidth;
		bgWidth = bg.width;

		text.width = bg.width;

		var bx:Int = Std.int(bg.width / 2 - 30);
		var by:Int = 14;
		for (i in 0...bars.length)
		{
			bars[i].x = bx;
			bars[i].y = by;
			bx += 6;
			by--;
		}

		screenCenter();
	}
}
#end
