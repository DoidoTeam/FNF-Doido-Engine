package backend.system;

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

/**
 * Modified Sound Tray
 * Because flixel is a bitch we redefine a bunch of stuff but named different... whatever
 */
class SoundTray extends FlxSoundTray
{
	var timer:Float;
	var defaultWidth:Int = 80;
	var defaultHeight:Int = 30;
	var defaultScale:Float = 2.0;
	var defaultFontSize:Int = 10;
	var defaultColor:FlxColor = FlxColor.WHITE;
	var bgWidth:Float = 0;

	var bg:Bitmap;
	var text:TextField;
	var bars:Array<Bitmap>;
	@:keep
	public function new()
	{
		super();
    	removeChildren(); //yikes!

		visible = false;
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

		y = -height;
		visible = false;
	}

	override public function update(MS:Float):Void
	{
		// Animate stupid sound tray thing
		if (timer > 0)
		{
			timer -= MS / 1000;
		}
		else if (y > -height)
		{
			y -= (MS / 1000) * FlxG.height * 2;

			if (y <= -height)
			{
				visible = false;
				active = false;
    		}
		}
	}

	override public function showAnim(volume:Float, ?sound:FlxSoundAsset, duration = 1.0, label = "VOLUME"):Void
	{
		var sound = Assets.sound("menu/scrollMenu");
		if (sound != null)
			FlxG.sound.load(sound).play();

		timer = duration;
		y = 0;
		visible = true;
		active = true;
		
		final numBars = Math.round(volume * 10);
		for (i in 0...bars.length)
			bars[i].alpha = i < numBars ? 1.0 : 0.5;

		text.text = label;
		traySize();

		Save.data.volume = FlxG.sound.volume;
		Save.data.muted  = FlxG.sound.muted;
		Save.save();
	}

	override public function screenCenter():Void
	{
		scaleX = defaultScale;
		scaleY = defaultScale;

		x = (0.5 * (Lib.current.stage.stageWidth - bgWidth * defaultScale) - FlxG.game.x);
	}

	function traySize()
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