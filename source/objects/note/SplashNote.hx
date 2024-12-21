package objects.note;

import flixel.FlxSprite;
import backend.song.Timings;

class SplashNote extends FlxSprite
{
	public var isHold:Bool = false;
	public var holdNote:Note = null;
	public var holdStrum:StrumNote = null;

	public var startAlpha:Float = 1.0;
	public final endAlpha:Float = 0.0001;

	public function new(?isHold:Bool = false)
	{
		super();
		alpha = endAlpha;
		this.isHold = isHold;
	}

	public var direction:String = "";

	public var assetModifier:String = "";
	public var noteType:String = "";
	public var noteData:Int = 0;

	public function updateData(note:Note)
	{
		direction = CoolUtil.getDirection(note.noteData);
		assetModifier = note.assetModifier;
		noteType = note.noteType;
		noteData = note.noteData;
		if(!isHold)
			reloadSplash();
		else
		{
			holdNote = note;
			reloadHoldSplash();
		}
	}

	public function reloadSplash()
	{
		isPixelSprite = false;
		switch(assetModifier)
		{
			case 'doido':
				frames = Paths.getSparrowAtlas('notes/doido/splashes');
				animation.addByPrefix("splash", '$direction splash', 24, false);
				scale.set(0.95,0.95);

			case "pixel":
				var frameArr:Array<Int> = [0, 1, 2, 3, 4, 5];
				for(i in 0...frameArr.length) {
					frameArr[i] *= 4;
					frameArr[i] += noteData;
				}
				
				loadGraphic(Paths.image('notes/pixel/splashesPixel'), true, 33, 33);
				for(i in 0...2)
					animation.add('splash$i', frameArr, 18, false, (i == 1));
				scale.set(6,6);
				isPixelSprite = true;
				
			default:
				frames = Paths.getSparrowAtlas("notes/base/splashes");
				
				animation.addByPrefix("splash1", '$direction splash 1', 24, false);
				animation.addByPrefix("splash2", '$direction splash 2', 24, false);
				
				scale.set(0.7,0.7);
		}
		updateHitbox();

		if(isPixelSprite)
			antialiasing = false;

		playRandom();
		alpha = endAlpha;
	}
	
	public function reloadHoldSplash()
	{
		isPixelSprite = false;
		switch(assetModifier)
		{
			case "pixel":
				function getArr(arr:Array<Int>):Array<Int>
				{
					var format:Array<Int> = [];
					for(i in 0...arr.length)
						format[i] = (arr[i] * 4) + noteData;
					return format;
				}
				var anims:Map<String, Array<Int>> = [
					"start" => getArr([0]),
					"loop"	=> getArr([1,2,3]),
					"splash"=> getArr([4,5,6,7,8]),
				];
				loadGraphic(Paths.image('notes/pixel/holdSplashesPixel'), true, 33, 33);
				for(anim => frameArr in anims)
					animation.add(anim, frameArr, 18, (anim == "loop"));
				scale.set(6,6);
				isPixelSprite = true;

			default:
				switch(assetModifier)
				{
					case "doido":
						frames = Paths.getSparrowAtlas('notes/doido/holdSplashes');
						scale.set(0.95,0.95);
					default:
						frames = Paths.getSparrowAtlas('notes/base/holdSplashes');
						scale.set(0.7,0.7);
				}
				direction = direction.toUpperCase();
				animation.addByPrefix("start", 	'holdCoverStart$direction', 24, false);
				animation.addByPrefix("loop",  	'holdCover$direction', 		24, true);
				animation.addByPrefix("splash",	'holdCoverEnd$direction', 	24, false);

				if(assetModifier == "doido")
					addOffset("splash", -16, -10);
				else
				{
					for(anim in ["start", "loop", "splash"])
						addOffset(anim, 6, -28);
				}
		}
		updateHitbox();

		if(isPixelSprite)
			antialiasing = false;

		playAnim("start");
		alpha = startAlpha;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(!isHold)
		{
			if(animation.finished)
				alpha = endAlpha;
		}
		else
		{
			// only follows the strum if its not splashing
			if(animation.curAnim.name != "splash")
				setPosition(holdStrum.x, holdStrum.y);

			var holdPercent = (holdNote.holdHitLength / holdNote.holdLength);
			if(holdStrum.animation.curAnim.name != "confirm" || holdPercent >= 1.0)
			{
				if(animation.curAnim.name != "splash")
				{
					playAnim("splash");
					if(holdPercent < Timings.holdTimings[0][0])
						alpha = endAlpha;
				}
			}
			
			if(animation.finished)
			{
				switch(animation.curAnim.name)
				{
					case "start": playAnim('loop');
					case "splash": alpha = endAlpha;
				}
			}
			if(alpha <= endAlpha)
				destroy();
		}
	}

	// plays a random animation, useful for common splashes
	public function playRandom()
	{
		alpha = startAlpha;
		var animList = animation.getNameList();
		playAnim(animList[FlxG.random.int(0, animList.length - 1)], true);
	}

	// not necessary on most cases, but base game's hold covers were acting weird so yeah...
	public var animOffsets:Map<String, Array<Float>> = [];
	public function addOffset(animName:String, offsetX:Float, offsetY:Float) {
		animOffsets.set(animName, [offsetX, offsetY]);
	}

	public function playAnim(animName:String, forced:Bool = true, frame:Int = 0)
	{
		animation.play(animName, forced, false, frame);
		updateHitbox();
		offset.x += frameWidth * scale.x / 2;
		offset.y += frameHeight* scale.y / 2;
		if(animOffsets.exists(animName))
		{
			var daOffset = animOffsets.get(animName);
			offset.x += daOffset[0];
			offset.y += daOffset[1];
		}
	}
}
