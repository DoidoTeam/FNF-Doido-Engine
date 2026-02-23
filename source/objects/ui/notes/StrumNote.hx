package objects.ui.notes;

import flixel.math.FlxPoint;

class StrumNote extends DoidoSprite
{
	public var lane:Int = 0;
		
	public var initialPos:FlxPoint = FlxPoint.get(0, 0);
	public var strumScale:Float = 1.0;
	public var strumAngle:Float = 0.0;
	
	public function new()
	{
		super();
	}
	
	public function reloadStrum(lane:Int)
	{
		this.lane = lane;
		this.strumScale = 1.0;
		
		var direction:String = NoteUtil.intToString(lane);
		
		switch("ill do it later")
		{
			default:
				this.loadSparrow("notes/base/strums");
				for (anim in ["static", "pressed", "confirm"]) {
					animation.addByPrefix(anim, 'strum $direction $anim', 24, false);
				}
				strumScale = 0.7;
		}
		
		scale.set(strumScale, strumScale);
		updateHitbox();
		playAnim("static");
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