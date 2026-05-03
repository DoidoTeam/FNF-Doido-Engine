package states.menus;

import doido.objects.Alphabet;
import doido.song.Timings;
import doido.song.Highscore;
import doido.song.Highscore.ScoreData;
import doido.song.Week;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import objects.ui.HealthIcon;
import objects.ui.menu.DiffSelector;

typedef FreeplaySong =
{
	var name:String;
	var week:String;
	var ?icon:String;
	var ?diffs:Array<String>;
	var ?color:FlxColor;
	var ?song:Bool;
}

class FreeplayState extends MusicBeatState
{
	static var curSelected:Int = 0;
	static var curDiff:Int = -1;
	static var songFilter:Array<String> = [];

	var songs:Array<FreeplaySong> = [];
	var weeks:Array<String> = [];

	var bg:FlxSprite;
	var bgPosY:Float = 0;
	var curBGColor:Null<FlxColor> = null;
	var fallbackColor:Null<FlxColor> = null;
	var randomHue:Float = 0.0;
	var randomSaturation:Float = switch (Save.data.flashingLights)
		{
			case "OFF": 0.2;
			case "REDUCED": 0.5;
			default: 0.9;
		};

	var topBar:FlxSprite;
	var bottomBar:FlxSprite;
	var namesGrp:FlxTypedGroup<FreeplayAlphabet>;
	var diffSelector:DiffSelector;

	var titleTxt:FlxText;
	var nameTxt:FlxText;

	var scoreTxt:FlxText;
	var missesTxt:FlxText;

	var curScore:Int = 0;
	var lerpScore:Float = 0.0;
	var curAccuracy:Float = 0.0;
	var lerpAccuracy:Float = 0.0;
	var curMisses:Int = 0;
	var lerpMisses:Float = 0;

	var disableInputs:Bool = false;
	var darkMode:Bool = Save.data.darkMode;

	public function new(?weeks:Array<String>)
	{
		super();
		if (weeks != null)
			this.weeks = weeks;
		loadScript();
	}

	override function create()
	{
		super.create();
		setFpsPos(Main.fpsX, 55);
		MusicBeat.playMusic("freakyMenu");
		DiscordIO.changePresence("In the Freeplay Menu");

		bg = new FlxSprite().loadGraphic(Assets.image(darkMode ? 'menuInvert' : 'menuDesat'));
		bg.scale.set(1.2, 1.2);
		bg.updateHitbox();
		bg.screenCenter(X);
		bg.x -= 50;
		bg.setZ(0);
		add(bg);

		add(namesGrp = new FlxTypedGroup<FreeplayAlphabet>());
		namesGrp.setZ(10);

		topBar = new FlxSprite().makeColor(FlxG.width + 10, 50, 0xFF000000);
		topBar.screenCenter(X);
		topBar.setZ(100);
		add(topBar);

		bottomBar = new FlxSprite().makeColor(FlxG.width + 10, 50, 0xFF000000);
		bottomBar.screenCenter(X);
		bottomBar.y = FlxG.height - bottomBar.height;
		bottomBar.setZ(100);
		add(bottomBar);

		diffSelector = new DiffSelector(FREEPLAY);
		diffSelector.diffPos.y = 80;
		diffSelector.diffPos.x = (FlxG.width - 180);
		diffSelector.updateHitbox();
		diffSelector.arrowL.x = diffSelector.leftX;
		diffSelector.arrowR.x = diffSelector.rightX;
		diffSelector.setZ(20);
		add(diffSelector);

		titleTxt = new FlxText(8, 6, 0, "FREEPLAY");
		titleTxt.setFormat(Main.globalFont, 36, 0xFFFFFFFF, LEFT);
		titleTxt.setZ(110);
		add(titleTxt);

		nameTxt = new FlxText(8, 6, 0, "WEEK 1");
		nameTxt.setFormat(Main.globalFont, 36, 0xFFFFFFFF, RIGHT);
		nameTxt.x = FlxG.width - nameTxt.width - 6;
		nameTxt.setZ(110);
		add(nameTxt);

		scoreTxt = new FlxText(8, 8, 0, "HIGHSCORE: ");
		scoreTxt.setFormat(Main.globalFont, 36, 0xFFFFFFFF, LEFT);
		scoreTxt.y = FlxG.height - scoreTxt.height - 8;
		scoreTxt.setZ(110);
		add(scoreTxt);

		missesTxt = new FlxText(8, 8, 0, "0 MISSES");
		missesTxt.setFormat(Main.globalFont, 36, 0xFFFFFFFF, LEFT);
		missesTxt.y = FlxG.height - missesTxt.height - 6;
		missesTxt.x = FlxG.width - missesTxt.width - 6;
		missesTxt.setZ(110);
		add(missesTxt);

		callScript("createPost");
		reloadSongs();
		sort(ZIndex.sort);
	}

	public function reloadSongs()
	{
		songs = [
			{
				name: "RANDOM",
				week: "play any song",
				icon: "-",
				diffs: [],
				color: null,
				song: false
			}
		];

		var count:Int = 0;
		for (week in Week.weekList(false, true))
		{
			if (weeks.length > 0 && !weeks.contains(week.weekFile))
				continue;

			count++;
			for (song in week.songs)
			{
				songs.push({
					name: song.song,
					week: week.freeplayName,
					icon: song.icon,
					diffs: week.diffs,
					color: null,
					song: true
				});

				// preloading and adding every difficulty to RANDOM!
				for (diff in week.diffs)
				{
					if (!songs[0].diffs.contains(diff))
					{
						songs[0].diffs.push(diff);
						diffSelector.changeDiff(diff);
					}
				}
			}
		}

		if (count == 0)
		{
			weeks = [];
			reloadSongs();
			return;
		}

		callScript("reloadSongs");
		namesGrp.killMembers();
		var i = 0;
		for (song in songs)
		{
			var name:FreeplayAlphabet = namesGrp.recycle(FreeplayAlphabet);

			name.text = song.name;
			name.reloadIcon(song.icon);
			name.ID = i;
			if (song.song)
				song.color = name.icon.barColor;

			if (!namesGrp.members.contains(name))
				namesGrp.add(name);
			i++;
		}

		callScript("reloadSongsPost");
		changeSelection();
		updatePos();
	}

	public function updatePos(lerp:Float = 1)
	{
		if (callScript("updatePos", [lerp]) ?? true)
		{
			bg.y = FlxMath.lerp(bg.y, bgPosY, lerp);

			namesGrp.forEachAlive((alphabet) ->
			{
				var daPos:Int = (alphabet.ID - curSelected);

				var xOffset:Float = Math.pow(3, Math.min(Math.abs(daPos), 3)) * 10;
				var yOffset:Float = (150 * daPos);

				alphabet.setPosition(FlxMath.lerp(alphabet.x, 280 - xOffset, lerp), FlxMath.lerp(alphabet.y, (FlxG.height / 2) - 30 + yOffset, lerp));
			});
		}
	}

	public function changeSelection(?change:Int = 0)
	{
		var prevDiff = diff;
		curSelected += change;
		curSelected = FlxMath.wrap(curSelected, 0, songs.length - 1);

		if (callScript("changeSelection", [change]) ?? true)
		{
			if (change != 0)
				FlxG.sound.play(Assets.sound("scroll"));

			namesGrp.forEachAlive((alphabet) ->
			{
				if (alphabet.ID == curSelected)
					alphabet.alpha = 1.0;
				else
					alphabet.alpha = 0.4;
			});

			bgPosY = FlxMath.lerp(40, -(bg.height - FlxG.height) - 40, curSelected / (songs.length - 1));
			curBGColor = curSong.color ?? fallbackColor;
			updateBGColor();

			nameTxt.text = curSong.week.toUpperCase();
			nameTxt.x = FlxG.width - nameTxt.width - 6;
		}

		if (diff != prevDiff)
		{
			if (!curSong.diffs.contains(prevDiff))
				curDiff = middleDiff;
			else
				curDiff = curSong.diffs.indexOf(prevDiff);
		}

		changeDiff();
	}

	public function updateBGColor()
	{
		if (callScript("updateBGColor") ?? true)
		{
			FlxTween.cancelTweensOf(bg);
			if (curBGColor != null)
				FlxTween.color(bg, 0.4, bg.color, curBGColor);
		}
	}

	public function changeDiff(change:Int = 0)
	{
		var prevDiff = diff;
		if (curDiff == -1)
			curDiff = middleDiff;

		curDiff += change;
		curDiff = FlxMath.wrap(curDiff, 0, diffLength);

		if (callScript("changeDiff", [change]) ?? true)
		{
			if (change != 0 && diffLength > 0)
				FlxG.sound.play(Assets.sound('scroll'));

			diffSelector.changeDiff(diff, curDiff, diffLength, change);
			namesGrp.forEachAlive((alphabet) ->
			{
				var thisScore:ScoreData = Highscore.getScore(songs[alphabet.ID].name + '-' + songs[alphabet.ID].diffs[curDiff]);
				var rank = Timings.getRank(thisScore.accuracy, thisScore.misses, false, true);

				if (alphabet.ID == curSelected)
				{
					curScore = Math.floor(thisScore.score);
					curAccuracy = thisScore.accuracy;
					curMisses = thisScore.misses;
				}

				var color = switch (rank.toUpperCase())
				{
					case "PP": '#FFFD62';
					case "P": '#FDAAFC';
					case "S" | "S+": '#EBE9A7';
					case "A" | "A+": '#94EBEB';
					case "B" | "B+" | "C" | "C+" | "D" | "D+": '#EFA07F';
					default: '#7496FF';
				}

				alphabet.rankTxt.visible = (rank != "?");
				alphabet.rankTxt.text = '<color value=${color}>${rank}</color>';
			});
		}
	}

	var holdTimer:Float = 0.0;
	var holdMax:Float = 0.5;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!disableInputs)
		{
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

			if (Controls.justPressed(UI_LEFT))
				changeDiff(-1);
			if (Controls.justPressed(UI_RIGHT))
				changeDiff(1);

			if (Controls.justPressed(BACK))
			{
				disableInputs = true;
				FlxG.sound.play(Assets.sound('cancel'));
				MusicBeat.switchState(new states.menus.MainMenuState());
			}

			if (Controls.justPressed(ACCEPT) || FlxG.keys.justPressed.SEVEN)
				startSong();
		}

		// score
		if (Math.abs(lerpScore - curScore) <= 40)
			lerpScore = curScore;
		else
			lerpScore = FlxMath.lerp(lerpScore, curScore, elapsed * 12);

		// accuracy
		if (Math.abs(lerpAccuracy - curAccuracy) <= 1)
			lerpAccuracy = curAccuracy;
		else
			lerpAccuracy = FlxMath.lerp(lerpAccuracy, curAccuracy, elapsed * 8);

		// misses
		if (Math.abs(lerpMisses - curMisses) <= 1)
			lerpMisses = curMisses;
		else
			lerpMisses = FlxMath.lerp(lerpMisses, curMisses, elapsed * 6);

		if (scoreTxt != null && scoreTxt.visible)
		{
			// drawing score + accuracy
			var scoreText = 'HIGHSCORE: ' + FlxStringUtil.formatMoney(Math.floor(lerpScore), false, true);
			scoreText += ' [${FlxMath.roundDecimal(lerpAccuracy, 2)}%]';
			if (scoreTxt.text != scoreText)
				scoreTxt.text = scoreText;
		}

		if (scoreTxt != null && scoreTxt.visible)
		{
			// drawing misses
			var missesText = Math.floor(lerpMisses) + ' MISSES';
			if (missesTxt.text != missesText)
			{
				missesTxt.text = missesText;
				missesTxt.x = FlxG.width - missesTxt.width - 8;
			}
		}

		if (curBGColor == null)
		{
			randomHue += elapsed * 60 * 5;
			randomHue %= 360;
			bg.color = FlxColor.interpolate(bg.color, FlxColor.fromHSB(randomHue, randomSaturation, 1.0), elapsed * 8);
		}

		updatePos(elapsed * 8);
		callScript("updatePost", [elapsed]);
	}

	public function startSong()
	{
		if (curSong.name.toLowerCase() == "random")
		{
			var possibleList:Array<Int> = [];
			for (i in 0...songs.length)
			{
				var song = songs[i];
				if (song.diffs.contains(curSong.diffs[curDiff]) && song != curSong)
					possibleList.push(i);
			}
			FlxG.random.shuffle(possibleList);
			changeSelection(FlxG.random.getObject(possibleList));
		}

		try
		{
			PlayState.loadSong(curSong.name, curSong.diffs[curDiff]);

			if (FlxG.keys.justPressed.SEVEN)
			{
				MusicBeat.switchState(new states.editors.ChartingState(PlayState.SONG));
				return;
			}
		}
		catch (e)
		{
			FlxG.sound.play(Assets.sound('cancel'));
			Logs.print(e);
			return;
		}

		disableInputs = true;
		if (callScript("startSong") ?? true)
		{
			FlxG.sound.play(Assets.sound('confirm'));
			namesGrp.forEachAlive((alphabet) ->
			{
				if (alphabet.ID == curSelected)
				{
					alphabet.icon.setAnim(2);
					FlxTween.flicker(alphabet, 1.2, 0.1);
				}
				else
				{
					alphabet.icon.setAnim(0);
					FlxTween.tween(alphabet, {alpha: 0}, 0.4);
				}
			});

			new FlxTimer().start(1.2, (tmr) ->
			{
				if (FlxG.keys.pressed.SHIFT)
					PlayState.startPos = 50000;

				MusicBeat.stopMusic();
				MusicBeat.switchState(new states.LoadingState());
			});
		}
	}

	var curSong(get, never):FreeplaySong;
	var diff(get, never):String;
	var middleDiff(get, never):Int;
	var diffLength(get, never):Int;

	function get_curSong():FreeplaySong
		return songs[curSelected];

	function get_diff():String
		return curSong.diffs[curDiff] ?? 'normal';

	function get_middleDiff()
		return Std.int((curSong.diffs.length - 1) / 2);

	function get_diffLength()
		return curSong.diffs.length - 1;
}

class FreeplayAlphabet extends Alphabet
{
	public var icon:HealthIcon;
	public var rankTxt:Alphabet;

	public var iconPos:DoidoPoint = {x: 0, y: 0};
	public var rankPos:DoidoPoint = {x: 16, y: 0};

	public function new()
	{
		super(0, 0, "", true);
		icon = new HealthIcon();
		icon.setIcon();
		rankTxt = new Alphabet(0, 0, "", true);
		rankTxt.scale.set(1.15, 1.15);
		rankTxt.updateHitbox();
	}

	public function reloadIcon(name:String)
	{
		if (name == "-")
		{
			icon.visible = false;
		}
		else
		{
			icon.visible = true;
			icon.setIcon(name);
		}
	}

	override function draw()
	{
		if (icon.visible)
		{
			icon.alpha = alpha;
			icon.setPosition(x - icon.width + iconPos.x, y + ((height - icon.height) / 2) + iconPos.y);
			icon.draw();
		}
		if (rankTxt.visible)
		{
			rankTxt.alpha = alpha;
			rankTxt.forEachAlive((letter) ->
			{
				letter.alpha = alpha;
			});
			rankTxt.setPosition(x + width + rankPos.x, y + ((height - rankTxt.height) / 2) + rankPos.y);
			rankTxt.draw();
		}
		super.draw();
	}
}
