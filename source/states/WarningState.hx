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
			+ "This mod features flashing lights that may\n"
			+ "be harmful to those with photosensitivity.\n"
			+ "You can disable them in the Options menu.\n\n"
			+ "Press ACCEPT to continue";
		var popUpTxt = new FlxText(0,0,0,tex);
		popUpTxt.setFormat(Main.gFont, 36, 0xFFFFFFFF, CENTER);
		popUpTxt.screenCenter();
		add(popUpTxt);
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		if(Controls.justPressed(ACCEPT))
		{
           	Init.flagState();

            FlxG.save.data.beenWarned = true;
            FlxG.save.flush();
        }
	}
}