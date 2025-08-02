package objects.note;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import backend.song.Conductor;

class Note extends FlxSprite
{
	public function new()
	{
		super();
		moves = false;
	}

	public var noteSize:Float = 1.0;
	public var assetModifier:String = "base";
	public var hasHoldSplash:Bool = true;

	public function updateData(songTime:Float, noteData:Int, ?noteType:String = "default", ?assetModifier:String = "base")
	{
		this.songTime = initialSongTime = songTime;
		this.noteData = noteData;
		this.noteType = noteType;
		this.assetModifier = assetModifier;
	}
	
	public function reloadSprite():Note
	{
		noteSize = 1.0;
		mustMiss = false;
		hasHoldSplash = true;
		var direction:String = CoolUtil.getDirection(noteData);
		antialiasing = FlxSprite.defaultAntialiasing;
		isPixelSprite = false;
		setAlpha();

		switch(assetModifier)
		{
			case "pixel":
				noteSize = 6;
				hasHoldSplash = true;
				if(!isHold)
				{
					loadGraphic(Paths.image("notes/pixel/notesPixel"), true, 17, 17);

					animation.add(direction, [noteData + 4], 0, false);
				}
				else
				{
					loadGraphic(Paths.image("notes/pixel/notesEnds"), true, 7, 6);

					animation.add(direction, [noteData + (isHoldEnd ? 4 : 0)], 0, false);
				}
				antialiasing = false;
				isPixelSprite = true;
				animation.play(direction);

			default:
				switch(noteType)
				{
					default:
						switch(assetModifier)
						{
							case "doido":
								frames = Paths.getSparrowAtlas("notes/doido/notes");
								noteSize = 0.95;
							default:
								noteSize = 0.7;
								frames = Paths.getSparrowAtlas("notes/base/notes");
						}

						var typeName:String = (isHold ? (isHoldEnd ? " hold end" : " hold") : "");

						// oxi
						animation.addByPrefix('${direction}${typeName}', 'note ${direction}${typeName}0', 24, true);

						animation.play('${direction}${typeName}');
				}
		}

		switch(noteType)
		{
			case "bomb":
				mustMiss = true;
				if(!isHold)
				{
					noteSize = 0.95;
					frames = Paths.getSparrowAtlas("notes/doido/bomb");
					animation.addByPrefix('bomb', 'bomb', 0, false);
					animation.play('bomb');
				}
				else
					color = 0xFF000000;
				
			case "EX Note"|"hurt note":
				var fold:String = 'base';
				if(assetModifier == 'doido')
					fold = 'doido';
				
				mustMiss = true;
				noteSize = ((fold == 'doido') ? 0.95 : 0.7);
				frames = Paths.getSparrowAtlas('notes/$fold/hurt_notes');
				var typeName:String = (isHold ? (isHoldEnd ? "hold end" : "hold0") : 'note $direction');
				
				animation.addByPrefix('hurt', '$typeName', 0, false);
				animation.play('hurt');
			
			case "Shoot Note"|"warn note":
				noteSize = 0.7;
				noteType = "warn note";
				frames = Paths.getSparrowAtlas('notes/base/warn_notes');
				var typeName:String = (isHold ? (isHoldEnd ? "hold end" : "hold0") : 'note $direction');
				
				animation.addByPrefix('warn', '$typeName', 0, false);
				animation.play('warn');
		}

		scale.set(noteSize, noteSize);
		updateHitbox();

		return this;
	}

	// you can use this to fix 
	public var noteOffset:FlxPoint = new FlxPoint(0,0);
	
	public var noteAngle:Float = 0;
	
	public var initialSongTime:Float = 0;
	public var songTime:Float = 0;
	public var noteData:Int = 0;
	public var noteType:String = "default";

	public function setSongOffset():Void
		songTime = initialSongTime + Conductor.musicOffset;

	public function noteDiff():Float
		return songTime + Conductor.inputOffset - Conductor.songPos;

	// in case you want to avoid notes this will do
	public var mustMiss:Bool = false;
	
	// doesnt actually change the scroll speed, just changes the hold note size
	public var scrollSpeed:Float = Math.NEGATIVE_INFINITY;
	
	// hold note stuff
	public var noteCrochet:Float = 0;
	public var isHold:Bool = false;
	public var isHoldEnd:Bool = false;
	public var holdLength:Float = 0;
	public var holdHitLength:Float = 0;

	// reusing this for clipRect later
	public var holdClipHeight:Float = 0.0;
	
	public var children:Array<Note> = [];
	public var parentNote:Note = null;

	// instead of mustPress, the strumline is determined by their strumlineID's
	public var strumlineID:Int = 0;
	
	public var missed:Bool = false;
	public var gotHit:Bool = false;
	public var gotHeld:Bool = false;
	public var gotReleased:Bool = false;
	
	public var spawned:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
	
	public var realAlpha:Float = 1;
	public function setAlpha():Void
	{
		var multAlpha:Float = 1;
		if(isHold)
			multAlpha = (gotHit ? 0.2 : 0.7);
		if(missed)
			multAlpha = 0.2;
		
		// change realAlpha instead of alpha for this effect
		alpha = realAlpha * multAlpha;
	}

	public function checkActive():Void
	{
		visible = active = alive = (Math.abs(songTime - Conductor.songPos) < Conductor.crochet * 2);

		// making sure you dont see it anymore
		if(gotHit && !isHold)
			visible = false;
	}
	
	// sets (probably) every value the note has to the default value
	public function resetNote()
	{
		visible = true;
		missed = false;
		gotHit = false;
		gotHeld = false;
		gotReleased = false;
		holdHitLength = 0;
		//spawned = false;
		
		clipRect = null;
		setAlpha();
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}
}
