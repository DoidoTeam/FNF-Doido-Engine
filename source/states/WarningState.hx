package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class WarningState extends MusicBeatState
{
	override public function create():Void 
	{
		super.create();
		var tex:String = "Warning!\n\n"
			+ "This is an in-development version of\n"
			+ "the engine, which is not ready for mod development.\n"
			+ "Please report any bugs to our Discord.\n\n"
			+ "Press ACCEPT to continue";
		var popUpTxt = new FlxText(0,0,0,tex);
		popUpTxt.setFormat(Main.globalFont, 36, 0xFFFFFFFF, CENTER);
		popUpTxt.screenCenter();
		add(popUpTxt);
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		if(Controls.justPressed(ACCEPT))
		{
           	Init.flagState();

            Save.data.warned = true;
            Save.save();
        }
	}
}