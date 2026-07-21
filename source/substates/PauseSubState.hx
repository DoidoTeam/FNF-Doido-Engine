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
	var options:Array<String> = ["Resume", "Restart Song", "Options", "Botplay", "Exit To Menu"];
	var optionText:Array<Alphabet> = [];
	var title:FlxText;
	var creditsText:FlxText;
	var botplayTxt:FlxText;
	var curSelected:Int = 0;

	public function new()
	{
		super();
		persistentUpdate = false;
		persistentDraw = true;

		var bg = new FlxSprite().makeColor(FlxG.width + 10, FlxG.height + 10, 0xFF000000);
		bg.alpha = 0.4;
		add(bg);

		if (true) // difficultyList.length > 0 or something like that
			options.insert(2, "Change Difficulty");

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

		// add the song title
		title = new FlxText(10, 10, 0, PlayState.CHART.song);
		title.setFormat(Main.globalFont, 36, 0xFFFFFFFF, RIGHT);
		title.setOutline(0xFF000000, 2);
		title.x = FlxG.width - title.width - 10;
		add(title);

		//  add the credits text
		creditsText = new FlxText(10, title.y + 30, 0, "");
		creditsText.setFormat(Main.globalFont, 36, 0xFFFFFFFF, RIGHT);
		creditsText.setOutline(0xFF000000, 2);
		creditsText.alpha = 1;
		add(creditsText);

		botplayTxt = new FlxText(0, 0, 0, "BOTPLAY");
		botplayTxt.setFormat(Main.globalFont, 36, 0xFFFFFFFF, RIGHT);
		botplayTxt.x = FlxG.width - botplayTxt.width - 10;
		botplayTxt.y = FlxG.height - botplayTxt.height - 10;
		botplayTxt.visible = PlayState.instance.botplay;
		add(botplayTxt);

		changeSelection();
		drawCreditsText();
		creditsFade();
	}

	var curSelectedCredit:Int = 0;

	function drawCreditsText()
	{
		creditsText.text = (curSelectedCredit == 0 ? 'Composer: ' + PlayState.META.composer + "\n" : 'Charter: ' + PlayState.META.charter + "\n");

		creditsText.x = FlxG.width - (creditsText.width + 12);

		curSelectedCredit++;
		curSelectedCredit = FlxMath.wrap(curSelectedCredit, 0, 1);
	}

	var creditsTween:FlxTween;
	var fadeDelay:Float = 5;
	var fadeDuration:Float = 0.75;

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

	override function update(elapsed:Float)
	{
		super.update(elapsed);

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
					botplayTxt.visible = PlayState.instance.botplay;
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
