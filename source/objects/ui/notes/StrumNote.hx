package objects.ui.notes;

import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import shaders.RGBPalette;

class StrumNote extends DoidoSprite
{
	public var lane:Int = 0;
	public var skin:String = "base";

	public var initialPos:FlxPoint = FlxPoint.get(0, 0);
	public var strumScale:Float = 1.0;
	public var strumAngle:Float = 0.0;

	public var rgb:Bool = false;
	public var colorShader:RGBPalette;
	public var colorFallback:Array<FlxColor> = [0xFF87a3ad, 0xFFFFFFFF, 0xFF000000];
	public var lastColors:Array<FlxColor> = [];

	public function new()
	{
		super();
		colorShader = new RGBPalette();
	}

	public function reloadStrum(lane:Int, skin:String)
	{
		this.skin = skin;
		this.lane = lane;
		this.strumScale = 1.0;

		var direction:String = NoteUtil.intToString(lane);
		var hasRgb:Bool = false;
		rgb = skin.endsWith("-quant");

		var formatted:String = skin.replace("-quant", "");
		switch (formatted)
		{
			case "pixel":
				this.loadImage('ui/notes/pixel/${rgb ? 'quant/' : ''}notes', true, 17, 17);

				animation.add("static", [lane], 12, false);
				animation.add("pressed", [lane + 8], 12, false);
				animation.add("confirm", [lane + 12, lane + 16], 12, false);

				antialiasing = false;
				strumScale = 6;
				hasRgb = true;

			default:
				if (Assets.fileExists('images/ui/notes/$formatted/quant/strums', IMAGE))
					hasRgb = true;
				else if (!Assets.fileExists('images/ui/notes/$formatted/strums', IMAGE))
					formatted = "base";

				this.loadSparrow('ui/notes/$formatted/${(rgb && hasRgb) ? 'quant/' : ''}strums');
				for (anim in ["static", "pressed", "confirm"])
					animation.addByPrefix(anim, 'strum $direction $anim', 24, false);

				strumScale = 0.7;
		}

		if (!hasRgb)
			rgb = false;
		if (rgb)
			shader = colorShader;
		else
			shader = null;

		scale.set(strumScale, strumScale);
		updateHitbox();
		playAnim("static");
	}

	override function playAnim(animName:String, forced:Bool = false, frame:Int = 0)
	{
		if (animName != "confirm")
			setRGB(animName, null);

		super.playAnim(animName, forced, frame);
	}

	public function playConfirm(note:Note)
	{
		playAnim("confirm");
		setRGB("confirm", note);
	}

	public function setRGB(anim:String, note:Note)
	{
		if (!rgb)
			return;

		if (anim == "static")
		{
			shader = null;
			lastColors = [];
			return;
		}
		else
		{
			var colorArray:Array<FlxColor> = [];
			if (note == null)
				colorArray = colorFallback;
			else
				colorArray = note.rgbColors;

			if (colorArray.length < 3 || lastColors == colorArray)
				return;

			if (shader != colorShader)
				shader = colorShader;

			lastColors = colorArray;
			colorShader.setColor(colorArray[0], colorArray[1], colorArray[2]);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updateOffset();
	}

	override function preUpdateOffset()
	{
		this.spriteCenter();
	}
}
