package gameObjects.hud.note;

import flixel.FlxG;
import flixel.FlxSprite;

class SplashNote extends FlxSprite
{
	public function new()
	{
		super();
		visible = false;
	}

	public var assetModifier:String = "";
	public var noteType:String = "";
	public var noteData:Int = 0;

	public function reloadSplash(note:Note)
	{
		var direction:String = CoolUtil.getDirection(note.noteData);

		assetModifier = note.assetModifier;
		noteType = note.noteType;
		noteData = note.noteData;
		
		switch(note.assetModifier)
		{
			case 'doido':
				frames = Paths.getSparrowAtlas('notes/doido/splashes');
				animation.addByPrefix('splash', '$direction splash', 24, false);
				scale.set(0.95,0.95);
				updateHitbox();
			
			case "pixel":
				var frameArr:Array<Int> = [0, 1, 2, 3, 4, 5];
				for(i in 0...frameArr.length) {
					frameArr[i] *= 4;
					frameArr[i] += noteData;
				}
				
				loadGraphic(Paths.image('notes/pixel/splashesPixel'), true, 33, 33);
				for(i in 0...2)
					animation.add('splash$i', frameArr, 24, false, (i == 1));
				scale.set(6,6);
				updateHitbox();
				isPixelSprite = true;
				
			default:
				frames = Paths.getSparrowAtlas("notes/base/splashes");
				
				animation.addByPrefix("splash1", '$direction splash 1', 24, false);
				animation.addByPrefix("splash2", '$direction splash 2', 24, false);
				
				scale.set(0.7,0.7);
				updateHitbox();
		}

		if(isPixelSprite)
			antialiasing = false;

		playAnim();
		visible = false;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(animation.finished)
			visible = false;
	}

	// plays a random animation
	public function playAnim()
	{
		visible = true;
		var animList = animation.getNameList();
		animation.play(animList[FlxG.random.int(0, animList.length - 1)], true, false, 0);
	}
}