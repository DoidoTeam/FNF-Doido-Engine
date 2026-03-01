package objects.ui.notes;

import flixel.FlxSprite;

class Note extends FlxSprite
{
	// main data
	public var data:NoteData;
	public var gotHit:Bool = false;
	public var missed:Bool = false;

	public var holdParent:Note = null;
	public var children:Array<Note> = [];
	// hold data
	public var isHold:Bool = false;
	public var isHoldEnd:Bool = false;
	public var holdIndex:Float = -1;
	public var holdStep:Float = -1;
	public var holdHitPercent:Float = 0.0;
	
	// noteskin stuff
	public var noteScale:Float = 1.0;
	
	// modchart stuff
	public var noteAngle:Null<Float> = null;
	public var noteSpeed:Null<Float> = null;
	public var noteSpeedMult:Float = 1.0;
	
	public function new()
	{
		super();
	}
	
	public function loadData(data:NoteData)
	{
		setPosition(-5000, -5000); // offscreen lol
		visible = true;

		this.data = data;
		gotHit = false;
		missed = false;
		alpha = 1.0;
		angle = 0;

		holdParent = null;
		children = [];
		
		isHold = isHoldEnd = false;
		holdIndex = 0;
		holdStep = 0;
		
		//noteSpeed = (FlxG.random.bool(50) ? null : 1.0);
	}
	
	public function reloadSprite()
	{
		clipRect = null;
		noteScale = 1.0;
		
		var direction:String = NoteUtil.intToString(data.lane);
		switch("i told you ill do the skins later")
		{
			default:
				var postfix:String = (isHold ? " hold" + (isHoldEnd ? " end" : "") : "");

				this.loadSparrow("notes/base/notes");
				animation.addByPrefix(direction, 'note ${direction}${postfix}0', 0, false);
				noteScale = 0.7;
		}
		
		scale.set(noteScale, noteScale);
		updateHitbox();
		animation.play(direction);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public function updateOffsets()
	{
		updateHitbox();
		offset.x += frameWidth * scale.x / 2;
		if(isHold)
		{
			offset.y = 0;
			origin.y = 0;
		}
		else
			offset.y += frameHeight * scale.y / 2;
	}
}