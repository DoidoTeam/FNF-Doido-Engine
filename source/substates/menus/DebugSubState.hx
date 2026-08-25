package substates.menus;

import states.editors.InputTestState;
import doido.objects.ui.DoidoRadio;
import doido.objects.ui.PsychUIDropDownMenu;
import states.ScriptedState;
import states.menus.StoryMenuState;
import states.editors.ChartingState;
import states.PlayState;
import doido.objects.ui.DoidoInputText;
import flixel.text.FlxBitmapText;
import states.editors.CharacterEditor;
import substates.editors.PopupSubState;
import doido.objects.ui.window.DoidoChooser.ChooserWindow;
import doido.objects.ui.buttons.DoidoTextButton;
import doido.system.CrashHandler;
import flixel.FlxSprite;
import doido.objects.Alphabet;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import states.menus.MainMenuState.MenuOption;

// NOTE: This menu is still a little rough around the edges
// i'll get to organizing / fixing eventually but for now
// it does the job pretty well...
class DebugSubState extends MusicBeatSubState
{
	public var bg:FlxSprite;
	public var displayGrp:FlxTypedGroup<Alphabet>;

	public final enabledColor:FlxColor = FlxColor.WHITE;
	public final disabledColor:FlxColor = FlxColor.WHITE.getDarkened(0.6);

	var curSelected:Int = 0;
	var options:Array<MenuOption> = [];

	public var width:Float = 0;
	public var height:Float = 0;
	public var padding:Int = 32;

	public var realX:Float = 0;
	public var realY:Float = 0;

	public function new()
	{
		super();
		FlxG.mouse.visible = true;
		FlxG.sound.play(Assets.sound("options/options-open"));

		#if MODS_FOLDER
		addOption("manage mods", () -> openSubState(new substates.menus.ModSubState(this, bg.width, bg.height)));
		#end
		addOption("chart editor", chartEditor);
		addOption("character editor", characterEditor);
		addOption("week editor", () -> MusicBeat.switchState(new StoryMenuState(true)));
		addOption("scripted state", scriptedState);
		addOption("input test", () -> MusicBeat.switchState(new InputTestState()));

		displayGrp = new FlxTypedGroup<Alphabet>();
		for (i in 0...options.length)
		{
			var disp = new Alphabet(0, 0, options[i].name, true, LEFT);
			disp.scale.set(0.9, 0.9);
			disp.updateHitbox();
			disp.ID = i;
			displayGrp.add(disp);

			width = Math.max(width, disp.width + (padding * 2));
			height += padding + disp.height;
		}

		bg = new FlxSprite().makeColor(width, height, 0xFF000000);
		bg.screenCenter();
		bg.alpha = 0.8;

		realX = bg.x;
		realY = bg.y;
		bg.scale.x = 0;
		bg.scale.y = 0;
		bg.screenCenter();

		add(bg);
		add(displayGrp);

		positionBg(0);
		positionOptions();
		changeSelection();
	}

	public function chartEditor()
	{
		var newSong:String = "bopeebo";
		var newDiff:String = "hard";

		function createText(x:Float = 0, y:Float = 0, text:String = "", color:FlxColor = 0xFFFFFFFF):FlxBitmapText
		{
			var newText = new FlxBitmapText(x, y, Assets.bitmapFont("phantommuff"));
			newText.alignment = LEFT;
			newText.text = text;
			newText.color = color;
			newText.scale.set(0.625, 0.625);
			newText.updateHitbox();
			return newText;
		}

		var openStuff:Array<FlxBasic> = [];
		openStuff.push(createText((FlxG.width / 2) - (145) - 5, (FlxG.height / 2) - 22 - 5, "Song:", 0xFFD8DAF6));
		openStuff.push(createText((FlxG.width / 2) + 5, (FlxG.height / 2) - 22 - 5, "Diff:", 0xFFD8DAF6));

		var songField:DoidoInputText;
		songField = new DoidoInputText((FlxG.width / 2) - (145) - 5, (FlxG.height / 2) - 5, 145, newSong);
		songField.onTextChange.add((cur, input) -> newSong = cur);
		openStuff.push(songField);

		var diffField:DoidoInputText;
		diffField = new DoidoInputText((FlxG.width / 2) + 5, (FlxG.height / 2) - 5, 145, newDiff);
		diffField.onTextChange.add((cur, input) -> newDiff = cur);
		openStuff.push(diffField);

		var ok = new DoidoTextButton("Ok", "small");
		ok.screenCenter();
		ok.y += 50;
		openStuff.push(ok);

		var popup = new PopupSubState("Open Song:", 320, 150, openStuff);
		openSubState(popup);

		ok.button.onUp.add(() ->
		{
			try
			{
				PlayState.loadSong(newSong, newDiff);
				MusicBeat.switchState(new ChartingState(PlayState.SONG));
			}
			catch (e)
			{
				FlxG.sound.play(Assets.sound('beep'));
				Logs.print(e);
			}
		});
	}

	public function characterEditor()
	{
		var openStuff:Array<FlxBasic> = [];
		var selected:String = "";
		var characters:Array<String> = Assets.list("data/characters/", true, JSON).concat(["face"]);

		var ok = new DoidoTextButton("Open", "small");
		ok.screenCenter();
		ok.x -= (ok.width / 2) + 5;
		ok.y += 142;
		openStuff.push(ok);

		var reload = new DoidoTextButton("Reload", "small");
		reload.screenCenter();
		reload.x += (reload.width / 2) + 5;
		reload.y += 142;
		openStuff.push(reload);

		var savewindow:ChooserWindow = new ChooserWindow((FlxG.width / 2) - (440 / 2), (FlxG.height / 2) - (240 / 2) - 10, 440, 245, [], null);
		savewindow.view = GRID;
		savewindow.type = CHARACTER;
		savewindow.options = characters;
		openStuff.push(savewindow);

		var popup = new PopupSubState("Open: NONE", 480, 340, openStuff, false);
		openSubState(popup);

		ok.button.onUp.add(() ->
		{
			if (selected == "")
				FlxG.sound.play(Assets.sound('beep'));
			else
				MusicBeat.switchState(new CharacterEditor(selected, false, false));
		});

		reload.button.onUp.add(() ->
		{
			#if MODS_FOLDER
			Mods.reloadMods();
			#end
			characters = Assets.list("data/characters/", true, JSON).concat(["face"]);
			savewindow.options = characters;
		});

		savewindow.onClick = (str) ->
		{
			selected = str;
			popup.titleText.text = 'Open: ${selected}';
			trace(selected);
		};
	}

	public function scriptedState()
	{
		var newState:String = "";
		var subState:Bool = false;

		function createText(x:Float = 0, y:Float = 0, text:String = "", color:FlxColor = 0xFFFFFFFF):FlxBitmapText
		{
			var newText = new FlxBitmapText(x, y, Assets.bitmapFont("phantommuff"));
			newText.alignment = LEFT;
			newText.text = text;
			newText.color = color;
			newText.scale.set(0.625, 0.625);
			newText.updateHitbox();
			return newText;
		}

		var openStuff:Array<FlxBasic> = [];
		openStuff.push(createText((FlxG.width / 2) - (145) - 5, (FlxG.height / 2) - 22 - 5, "Script:", 0xFFD8DAF6));

		var stateField:DoidoInputText;
		stateField = new DoidoInputText((FlxG.width / 2) - (145) - 5, (FlxG.height / 2) - 5, 145 + 30, newState);
		stateField.onTextChange.add((cur, input) -> newState = cur);
		openStuff.push(stateField);

		var radio = new DoidoRadio(["State", "SubState"], 0, (cur) ->
		{
			subState = cur == 1;
		});
		radio.x = (FlxG.width / 2) + 5 + 30;
		radio.y = (FlxG.height / 2) - 22 - 5;
		openStuff.push(radio);

		/*var sub = new PsychUIDropDownMenu((FlxG.width / 2) + 5, (FlxG.height / 2) - 5, ["State", "SubState"], (i, s) ->
			{
				subState = s == "SubState";
			}, 145, false);
			openStuff.push(sub); */

		var ok = new DoidoTextButton("Ok", "small");
		ok.screenCenter();
		ok.y += 50;
		openStuff.push(ok);

		var popup = new PopupSubState("Open State:", 320, 150, openStuff);
		openSubState(popup);

		ok.button.onUp.add(() ->
		{
			if (Assets.fileExists('data/scripts/${subState ? 'substates' : 'states'}/$newState', SCRIPT))
			{
				if (subState)
					openSubState(new ScriptedSubState(newState));
				else
					MusicBeat.switchState(new ScriptedState(newState));
			}
			else
			{
				FlxG.sound.play(Assets.sound('beep'));
				Logs.print('STATE NOT FOUND: $newState', WARNING);
			}
		});
	}

	override function create()
	{
		super.create();
		persistentDraw = false;
	}

	public function positionBg(elapsed:Float)
	{
		bg.scale.set(FlxMath.lerp(bg.scale.x, width, elapsed * 8), FlxMath.lerp(bg.scale.y, height, elapsed * 8));
		bg.updateHitbox();
		bg.screenCenter();
	}

	public function positionOptions()
	{
		displayGrp.forEachAlive((disp) ->
		{
			disp.screenCenter(X);
			disp.y = realY + (padding / 2) + (padding + disp.height) * disp.ID;
		});
	}

	var holdTimer:Float = 0.0;
	var holdMax:Float = 0.5;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (Controls.justPressed(BACK))
		{
			FlxG.sound.play(Assets.sound("options/options-close"));
			FlxG.mouse.visible = false;
			close();
		}

		var change:Int = (Controls.pressed(UI_DOWN) ? 1 : 0) - (Controls.pressed(UI_UP) ? 1 : 0);
		if (change != 0)
			holdTimer += elapsed;
		else
			holdTimer = 0.0;
		if (Controls.justPressed(UI_UP) || Controls.justPressed(UI_DOWN) || holdTimer >= holdMax)
		{
			changeSelection(change);
			if (holdTimer >= holdMax)
				holdTimer = holdMax - 0.12;
		}

		if (Controls.justPressed(ACCEPT))
			options[curSelected].press();

		positionBg(elapsed);
	}

	public function changeSelection(?change:Int = 0)
	{
		if (change != 0)
			FlxG.sound.play(Assets.sound("scroll"));

		curSelected += change;
		curSelected = FlxMath.wrap(curSelected, 0, options.length - 1);

		displayGrp.forEachAlive((disp) ->
		{
			disp.color = (disp.ID == curSelected ? enabledColor : disabledColor);
		});
	}

	public function addOption(name:String, press:Void->Void, ?pos:Int)
	{
		var option:MenuOption = {name: name, press: press};
		if (pos == null)
			options.push(option);
		else
			options.insert(pos, option);
	}

	public function removeOption(name:String)
	{
		var opt:MenuOption = null;
		for (option in options)
		{
			if (option.name == name)
			{
				opt = option;
				break;
			}
		}
		if (opt != null)
			options.remove(opt);
	}

	public function moveOption(name:String, pos:Int)
	{
		var opt:MenuOption = null;
		for (option in options)
		{
			if (option.name == name)
			{
				opt = option;
				break;
			}
		}
		if (opt != null)
			options.remove(opt);
		addOption(opt.name, opt.press, pos);
	}

	override function draw()
	{
		function check(obj:FlxBasic)
		{
			if (obj == null)
				return;

			if (Std.isOfType(obj, FlxSpriteGroup))
			{
				var grp:FlxSpriteGroup = cast obj;
				grp.forEach((member) -> check(member));
			}
			else if (Std.isOfType(obj, FlxGroup))
			{
				var grp:FlxGroup = cast obj;
				grp.forEach((member) -> check(member));
			}
			else if (Std.isOfType(obj, FlxSprite))
				setClip(cast obj, bg);
		}

		check(displayGrp);

		// for (obj in objects)
		//	check(obj);

		// setClip(closeButton, bg);
		// setClip(titleText, bg);

		super.draw();
	}

	function setClip(sprite:FlxSprite, bg:FlxSprite)
	{
		var newx:Float = bg.x - sprite.x;
		var newy:Float = bg.y - sprite.y;
		var newwidth:Float = (bg.x + bg.width - sprite.x) - newx;
		var newheight:Float = (bg.y + bg.height - sprite.y) - newy;
		sprite.clipRect = new FlxRect(newx / sprite.scale.x, newy / sprite.scale.y, newwidth / sprite.scale.x, newheight / sprite.scale.y);
	}
}
