package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import data.GameData.MusicBeatState;

class MenuState extends MusicBeatState
{
	var optionShit:Array<String> = ["disruption", "ugh", "collision"];
	static var curSelected:Int = 1;

	var optionGroup:FlxTypedGroup<FlxSprite>;

	override function create()
	{
		super.create();
		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(80,80,80));
		bg.screenCenter();
		add(bg);

		optionGroup = new FlxTypedGroup<FlxSprite>();
		add(optionGroup);

		for(i in 0...optionShit.length)
		{
			var item:FlxText = new FlxText(0, 0, 0, optionShit[i]);
			item.setFormat(Main.gFont, 42, 0xFFFFFFFF, CENTER);
			item.x = (FlxG.width / 2) - (item.width / 2);
			item.y = 50 + ((item.height + 100) * i);
			item.ID = i; 
			optionGroup.add(item);
		}

		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(controls.justPressed("UI_UP"))
			changeSelection(-1);
		if(controls.justPressed("UI_DOWN"))
			changeSelection(1);

		if(controls.justPressed("ACCEPT"))
		{
			PlayState.SONG = data.SongData.loadFromJson(optionShit[curSelected] + "_fnf");
			Main.switchState(new PlayState());
		}
	}

	public function changeSelection(change:Int = 0)
	{
		curSelected += change;
		curSelected = FlxMath.wrap(curSelected, 0, optionShit.length - 1);

		for(item in optionGroup.members)
		{
			item.color = 0xFFFFFFFF;
			if(curSelected == item.ID)
				item.color = 0xFF000000;
		}
	}
}
