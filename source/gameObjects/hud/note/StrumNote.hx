package gameObjects.hud.note;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;

class StrumNote extends FlxSprite
{
	public function new()
	{
		super();
		reloadStrum(0, "default");
	}

	public var strumData:Int = 0;
	public var strumType:String = "default";

	// use these to modchart
	public var strumSize:Float = 1.0;
	public var scaleOffset:FlxPoint = new FlxPoint(0,0);
	public var initialPos:FlxPoint = new FlxPoint(0,0);

	public function reloadStrum(strumData:Int, ?strumType:String = "default"):StrumNote
	{
		this.strumData = strumData;
		this.strumType = strumType;
		strumSize = 1.0;

		frames = Paths.getSparrowAtlas("notes/" + strumType + "/strums");

		var direc:String = NoteUtil.getDirection(strumData);

		switch(strumType)
		{
			default:
				strumSize = 0.7;
				animation.addByPrefix("static",  'strum $direc static',  24, false);
				animation.addByPrefix("pressed", 'strum $direc pressed', 12, false);
				animation.addByPrefix("confirm", 'strum $direc confirm', 24, false);

				addOffset("static", 0, 0);
				addOffset("pressed", -2, -2);
				addOffset("confirm", 36, 36);

				playAnim("static");
		}

		scale.set(strumSize, strumSize);
		updateHitbox();
		scaleOffset.set(offset.x, offset.y);

		playAnim("static");

		return this;
	}

	public var animOffsets:Map<String, Array<Float>> = [];

	public function addOffset(animName, offX:Float = 0, offY:Float = 0):Void
		return animOffsets.set(animName, [offX, offY]);

	public function playAnim(animName:String, ?forced:Bool = false, ?reversed:Bool = false, ?frame:Int = 0)
	{
		animation.play(animName, forced, reversed, frame);

		if(animOffsets.exists(animName))
		{
			var daOffset = animOffsets.get(animName);
			offset.set(daOffset[0] * scale.x, daOffset[1] * scale.y);
		}
		else
			offset.set(0,0);

		// useful for pixel notes since their offsets are not 0, 0 by default
		offset.x += scaleOffset.x;
		offset.y += scaleOffset.y;
	}
}