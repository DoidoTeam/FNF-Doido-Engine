package objects.ui.notes;

class Note extends DoidoSprite
{
	// main data
	public var stepTime:Float = 0;
	public var noteData:Int = 0;
	
	// noteskin stuff
	public var noteScale:Float = 1.0;
	
	// modchart stuff
	public var notePath:NotePath = null;
	public var noteSpeed:Null<Float> = null;
	
	public function new()
	{
		super(-5000, -5000); // offscreen lol
	}
	
	public function loadData(stepTime:Float, noteData:Int)
	{
		path = null;
		this.stepTime = stepTime;
		this.noteData = noteData;
	}
	
	public function reloadSprite()
	{
		this.noteScale = 1.0;
		
		var direction:String = NoteUtil.intToString(noteData);
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