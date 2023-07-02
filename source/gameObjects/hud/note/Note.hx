package gameObjects.hud.note;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import data.Conductor;

class Note extends FlxSprite
{
	public function new()
	{
		super();
		reloadNote(0, 0, "default");
	}

	public var noteSize:Float = 1.0;

	public function reloadNote(songTime:Float, noteData:Int, ?noteType:String = "default", ?assetModifier:String = "base"):Note
	{
		var storedPos:Array<Float> = [x, y];
		this.songTime = songTime;
		this.noteData = noteData;
		this.noteType = noteType;
		noteSize = 1.0;

		switch(assetModifier)
		{
			default:
				switch(noteType)
				{
					default:
						noteSize = 0.7;
						frames = Paths.getSparrowAtlas("notes/base/notes");

						switch(assetModifier)
						{
							case "doido":
								frames = Paths.getSparrowAtlas("notes/doido/notes");
								noteSize = 1.0;
						}

						var direc:String 	= NoteUtil.getDirection(noteData);
						var typeName:String = (isHold ? (isHoldEnd ? " hold end" : " hold") : "");

						// oxi
						animation.addByPrefix('${direc}${typeName}', 'note ${direc}${typeName}0', 24, true);

						animation.play('${direc}${typeName}');
				}
		}

		if(isHold)
			alpha = 0.8;

		scale.set(noteSize, noteSize);
		updateHitbox();

		moves = false;
		setPosition(storedPos[0], storedPos[1]);
		return this;
	}

	// you can use this to fix 
	public var noteOffset:FlxPoint = new FlxPoint(0,0);

	public var songTime:Float = 0;
	public var noteData:Int = 0;
	public var noteType:String = "default";

	// doesnt actually change the scroll speed, just changes the hold note size
	public var scrollSpeed:Float = Math.NEGATIVE_INFINITY;

	public var isHold:Bool = false;
	public var isHoldEnd:Bool = false;
	public var holdLength:Float = 0;
	public var holdHitLength:Float = 0;

	// instead of mustPress, the notes are placed by their strumlineID's
	public var strumlineID:Int = 0;

	public var canHit:Bool = true;
	public var gotHit:Bool = false;

	public var parentNote:Note = null;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	// change these to whatever you want on PlayState
	public dynamic function onHit()  {}
	public dynamic function onMiss() {}
	public dynamic function onHold() {}

	public function checkActive():Void
	{
		visible = active = alive = (Math.abs(songTime - Conductor.songPos) < Conductor.crochet * 2);

		//visible = active = alive = false;

		// making sure you dont see it anymore
		if(gotHit && !isHold)
			visible = false;
	}
}