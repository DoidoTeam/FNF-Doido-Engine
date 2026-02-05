package objects.doido;

import animate.FlxAnimate;

class DoidoSprite extends FlxAnimate
{
	public var curAnimName:String = '';
	public var curAnimFrame(get, never):Int;
	public var curAnimFinished(get, never):Bool;
	public var animOffsets:Map<String, Array<Float>> = [];
	
	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
	};
	
	public function addOffset(animName:String, offsetX:Float, offsetY:Float) {
		animOffsets.set(animName, [offsetX, offsetY]);
	}

	public function playAnim(animName:String, forced:Bool = true, frame:Int = 0)
	{
		if (!animExists(animName)) return;
		animation.play(animName, forced, false, frame);
		curAnimName = animName;
		
		updateOffset();
	}
	
	// use this to modify the sprite's origin
	public function preUpdateOffset()
	{
		offset.set(0, 0);
	}
	
	public function updateOffset()
	{
		preUpdateOffset();
		if(animOffsets.exists(curAnimName))
		{
			var daOffset = animOffsets.get(curAnimName);
			offset.x += daOffset[0] * scale.x;
			offset.y += daOffset[1] * scale.y;
		}
	}

	public function animExists(animName:String):Bool
		return (animation.getByName(animName) != null);

	public function get_curAnimFrame():Int
		return animation.curAnim.curFrame;

	public function get_curAnimFinished():Bool
		return animation.curAnim.finished;
}