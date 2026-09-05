package objects.ui.notes;

import doido.song.Conductor;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import shaders.RGBPalette;

class Note extends FlxSprite
{
	// main data
	public var data:NoteData;
	public var skin:String = "base";
	public var gotHit:Bool = false;
	public var missed:Bool = false;

	public var stepTime(get, null):Float;
	public function get_stepTime():Float {
		return data.stepTime + (Conductor.musicOffset / Conductor.stepCrochet);
	}

	// hold parenting
	public var holdParent:Note = null;
	public var children:Array<Note> = [];
	// hold data
	public var isHold:Bool = false;
	public var isHoldEnd:Bool = false;
	public var holdIndex:Float = -1;
	public var holdStep:Float = -1;
	public var holdHitPercent:Float = 0.0;
	public var holdCoyote:Float = 0.2;

	// noteskin stuff
	public var noteScale:Float = 1.0;

	// modchart stuff
	public var noteAngle:Null<Float> = null;
	public var noteSpeed:Null<Float> = null;
	public var noteSpeedMult:Float = 1.0;

	// oop
	public var rgb:Bool = false;
	public var rgbColors:Array<FlxColor> = [];
	public var colorShader:RGBPalette;

	public var quant:Bool = false;
	public var noteQuant:Int = 0;

	public function new()
	{
		super();
		colorShader = new RGBPalette();
	}

	public function loadData(data:NoteData, skin:String)
	{
		// visual stuff
		setPosition(-5000, -5000); // offscreen lol
		visible = true;
		alpha = 1.0;
		angle = 0;

		// main data
		this.data = data;
		this.skin = skin;
		gotHit = false;
		missed = false;

		// hold parenting
		holdParent = null;
		children = [];
		// hold stuff
		isHold = isHoldEnd = false;
		holdIndex = 0;
		holdStep = 0;
		holdHitPercent = 0.0;
		resetCoyote();

		// noteskin stuff
		noteScale = 1.0;

		// modchart stuff
		noteAngle = null;
		noteSpeed = null;
		noteSpeedMult = 1.0;

		// noteSpeed = (FlxG.random.bool(50) ? null : 1.0);
	}

	public function resetCoyote():Void
	{
		holdCoyote = 0.2;
	}

	public function reloadSprite()
	{
		clipRect = null;

		var direction:String = NoteUtil.intToString(data.lane);
		var hasRgb:Bool = false;
		quant = skin.endsWith("-quant");
		rgb = quant;

		var formatted:String = skin.replace("-quant", "");
		switch (formatted)
		{
			case "pixel":
				var path = 'ui/notes/pixel/${rgb ? 'quant/' : ''}';
				if (isHold)
					path += 'ends';
				else
					path += 'notes';
				this.loadImage(path, true, isHold ? 7 : 17, isHold ? 6 : 17);

				animation.add(direction, [data.lane + ((isHold && !isHoldEnd) ? 0 : 4)], 0, false);
				noteScale = 6;
				antialiasing = false;
				hasRgb = true;

			default:
				if (Assets.fileExists('images/ui/notes/$formatted/quant/notes', IMAGE))
					hasRgb = true;
				else if (!Assets.fileExists('images/ui/notes/$formatted/notes', IMAGE))
					formatted = "base";

				this.loadSparrow('ui/notes/$formatted/${(rgb && hasRgb) ? 'quant/' : ''}notes');
				var postfix:String = (isHold ? " hold" + (isHoldEnd ? " end" : "") : "");
				animation.addByPrefix(direction, 'note ${direction}${postfix}0', 0, false);
				noteScale = 0.7;
		}

		if (!hasRgb)
		{
			rgb = false;
			quant = false;
		}

		scale.set(noteScale, noteScale);
		updateHitbox();
		animation.play(direction);

		if (rgb)
		{
			if (shader != colorShader)
				shader = colorShader;

			if (quant)
			{
				noteQuant = NoteUtil.calcQuant(data);
				rgbColors = NoteUtil.getQuantColors(skin)[noteQuant];
			}

			colorShader.setColor(rgbColors[0], rgbColors[1], rgbColors[2]);
		}
		else
			shader = null;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public function updateOffsets()
	{
		updateHitbox();
		offset.x += frameWidth * scale.x / 2;
		if (isHold)
		{
			offset.y = 0;
			origin.y = 0;
		}
		else
			offset.y += frameHeight * scale.y / 2;
	}
}
