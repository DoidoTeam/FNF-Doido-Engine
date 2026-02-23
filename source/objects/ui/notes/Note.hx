package objects.ui.notes;

class Note extends DoidoSprite
{
	// main data
	public var data:NoteData;
	public var gotHit:Bool = false;
	public var missed:Bool = false;
	
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
		this.data = data;
		visible = true;
		gotHit = false;
		missed = false;
		alpha = 1.0;

		//noteSpeed = (FlxG.random.bool(50) ? null : 1.0);
	}
	
	public function reloadSprite()
	{
		this.noteScale = 1.0;
		
		var direction:String = NoteUtil.intToString(data.lane);
		switch("i told you ill do the skins later")
		{
			default:
				this.loadSparrow("notes/base/notes");
				animation.addByPrefix(direction, 'note ${direction}0', 0, false);
				noteScale = 0.7;
		}
		
		scale.set(noteScale, noteScale);
		updateHitbox();
		playAnim(direction);
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