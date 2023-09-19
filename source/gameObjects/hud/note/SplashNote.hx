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

	/*
	**	these are used so each note gets their own splash
	**	but if that splash already exists, then it spawns
	**	the same splash, so there are not
	** 	8204+ splashes created each song
	*/
	public static var existentModifiers:Array<String> = [];
	public static var existentTypes:Array<String> = [];

	public static function resetStatics()
	{
		existentModifiers = [];
		existentTypes = [];
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
				
			default:
				frames = Paths.getSparrowAtlas("notes/base/splashes");
				
				animation.addByPrefix("splash1", '$direction splash 1', 24, false);
				animation.addByPrefix("splash2", '$direction splash 2', 24, false);
				
				scale.set(0.7,0.7);
				updateHitbox();
		}

		playAnim();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(animation.finished)
		{
			visible = false;
		}
	}

	// plays a random animation
	public function playAnim()
	{
		visible = true;
		var animList = animation.getNameList();
		animation.play(animList[FlxG.random.int(0, animList.length - 1)], true, false, 0);
	}
}