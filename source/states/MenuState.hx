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
	var optionShit:Array<String> = ["disruption", "ugh", "collision", "lunar-odyssey"];
	static var curSelected:Int = 1;

	var optionGroup:FlxTypedGroup<Alphabet>;

	override function create()
	{
		super.create();

		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Song Selection", null);

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

		var warn = new Alphabet(0,0, "WARNING\\scores wont save for now", true);
		warn.color = 0xFFFF0000;
		warn.align = CENTER;
		warn.scale.set(0.45,0.45);
		warn.updateHitbox();
		warn.x = FlxG.width / 2;
		warn.y = FlxG.height - warn.height - 8;
		add(warn);

		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(controls.justPressed("UI_UP"))
			changeSelection(-1);
		if(controls.justPressed("UI_DOWN"))
			changeSelection(1);

		if(FlxG.keys.justPressed.O)
		{
			Main.switchState(new states.menu.OptionsState());
		}

		if(controls.justPressed("ACCEPT"))
		{
			PlayState.SONG = SongData.loadFromJson(optionShit[curSelected]);
			Main.switchState(new PlayState());
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
