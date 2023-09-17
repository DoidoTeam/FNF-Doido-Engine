package states;

import data.Discord.DiscordClient;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import data.GameData.MusicBeatState;
import data.SongData;
import gameObjects.menu.Alphabet;
import gameObjects.menu.Alphabet.AlphabetAlign;

using StringTools;

class MenuState extends MusicBeatState
{
	var optionShit:Array<String> = ["story mode", "freeplay", "options"];
	static var curSelected:Int = 0;

	var optionGroup:FlxTypedGroup<Alphabet>;

	override function create()
	{
		super.create();
		CoolUtil.playMusic("freakyMenu");

		// Updating Discord Rich Presence
		DiscordClient.changePresence("Main Menu", null);

		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(80,80,80));
		bg.screenCenter();
		add(bg);

		optionGroup = new FlxTypedGroup<Alphabet>();
		add(optionGroup);

		for(i in 0...optionShit.length)
		{
			var item = new Alphabet(0,0, "nah", false);
			item.align = CENTER;
			item.text = optionShit[i].toUpperCase();
			item.x = FlxG.width / 2;
			item.y = 50 + ((item.height + 100) * i);
			item.ID = i;
			optionGroup.add(item);
		}

		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(Controls.justPressed("UI_UP"))
			changeSelection(-1);
		if(Controls.justPressed("UI_DOWN"))
			changeSelection(1);
		
		if(Controls.justPressed("BACK"))
			Main.switchState(new TitleState());

		if(Controls.justPressed("ACCEPT"))
		{
			switch(optionShit[curSelected])
			{
				case "story mode":
					Main.switchState(new states.menu.StoryMenuState());
			
				case "freeplay":
					Main.switchState(new states.menu.FreeplayState());

				case "options":
					Main.switchState(new states.menu.OptionsState());
			}
		}
	}

	public function changeSelection(change:Int = 0)
	{
		curSelected += change;
		curSelected = FlxMath.wrap(curSelected, 0, optionShit.length - 1);

		for(item in optionGroup.members)
		{
			var daText:String = optionShit[item.ID].toUpperCase().replace("-", " ");

			var daBold = (curSelected == item.ID);

			if(item.bold != daBold)
			{
				item.bold = daBold;
				if(daBold)
					item.text = '> ' + daText + ' <';
				else
					item.text = daText;
				item.x = FlxG.width / 2;
			}
		}
	}
}
