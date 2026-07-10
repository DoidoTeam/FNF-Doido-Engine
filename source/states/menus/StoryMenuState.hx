package states.menus;

import substates.editors.WeekEditorSubState;
import objects.Character;
import doido.song.Highscore;
import doido.song.Week;
import flixel.math.FlxMath;
import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import objects.ui.menu.DiffSelector;

class StoryMenuState extends MusicBeatState
{
	static var curWeek:Int = 0;
	static var curDiff:Int = -1;

	var weekList:Array<WeekData> = [];

	var realScore:Float = 0;
	var lerpedScore:Float = 0;

	var topBar:FlxSprite;
	var charBg:FlxSprite;

	var grpChars:FlxTypedGroup<StoryChar>;
	var grpWeeks:FlxTypedGroup<WeekTitle>;
	var diffSelector:DiffSelector;

	var trackTitle:FlxText;
	var trackTxt:FlxText;
	var weekNameTxt:FlxText;
	var weekScoreTxt:FlxText;

	// var resetTxt:FlxText;

	override function create()
	{
		super.create();
		setFpsPos(Main.fpsX, 55);
		MusicBeat.playMusic("freakyMenu");
		DiscordIO.changePresence("In the Story Menu");
		weekList = Week.weekList(true, false);
		persistentDraw = true;
		persistentUpdate = true;

		grpWeeks = new FlxTypedGroup<WeekTitle>();
		add(grpWeeks);

		for (i in 0...weekList.length)
			grpWeeks.add(new WeekTitle(weekList[i].weekFile, i, curWeek));

		topBar = new FlxSprite(0, 0).makeColor(FlxG.width + 10, 60, 0xFF000000);
		topBar.screenCenter(X);
		add(topBar);

		charBg = new FlxSprite(0, 50).makeColor(FlxG.width + 10, 392, 0xFFFFFFFF);
		charBg.color = 0xFFF9CF51;
		charBg.screenCenter(X);
		add(charBg);

		weekScoreTxt = new FlxText(8, 8, 0, "WEEK SCORE: 0");
		weekScoreTxt.setFormat(Main.globalFont, 36, 0xFFFFFFFF, LEFT);
		add(weekScoreTxt);

		weekNameTxt = new FlxText(8, 8, 0, "");
		weekNameTxt.setFormat(Main.globalFont, 36, 0xFFFFFFFF, RIGHT);
		weekNameTxt.alpha = 0.8;
		add(weekNameTxt);

		trackTitle = new FlxText(0, 0, 0, "TRACKS");
		trackTitle.setFormat(Main.globalFont, 48, 0xFFE55777, CENTER);
		trackTitle.setPosition(200 - trackTitle.width / 2, charBg.y + charBg.height + 20);
		add(trackTitle);

		trackTxt = new FlxText(0, 0, 0, "what the hell");
		trackTxt.setFormat(Main.globalFont, 36, 0xFFE55777, CENTER);
		trackTxt.y = (trackTitle.y + trackTitle.height + 12);
		add(trackTxt);

		diffSelector = new DiffSelector(STORY);
		diffSelector.diffPos.y = charBg.y + charBg.height + 30; // 20
		diffSelector.diffPos.x = (FlxG.width - 215);
		diffSelector.updateHitbox();
		diffSelector.arrowL.x = diffSelector.leftX;
		diffSelector.arrowR.x = diffSelector.rightX;
		add(diffSelector);

		grpChars = new FlxTypedGroup<StoryChar>();
		add(grpChars);

		var posits:Array<StoryCharPos> = [DAD, BF, GF];
		for (i in 0...posits.length)
		{
			var char = new StoryChar(posits[i]);
			char.ID = i;
			grpChars.add(char);
		}

		if (curDiff == -1)
			curDiff = middleDiff;

		preload();
		changeWeek();
	}

	function preload()
	{
		var diffs:Array<String> = [];
		var chars:Array<String> = [];
		for (week in weekList)
		{
			for (diff in week.storyDiffs)
			{
				if (!diffs.contains(diff))
				{
					diffSelector.changeDiff(diff);
					diffs.push(diff);
				}
			}

			for (char in week.chars)
			{
				if (!chars.contains(char) && char != "")
				{
					grpChars.members[0].reloadChar(char);
					chars.push(char);
				}
			}
		}
	}

	var canSelect = true;

	var holdTimer:Float = 0.0;
	var holdMax:Float = 0.5;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (canSelect && subState == null)
		{
			var change:Int = (Controls.pressed(UI_DOWN) ? 1 : 0) - (Controls.pressed(UI_UP) ? 1 : 0);
			if (change != 0)
				holdTimer += elapsed;
			else
				holdTimer = 0.0;
			if (Controls.justPressed(UI_UP) || Controls.justPressed(UI_DOWN) || holdTimer >= holdMax)
			{
				changeWeek(change);
				if (holdTimer >= holdMax)
					holdTimer = holdMax - 0.12;
			}

			if (Controls.justPressed(UI_LEFT))
				changeDiff(-1);
			if (Controls.justPressed(UI_RIGHT))
				changeDiff(1);

			diffSelector.arrowL.animation.play(Controls.pressed(UI_LEFT) ? "push" : "idle");
			diffSelector.arrowR.animation.play(Controls.pressed(UI_RIGHT) ? "push" : "idle");

			if (Controls.justPressed(BACK))
			{
				canSelect = false;
				FlxG.sound.play(Assets.sound('cancel'));
				MusicBeat.switchState(new states.menus.MainMenuState());
			}

			if (Controls.justPressed(ACCEPT) && canSelect)
				startWeek();

			if (Save.data.developerMode && FlxG.keys.justPressed.SEVEN)
				openSubState(new WeekEditorSubState(week, this));
		}

		for (week in grpWeeks.members)
		{
			var weekPos = 402 + 60 + (week.ID - curWeek) * 120;

			if (week.y != weekPos)
				week.y = FlxMath.lerp(week.y, weekPos, elapsed * 12);
		}

		if (lerpedScore != realScore)
		{
			lerpedScore = FlxMath.lerp(lerpedScore, realScore, elapsed * 8);
			weekScoreTxt.text = "WEEK SCORE: " + FlxStringUtil.formatMoney(Math.floor(lerpedScore), false, true);
		}
	}

	public function startWeek()
	{
		try
		{
			PlayState.loadWeek(week, diff);
		}
		catch (e)
		{
			FlxG.sound.play(Assets.sound('beep'));
			Logs.print(e);
			return;
		}

		canSelect = false;
		FlxG.sound.play(Assets.sound('confirm'));
		grpChars.members[1].playAnim("select");
		grpWeeks.members[curWeek].flashing = true;

		new FlxTimer().start(1.2, function(tmr:FlxTimer)
		{
			MusicBeat.stopMusic();
			MusicBeat.switchState(new states.LoadingState());
		});
	}

	public function changeWeek(change:Int = 0)
	{
		if (change != 0)
			FlxG.sound.play(Assets.sound('scroll'));

		var prevDiff = diff;
		curWeek += change;
		curWeek = FlxMath.wrap(curWeek, 0, weekList.length - 1);

		for (week in grpWeeks.members)
		{
			week.alpha = 0.4;
			if (week.ID == curWeek)
				week.alpha = 1;
		}

		for (char in grpChars.members)
		{
			char.visible = true;
			if (week.chars[char.ID] == "")
				char.visible = false;
			else if (week.chars[char.ID] != char.curChar)
				char.reloadChar(week.chars[char.ID]);
		}

		trackTxt.text = "";
		for (song in week.songs)
			trackTxt.text += song.song.toUpperCase() + '\n';
		trackTxt.x = 200 - (trackTxt.width / 2);

		weekNameTxt.text = week.weekName.toUpperCase();
		weekNameTxt.x = FlxG.width - weekNameTxt.width - 8;

		var newColor = SpriteUtil.getColor(week.storyColor);
		if (newColor != charBg.color)
		{
			FlxTween.cancelTweensOf(charBg);
			FlxTween.color(charBg, 0.4, charBg.color, newColor);
		}

		if (diff != prevDiff)
		{
			if (!week.storyDiffs.contains(prevDiff))
				curDiff = middleDiff;
			else
				curDiff = week.storyDiffs.indexOf(prevDiff);
		}

		changeDiff();
	}

	public function changeDiff(change:Int = 0)
	{
		if (change != 0)
			FlxG.sound.play(Assets.sound('scroll'));

		curDiff += change;
		curDiff = FlxMath.wrap(curDiff, 0, week.storyDiffs.length - 1);

		diffSelector.changeDiff(diff, curDiff, week.storyDiffs.length - 1, change);
		realScore = Highscore.getScore('week-${week.weekFile}-$diff').score;
	}

	var week(get, never):WeekData;
	var diff(get, never):String;
	var middleDiff(get, never):Int;

	function get_week():WeekData
		return weekList[curWeek] ?? Week.defaultWeek();

	function get_diff():String
		return week.storyDiffs[curDiff] ?? 'normal';

	function get_middleDiff()
		return Std.int((week.storyDiffs.length - 1) / 2);
}

enum StoryCharPos
{
	DAD;
	BF;
	GF;
}

// PLACEHOLDERS!!!!
class StoryChar extends Character
{
	public var position:StoryCharPos = BF;
	public var initialized:Bool = false;

	public function new(position:StoryCharPos)
	{
		super("", false);
		this.position = position;
		this.dataPath = "data/storychars/";
		this.spritePath = "menu/story/chars/";
		initialized = true;
	}

	public function reloadChar(curChar:String = "bf")
	{
		if (curChar == this.curChar)
			return;

		this.curChar = curChar;
		loadCharacter(false);
		updateHitbox();
	}

	override public function loadCharacter(reload:Bool = false)
	{
		if (initialized)
			super.loadCharacter(reload);
	}

	override function updateHitbox()
	{
		super.updateHitbox();

		x = switch (position)
		{
			case DAD:
				x = 100;
			case GF:
				x = FlxG.width - width - 100;
			default:
				x = FlxG.width / 2 - width / 2;
		};
		y = 50 + (392 / 2) - (height / 2);

		x += globalOffset.x;
		y += globalOffset.y;
	}
}

class WeekTitle extends FlxSprite
{
	public var flashing:Bool = false;
	public var weekFile:String;

	var colorCount:Float = 0;

	public function new(weekFile:String, index:Int, curWeek:Int)
	{
		super(0, 0);
		this.weekFile = weekFile;
		this.ID = index;
		this.loadImage('menu/story/week/$weekFile');

		screenCenter(X);
		y = 402 + 60 + (index - curWeek) * 120;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (flashing)
		{
			colorCount += elapsed;
			if (colorCount >= 0.05)
			{
				colorCount = 0;
				if (color == 0xFF00FFFF)
					color = 0xFFFFFFFF;
				else
					color = 0xFF00FFFF;
			}
		}
	}
}
