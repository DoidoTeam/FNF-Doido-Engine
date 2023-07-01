package gameObjects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import states.PlayState;

class Stage extends FlxGroup
{
	public var curStage:String = "";

	public var foreground:FlxGroup;

	public function new() {
		super();
		foreground = new FlxGroup();
	}

	public function reloadStage(curStage:String = "")
	{
		this.clear();
		foreground.clear();

		this.curStage = curStage;
		switch(curStage)
		{
			default:
				PlayState.defaultCamZoom = 0.9;

				var bg = new FlxSprite(-600, -600).loadGraphic(Paths.image("backgrounds/stage/stageback"));
				bg.scrollFactor.set(0.6,0.6);
				add(bg);

				var front = new FlxSprite(-580, 440).loadGraphic(Paths.image("backgrounds/stage/stagefront"));
				add(front);

				var curtains = new FlxSprite(-600, -400).loadGraphic(Paths.image("backgrounds/stage/stagecurtains"));
				curtains.scrollFactor.set(1.4,1.4);
				add(curtains);
		}
	}

	
}