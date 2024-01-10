package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import data.GameData.MusicBeatState;
import flixel.text.FlxText;
import flixel.system.FlxSound;

class WarningState extends MusicBeatState
{
	override public function create():Void 
	{
		super.create();

        var color = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
		color.screenCenter();
		add(color);

		var tex:String = "Warning!\n\nThis mod features flashing lights that may\nbe harmful to those with photosensitivity.\nYou can disable them in the Options menu.\n\nPress ENTER to continue!";
		var popUpTxt = new FlxText(0,0,0,tex);
		popUpTxt.setFormat(Main.gFont, 43, 0xFFFFFFFF, CENTER);
		popUpTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 2.5);
		popUpTxt.screenCenter();
		add(popUpTxt);
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);

		if (Controls.justPressed("ACCEPT")) {
            Main.switchState(new states.TitleState());

            FlxG.save.data.firstBoot = true;
            FlxG.save.flush();
        }
	}
}