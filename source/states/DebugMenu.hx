package states;

import doido.Mods;
import doido.song.Highscore;
import doido.song.Highscore.ScoreData;
import doido.objects.Alphabet;
import doido.song.Week.WeekData;
import doido.Cache;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID as FlxPad;
import haxe.Json;
import openfl.media.Sound;
import states.editors.ChartingState;
import doido.song.Week;
import doido.song.Timings;
import flixel.util.FlxStringUtil;
import states.editors.*;

using doido.utils.TextUtil;

class DebugMenu extends MusicBeatState
{
	var options:Array<String> = [
		"Story Mode",
		"Freeplay",
		"Controls",
		"Options",
		"Credits",
		"Main Menu",
		#if MODS_FOLDER
		"Mods",
		#end
		#if !mobile "Character Editor", "Crash Handler", "Scripted State" #end
	];
	var text:FlxText;
	var title:FlxText;
	var ver:FlxText;
	var cur:Int = 0;

	override function create()
	{
		super.create();
		MusicBeat.playMusic("freakyMenu");
		DiscordIO.changePresence("In the Main Menu");

		var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		bg.screenCenter();
		add(bg);

		var doidoText = "<wave intensity=10 speed=3>DOIDO</wave> <shake intensity=2 speed=10><color value=#FF0000>ENGINE</color></shake>";
		doidoText += "\n<rainbow speed=6 offset=8><wave intensity=15 speed=20>PUDIM</wave></rainbow>";

		var alphabet = new Alphabet(FlxG.width / 2, 50, doidoText, true, CENTER);
		add(alphabet);

		text = new FlxText(10, 0, 0, '');
		text.setFormat(Main.globalFont, 48, 0xFFFFFFFF, LEFT);
		text.setOutline(0xFF000000, 3);
		add(text);
		drawText();
		text.y = FlxG.height - text.height - 10;

		title = new FlxText(10, 0, 0, 'DE-Pudim');
		title.setFormat(Main.globalFont, 100, 0xFFFFFFFF, LEFT);
		title.setOutline(0xFF000000, 5);
		title.y = text.y - title.height;
		add(title);

		ver = new FlxText(10, 0, 0, Main.internalVer);
		ver.setFormat(Main.globalFont, 32, 0xFFFFFFFF, LEFT);
		ver.setOutline(0xFF000000, 2.5);
		ver.x = title.x + title.width + 5;
		ver.y = text.y - ver.height;
		add(ver);

		// zindex test...
		var bg2 = new FlxSprite().loadGraphic(Assets.image('menuDesat'));
		bg2.zIndex = -1;
		add(bg2);

		sort(ZIndex.sort);
	}

	function drawText()
	{
		text.text = "";
		for (i in 0...options.length)
			text.text += (i == cur ? "> " : "") + options[i] + "\n";
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (Controls.justPressed(UI_UP))
			changeSelection(-1);
		if (Controls.justPressed(UI_DOWN))
			changeSelection(1);

		if (Controls.justPressed(ACCEPT))
		{
			switch (options[cur].toLowerCase())
			{
				case "options":
					openSubState(new substates.menus.OptionsSubState());
				case "popup":
					openSubState(new substates.editors.PopupSubState());
				case "controls":
					MusicBeat.switchState(new DebugControls());
				case "crash handler":
					null.draw();
				case "credits":
					MusicBeat.switchState(new states.menus.CreditsState());
				case "character editor":
					MusicBeat.switchState(new CharacterEditor("face", FlxG.keys.pressed.SHIFT));
				case "main menu":
					MusicBeat.switchState(new states.menus.MainMenuState());
				case "story mode":
					/*var week:WeekData = {
							songs: [{song: "bopeebo"}, {song: "fresh"}, {song: "dadbattle"}]
						};
						PlayState.loadWeek(week, "hard"); */
					MusicBeat.switchState(new states.menus.StoryMenuState());
				case "scripted state":
					MusicBeat.switchState(new ScriptedState("test"));
				#if MODS_FOLDER
				case "mods":
					MusicBeat.switchState(new ModManager());
				#end
				default:
					MusicBeat.switchState(new states.menus.FreeplayState());
			}
		}
	}

	public function changeSelection(change:Int = 0)
	{
		if (change != 0)
			FlxG.sound.play(Assets.sound('scroll'));

		cur += change;
		cur = FlxMath.wrap(cur, 0, options.length - 1);
		drawText();
	}
}

typedef FreeplaySong =
{
	var name:String;
	var ?icon:String;
	var ?diffs:Array<String>;
}

class Freeplay extends MusicBeatState
{
	var options:Array<FreeplaySong> = [];
	var text:FlxText;
	var title:FlxText;
	var score:FlxText;
	var curSong:Int = 0;
	var curDiff:Int = 1;

	override function create()
	{
		super.create();
		MusicBeat.playMusic("freakyMenu");
		DiscordIO.changePresence("In the Freeplay Menu");

		for (week in Week.weekList(false, true))
		{
			for (song in week.songs)
			{
				options.push({
					name: song.song,
					icon: song.icon,
					diffs: week.diffs,
				});
			}
		}

		#if !mobile
		// options.push({name: "Load Other"});
		#end

		var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		bg.screenCenter();
		add(bg);

		text = new FlxText(10, 0, 0, '');
		text.setFormat(Main.globalFont, 48, 0xFFFFFFFF, LEFT);
		text.setOutline(0xFF000000, 3);
		add(text);
		drawText();
		text.y = FlxG.height - text.height - 10;

		title = new FlxText(10, 0, 0, 'Freeplay');
		title.setFormat(Main.globalFont, 100, 0xFFFFFFFF, LEFT);
		title.setOutline(0xFF000000, 5);
		title.y = text.y - title.height;
		add(title);

		score = new FlxText(10, 10, 0, "");
		score.setFormat(Main.globalFont, 36, 0xFFFFFFFF, RIGHT);
		score.setOutline(0xFF000000, 2);
		score.alpha = 1;
		add(score);
		drawScore();
	}

	function drawText()
	{
		text.text = "";
		for (i in 0...options.length)
			text.text += (i == curSong ? "> " : "") + options[i].name + "\n";
	}

	function drawScore()
	{
		var newscore:ScoreData = Highscore.getScore(options[curSong].name + '-' + options[curSong].diffs[curDiff]);
		var rank = Timings.getRank(newscore.accuracy, newscore.misses, false, true);
		score.text = "";
		if (options[curSong].name == "Load Other")
			return;
		score.text += "SCORE: " + FlxStringUtil.formatMoney(Math.floor(newscore.score), false, true);
		score.text += "\nACCURACY: " + (Math.floor(newscore.accuracy * 100) / 100) + "%" + ' [$rank]';
		score.text += "\nMISSES: " + Math.floor(newscore.misses);
		score.text += '\n< ${options[curSong].diffs[curDiff].toUpperCase()} >';
		score.x = FlxG.width - score.width - 10;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (Controls.justPressed(UI_UP))
			changeSelection(-1);
		if (Controls.justPressed(UI_DOWN))
			changeSelection(1);
		if (Controls.justPressed(UI_LEFT))
			changeDiff(-1);
		if (Controls.justPressed(UI_RIGHT))
			changeDiff(1);

		if (Controls.justPressed(BACK))
			MusicBeat.switchState(new states.DebugMenu());

		if (Controls.justPressed(ACCEPT) || FlxG.keys.justPressed.SHIFT || FlxG.keys.justPressed.SEVEN)
		{
			try
			{
				PlayState.loadSong(options[curSong].name, options[curSong].diffs[curDiff]);

				if (FlxG.keys.justPressed.SEVEN)
				{
					MusicBeat.switchState(new ChartingState(PlayState.SONG));
				}
				else
				{
					if (FlxG.keys.justPressed.SHIFT)
						PlayState.startPos = 50000;

					MusicBeat.stopMusic();
					MusicBeat.switchState(new states.LoadingState());
				}
			}
			catch (e)
			{
				FlxG.sound.play(Assets.sound('beep'));
				Logs.print(e);
			}
		}
	}

	public function changeSelection(change:Int = 0)
	{
		if (change != 0)
			FlxG.sound.play(Assets.sound('scroll'));

		curSong += change;
		curSong = FlxMath.wrap(curSong, 0, options.length - 1);
		drawText();
		changeDiff();
		drawScore();
	}

	public function changeDiff(change:Int = 0)
	{
		if (options[curSong].name == "Load Other")
			return;

		curDiff += change;

		var maxDiff:Int = options[curSong].diffs.length - 1;
		if (change == 0)
			curDiff = Math.floor(FlxMath.bound(curDiff, 0, maxDiff));
		else
			curDiff = FlxMath.wrap(curDiff, 0, maxDiff);

		drawScore();
	}
}

#if MODS_FOLDER
class ModManager extends MusicBeatState
{
	var text:FlxText;
	var title:FlxText;
	var ver:FlxText;
	var cur:Int = 0;
	var options:Array<String> = [];
	var reordering:Bool = false;

	override function create()
	{
		super.create();
		MusicBeat.playMusic("freakyMenu");
		DiscordIO.changePresence("In the Mod Manager");

		var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		bg.screenCenter();
		add(bg);

		text = new FlxText(10, 0, 0, '');
		text.setFormat(Main.globalFont, 48, 0xFFFFFFFF, LEFT);
		text.setOutline(0xFF000000, 3);
		add(text);

		title = new FlxText(10, 0, 0, 'Mods');
		title.setFormat(Main.globalFont, 100, 0xFFFFFFFF, LEFT);
		title.setOutline(0xFF000000, 5);
		add(title);

		ver = new FlxText(10, 0, 0, "Hold Shift to Reorder");
		ver.setFormat(Main.globalFont, 32, 0xFFFFFFFF, LEFT);
		ver.setOutline(0xFF000000, 2.5);
		ver.x = title.x + title.width + 5;
		add(ver);

		updateList();
		drawText();
	}

	function updateList()
	{
		options = [];
		for (mod in Mods.modList.mods)
			options.push(mod.name + ' - ' + mod.enabled);
		options.push("Reload List");
	}

	function drawText()
	{
		text.text = "";
		for (i in 0...options.length)
			text.text += (i == cur ? "> " : "") + options[i] + "\n";
		text.y = FlxG.height - text.height - 10;
		title.y = text.y - title.height;
		ver.y = text.y - ver.height;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (Controls.justPressed(UI_UP))
			changeSelection(-1);
		if (Controls.justPressed(UI_DOWN))
			changeSelection(1);

		if (Controls.justPressed(BACK))
			MusicBeat.switchState(new states.menus.MainMenuState());

		if (Controls.justPressed(ACCEPT))
		{
			if (options[cur] == "Reload List")
				Mods.scan();
			else
			{
				var mod = Mods.modList.mods[cur];
				Mods.setMod(mod.name, !mod.enabled, true);
			}

			updateList();
			drawText();
			changeSelection();
		}

		reordering = FlxG.keys.pressed.SHIFT;
	}

	public function changeSelection(change:Int = 0)
	{
		if (change != 0)
			FlxG.sound.play(Assets.sound('scroll'));

		if (reordering && cur != 0 && options[cur] != "Reload List")
		{
			Mods.move(cur, change);
			updateList();
		}

		cur += change;
		cur = FlxMath.wrap(cur, 0, options.length - 1);
		drawText();
	}
}
#end

class DebugControls extends MusicBeatState
{
	public static var pad:Bool = false;

	var options:Array<DoidoKey> = [];
	var text:FlxText;
	var title:FlxText;
	var curV:Int = 0;
	var curH:Int = 0;

	override function create()
	{
		super.create();
		MusicBeat.playMusic("freakyMenu");
		DiscordIO.changePresence("In the Controls Menu");
		var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		bg.screenCenter();
		add(bg);

		for (label => key in Controls.bindMap)
		{
			if (key.rebindable)
				options.push(label);
		}

		text = new FlxText(10, 0, 0, '');
		text.setFormat(Main.globalFont, 48, 0xFFFFFFFF, LEFT);
		text.setOutline(0xFF000000, 3);
		add(text);
		drawText();
		text.y = FlxG.height - text.height - 10;

		title = new FlxText(10, 0, 0, 'Controls');
		title.setFormat(Main.globalFont, 100, 0xFFFFFFFF, LEFT);
		title.setOutline(0xFF000000, 5);
		title.y = text.y - title.height;
		add(title);
	}

	function drawText()
	{
		text.text = "";
		for (i in 0...options.length)
		{
			var name:String = (cast options[i]).toUpperCase();
			var bind0:String = "";
			var bind1:String = "";

			if (pad)
			{
				bind0 = Controls.bindMap.get(options[i]).gamepad[0].toString();
				bind1 = Controls.bindMap.get(options[i]).gamepad[1].toString();
			}
			else
			{
				bind0 = Controls.bindMap.get(options[i]).keyboard[0].toString();
				bind1 = Controls.bindMap.get(options[i]).keyboard[1].toString();
			}

			bind0 = '${curH == 0 && curV == i ? "> " : ""}${Controls.formatKey(bind0, pad)}${curH == 0 && curV == i ? " <" : ""}';
			bind1 = '${curH == 1 && curV == i ? "> " : ""}${Controls.formatKey(bind1, pad)}${curH == 1 && curV == i ? " <" : ""}';

			text.text += '$name $bind0 $bind1\n';
		}

		// um bonus bem grande assim
		var name:String = "DEVICE";
		var bind0:String = "KEYBOARD";
		var bind1:String = "GAMEPAD";

		if (curV == options.length)
		{
			if (curH == 0)
				bind0 = '> $bind0 <';
			else
				bind1 = '> $bind1 <';
		}

		text.text += '$name $bind0 $bind1\n';
	}

	var waitingInput:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (waitingInput)
		{
			if (pad && FlxG.gamepads.lastActive.justPressed.ANY)
			{
				waitingInput = false;
				var daKey:FlxPad = FlxG.gamepads.lastActive.firstJustPressedID();

				if (FlxG.gamepads.lastActive.analog.value.LEFT_STICK_X < 0)
					daKey = FlxPad.LEFT_STICK_DIGITAL_LEFT;
				if (FlxG.gamepads.lastActive.analog.value.LEFT_STICK_X > 0)
					daKey = FlxPad.LEFT_STICK_DIGITAL_RIGHT;
				if (FlxG.gamepads.lastActive.analog.value.LEFT_STICK_Y < 0)
					daKey = FlxPad.LEFT_STICK_DIGITAL_UP;
				if (FlxG.gamepads.lastActive.analog.value.LEFT_STICK_Y > 0)
					daKey = FlxPad.LEFT_STICK_DIGITAL_DOWN;

				if (FlxG.gamepads.lastActive.analog.value.RIGHT_STICK_X < 0)
					daKey = FlxPad.RIGHT_STICK_DIGITAL_LEFT;
				if (FlxG.gamepads.lastActive.analog.value.RIGHT_STICK_X > 0)
					daKey = FlxPad.RIGHT_STICK_DIGITAL_RIGHT;
				if (FlxG.gamepads.lastActive.analog.value.RIGHT_STICK_Y < 0)
					daKey = FlxPad.RIGHT_STICK_DIGITAL_UP;
				if (FlxG.gamepads.lastActive.analog.value.RIGHT_STICK_Y > 0)
					daKey = FlxPad.RIGHT_STICK_DIGITAL_DOWN;

				Controls.bindMap.get(options[curV]).gamepad[curH] = daKey;
				Controls.save();
				drawText();
			}
			else if (FlxG.keys.justPressed.ANY)
			{
				waitingInput = false;
				var daKey:FlxKey = FlxG.keys.firstJustPressed();
				Controls.bindMap.get(options[curV]).keyboard[curH] = daKey;
				Controls.save();
				drawText();
			}
		}
		else
		{
			if (Controls.justPressed(UI_UP))
				changeSelection(-1);
			if (Controls.justPressed(UI_DOWN))
				changeSelection(1);
			if (Controls.justPressed(UI_LEFT))
				changeBind(-1);
			if (Controls.justPressed(UI_RIGHT))
				changeBind(1);

			if (Controls.justPressed(ACCEPT))
			{
				if (curV == options.length)
				{
					pad = curH == 1;
					MusicBeat.switchState(new DebugControls());
				}
				else
					waitingInput = true;
			}
			if (Controls.justPressed(BACK))
				MusicBeat.switchState(new states.DebugMenu());
		}
	}

	public function changeSelection(change:Int = 0)
	{
		if (change != 0)
			FlxG.sound.play(Assets.sound('scroll'));

		curV += change;
		curV = FlxMath.wrap(curV, 0, options.length);
		drawText();
	}

	public function changeBind(change:Int = 0)
	{
		if (change != 0)
			FlxG.sound.play(Assets.sound('scroll'));

		curH += change;
		curH = FlxMath.wrap(curH, 0, 1);
		drawText();
	}
}
