package substates;

import substates.menus.OptionsSubState;
import doido.objects.Alphabet;
import states.PlayState;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class PauseSubState extends MusicBeatSubState
{
	var options:Array<String> = ["Resume", "Restart Song", "Options", "Practice Mode", "Botplay", "Exit To Menu"];
	var optionText:Array<Alphabet> = [];
	var curSelected:Int = 0;

	var gamepadDisconnected:Bool = false;
	var gamepadBG:FlxSprite;
	var gamepadWarning1:Alphabet;
	var gamepadWarning2:Alphabet;

	var metadata:Array<FlxText> = [];
	var title:FlxText;
	var creditsText:FlxText;
	var diffText:FlxText;
	var blueballText:FlxText;
	var bottomTxt:FlxText;

	public function new(?gamepadDisconnected:Bool = false)
	{
		super();
		this.gamepadDisconnected = gamepadDisconnected;
		persistentUpdate = false;
		persistentDraw = true;

		var bg = new FlxSprite().makeColor(FlxG.width + 10, FlxG.height + 10, 0xFF000000);
		bg.alpha = 0.4;
		add(bg);

		// i hope this wont break anything
		/*if (PlayState.instance.startedSong)
			options.insert(3, "Options"); */

		for (i in 0...options.length)
		{
			var option = new Alphabet(40, 0, options[i], true);
			option.y = FlxMath.lerp(120, FlxG.height - 90 - option.height, i / (options.length - 1));
			optionText.push(option);
			option.ID = i;
			add(option);
		}

		var textPadding:Int = 35;

		// add the song title
		title = new FlxText(10, 8, 0, TextUtil.titleCase(PlayState.CHART.song));
		title.setFormat(Main.globalFont, 36, 0xFFFFFFFF, RIGHT);
		title.setOutline(0xFF000000, 2);
		title.x = FlxG.width - title.width - 10;
		metadata.push(title);

		//  add the credits text
		creditsText = new FlxText(10, title.y + textPadding, 0, "");
		creditsText.setFormat(Main.globalFont, 36, 0xFFFFFFFF, RIGHT);
		creditsText.setOutline(0xFF000000, 2);
		creditsText.alpha = 1;
		metadata.push(creditsText);

		diffText = new FlxText(10, creditsText.y + textPadding, 0, 'Difficulty: ${TextUtil.titleCase(PlayState.songDiff)}');
		diffText.setFormat(Main.globalFont, 36, 0xFFFFFFFF, RIGHT);
		diffText.setOutline(0xFF000000, 2);
		diffText.alpha = 1;
		diffText.x = FlxG.width - diffText.width - 10;
		metadata.push(diffText);

		blueballText = new FlxText(10, diffText.y + textPadding, 0, 'Blueballed: ${PlayState.blueballed}');
		blueballText.setFormat(Main.globalFont, 36, 0xFFFFFFFF, RIGHT);
		blueballText.setOutline(0xFF000000, 2);
		blueballText.alpha = 1;
		blueballText.x = FlxG.width - blueballText.width - 10;
		metadata.push(blueballText);

		bottomTxt = new FlxText(0, 0, 0, "BOTPLAY");
		bottomTxt.setFormat(Main.globalFont, 36, 0xFFFFFFFF, RIGHT);
		bottomTxt.setOutline(0xFF000000, 2);
		bottomTxt.y = FlxG.height - bottomTxt.height - 10;
		add(bottomTxt);

		addMeta();
		changeSelection();
		drawCreditsText();
		drawBottom();
		creditsFade();

		if (gamepadDisconnected)
		{
			gamepadBG = new FlxSprite().makeColor(FlxG.width + 10, FlxG.height + 10, 0xFF000000);
			gamepadBG.alpha = 0.9;
			add(gamepadBG);

			gamepadWarning1 = new Alphabet(FlxG.width / 2, 0, '<color value=#FF2020>GAMEPAD DISCONNECTED</color>', false);
			gamepadWarning1.align = CENTER;
			gamepadWarning1.y = (FlxG.height - gamepadWarning1.height) / 2 - 80;
			add(gamepadWarning1);

			gamepadWarning2 = new Alphabet(FlxG.width / 2, 0, '<color value=#FFFFFF>press a key to resume the game</color>', false);
			gamepadWarning2.scale.set(0.6, 0.6);
			gamepadWarning2.updateHitbox();
			gamepadWarning2.align = CENTER;
			gamepadWarning2.y = gamepadWarning1.y + gamepadWarning1.height + 8;
			add(gamepadWarning2);

			FlxG.sound.play(Assets.sound('crash'));
		}
	}

	function addMeta()
	{
		var delay = 0.0;
		for (text in metadata)
		{
			text.alpha = 0;
			text.x -= 5;
			FlxTween.tween(text, {alpha: 1, y: text.y + 5}, 1.2, {ease: FlxEase.quartOut, startDelay: delay});
			add(text);
			delay += 0.1;
		}
	}

	var curSelectedCredit:Int = 0;
	var creditsTween:FlxTween;
	var fadeDelay:Float = 6;
	var fadeDuration:Float = 0.75;

	function drawCreditsText()
	{
		creditsText.text = (curSelectedCredit == 0 ? 'Composer: ' + PlayState.META.composer + "\n" : 'Charter: ' + PlayState.META.charter + "\n");

		creditsText.x = FlxG.width - (creditsText.width + 12);

		curSelectedCredit++;
		curSelectedCredit = FlxMath.wrap(curSelectedCredit, 0, 1);
	}

	function creditsFade()
	{
		creditsTween = FlxTween.tween(creditsText, {alpha: 0.0}, fadeDuration, {
			startDelay: fadeDelay,
			ease: FlxEase.quartOut,
			onComplete: (_) ->
			{
				drawCreditsText();
				FlxTween.tween(creditsText, {alpha: 1.0}, fadeDuration, {
					ease: FlxEase.quartOut,
					onComplete: (_) ->
					{
						creditsFade();
					}
				});
			}
		});
	}

	function drawBottom()
	{
		bottomTxt.text = PlayState.instance.botplay ? "BOTPLAY" : (PlayState.instance.practice ? "PRACTICE" : "");
		bottomTxt.x = FlxG.width - bottomTxt.width - 10;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (gamepadDisconnected)
		{
			if (FlxG.keys.justPressed.ANY || FlxG.gamepads?.lastActive?.justPressed.ANY)
			{
				gamepadDisconnected = false;
				FlxG.sound.play(Assets.sound('cancel'));
				for(item in [gamepadBG, gamepadWarning1, gamepadWarning2])
				{
					remove(item);
					item.destroy();
				}
			}
		}
		else
		{
			if (Controls.justPressed(UI_UP))
				changeSelection(-1);

			if (Controls.justPressed(UI_DOWN))
				changeSelection(1);

			if (Controls.justPressed(ACCEPT))
			{
				switch (options[curSelected].toLowerCase())
				{
					case 'resume':
						close();

					case 'restart song':
						MusicBeat.skip = true;
						MusicBeat.switchState(new states.PlayState());

					case 'botplay':
						FlxG.sound.play(Assets.sound("cancel"));
						PlayState.instance.botplay = !PlayState.instance.botplay;
						PlayState.instance.practice = false;
						drawBottom();

					case 'practice mode':
						FlxG.sound.play(Assets.sound("cancel"));
						PlayState.instance.practice = !PlayState.instance.practice;
						PlayState.instance.botplay = false;
						drawBottom();

					case 'options':
						openSubState(new OptionsSubState(PlayState.instance));

					case 'exit to menu':
						PlayState.instance.goToMenu();

					default:
						FlxG.sound.play(Assets.sound("cancel"));
				}
			}

			if (Controls.justPressed(BACK))
				close();
		}
	}

	override function close()
	{
		PlayState.instance.unpauseSong();
		super.close();
	}

	public function changeSelection(change:Int = 0)
	{
		if (change != 0)
			FlxG.sound.play(Assets.sound('scroll'));

		curSelected += change;
		curSelected = FlxMath.wrap(curSelected, 0, options.length - 1);

		for (text in optionText)
		{
			FlxTween.completeTweensOf(text);
			if (text.ID == curSelected)
			{
				text.alpha = 1.0;
				text.x += 40;
				FlxTween.tween(text, {x: text.x - 40}, 0.2, {
					ease: FlxEase.sineInOut
				});
			}
			else
				text.alpha = 0.7;
		}
	}
}
