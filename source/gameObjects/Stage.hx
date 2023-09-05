package gameObjects;

import flixel.FlxG;
import flixel.FlxSprite;
//import flixel.addons.effects.FlxSkewedSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import states.PlayState;

class Stage extends FlxGroup
{
	public var curStage:String = "";

	// things to help your stage get better
	public var bfPos:FlxPoint  = new FlxPoint();
	public var dadPos:FlxPoint = new FlxPoint();
	public var gfPos:FlxPoint  = new FlxPoint();
	public var hasGf:Bool = true;

	public var foreground:FlxGroup;

	public function new() {
		super();
		foreground = new FlxGroup();
	}

	public function reloadStageFromSong(song:String = "test"):Void
	{
		switch(song.toLowerCase())
		{
			case "collision":
				reloadStage("mugen");

			default:
				reloadStage("stage");
		}
	}

	public function reloadStage(curStage:String = "")
	{
		this.clear();
		foreground.clear();
		
		gfPos.set(650, 550);
		dadPos.set(100,700);
		bfPos.set(850, 700);
		hasGf = true;
		
		this.curStage = curStage;
		switch(curStage)
		{
			case "mugen":
				PlayState.defaultCamZoom = 0.7;
				
				var bg = new FlxSprite(-640, -1000).loadGraphic(Paths.image("backgrounds/mugen/mugen"));
				add(bg);
				
				hasGf = false;
				dadPos.x -= 100;
				//gfPos.y += 80;
				
			default:
				this.curStage = "stage";
				PlayState.defaultCamZoom = 0.9;
				
				var bg = new FlxSprite(-600, -600).loadGraphic(Paths.image("backgrounds/stage/stageback"));
				bg.scrollFactor.set(0.6,0.6);
				add(bg);
				
				var front = new FlxSprite(-580, 440);
				front.loadGraphic(Paths.image("backgrounds/stage/stagefront"));
				add(front);
				
				var curtains = new FlxSprite(-600, -400).loadGraphic(Paths.image("backgrounds/stage/stagecurtains"));
				curtains.scrollFactor.set(1.4,1.4);
				add(curtains);
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
	
	public function stepHit(curStep:Int = -1)
	{
		// put your song stuff here
		
		// beat hit
		if(curStep % 4 == 0)
		{
			
		}
	}
}