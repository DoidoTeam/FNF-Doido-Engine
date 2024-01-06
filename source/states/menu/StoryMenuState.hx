package states.menu;

import data.Discord.DiscordClient;
import subStates.DeleteScoreSubState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import data.GameData.MusicBeatState;
import data.Highscore;
import data.SongData;
import gameObjects.menu.Alphabet;

typedef WeekData =
{
	var fileName:String;
	var weekName:String;
	var songList:Array<String>;
	var dad:String;
	var bf:String;
	var gf:String;
}
class StoryMenuState extends MusicBeatState
{
	var weekList:Array<WeekData> = [];
	
	public function addWeek(fileName:String, weekName:String, songList:Array<String>, dad:String="", bf:String="", gf:String="")
	{
		weekList.push({
			fileName: fileName,
			weekName: weekName,
			songList: songList,
			dad: dad, bf: bf, gf: gf,
		});
	}
	
	static var curWeek:Int = 0;
	static var curDiff:String = "";
	static var diffInt:Int = 1;
	
	var grpChars:FlxTypedGroup<StoryChar>;
	var grpWeeks:FlxTypedGroup<FlxSprite>;
	var diffSelector:DiffSelector;
	
	// intended score // display score
	var scoreCount:Array<Float> = [0,0];
	
	var trackTxt:FlxText;
	var weekNameTxt:FlxText;
	var weekScoreTxt:FlxText;
	var resetTxt:FlxText;
	
	override function create()
	{
		super.create();
		preloadAssets();
		CoolUtil.playMusic("freakyMenu");
		DiscordClient.changePresence("Story Mode - Choosin' a week", null);
		addWeek(
			"tutorial",
			"funky beginnings",
			["tutorial"],
			"", "bf", "gf"
		);
		addWeek(
			"week1",
			"daddy dearest",
			["bopeebo", "fresh", "dadbattle"],
			"dad", "bf", "gf"
		);
		addWeek(
			"week6",
			"hating simulator (ft. moawling)",
			["senpai", "roses", "thorns"],
			"senpai", "bf", "gf"
		);
		
		grpWeeks = new FlxTypedGroup<FlxSprite>();
		add(grpWeeks);
		
		for(i in 0...weekList.length)
		{
			var weekSpr = new FlxSprite().loadGraphic(Paths.image('menu/story/week/${weekList[i].fileName}'));
			weekSpr.ID = i;
			weekSpr.screenCenter(X);
			grpWeeks.add(weekSpr);
		}
		updateWeekPos(1);
		
		var blackMf = new FlxSprite(0, 0).makeGraphic(FlxG.width * 2, 60, 0xFF000000);
		blackMf.screenCenter(X);
		add(blackMf);
		var yellowMf = new FlxSprite(0, 50).makeGraphic(FlxG.width * 2, 392, 0xFFF9CF51);
		yellowMf.screenCenter(X);
		add(yellowMf);
		
		resetTxt = new FlxText(0,0,0,"PRESS RESET TO DELETE WEEK SCORE");
		resetTxt.setFormat(Main.gFont, 18, 0xFFFFFFFF, LEFT);
		resetTxt.x = FlxG.width - resetTxt.width - 8;
		resetTxt.y = FlxG.height - resetTxt.height - 8;
		resetTxt.alpha = 0.8;
		add(resetTxt);
		
		weekScoreTxt = new FlxText(8, 8, 0,"");
		weekScoreTxt.setFormat(Main.gFont, 36, 0xFFFFFFFF, LEFT);
		add(weekScoreTxt);
		
		weekNameTxt = new FlxText(8, 8, 0,"");
		weekNameTxt.setFormat(Main.gFont, 36, 0xFFFFFFFF, RIGHT);
		weekNameTxt.alpha = 0.8;
		add(weekNameTxt);
		
		var trackTitle = new FlxText(0,0,0,"TRACKS");
		trackTitle.setFormat(Main.gFont, 48, 0xFFFC3EAA, CENTER);
		trackTitle.setPosition(200 - trackTitle.width / 2, yellowMf.y + yellowMf.height + 20);
		add(trackTitle);
		
		trackTxt = new FlxText(0,0,0,"what the hell");
		trackTxt.setFormat(Main.gFont, 36, 0xFFFC3EAA, CENTER);
		trackTxt.y = (trackTitle.y + trackTitle.height + 12);
		add(trackTxt);
		
		diffSelector = new DiffSelector();
		diffSelector.diffPos.y = yellowMf.y + yellowMf.height + 30; // 20
		diffSelector.diffPos.x = (FlxG.width - 200);
		diffSelector.updateHitbox();
		add(diffSelector);
		
		grpChars = new FlxTypedGroup<StoryChar>();
		add(grpChars);
		
		for(i in 0...3)
		{
			var char = new StoryChar();
			char.ID = i;
			grpChars.add(char);
		}
		
		changeWeek();
	}
		
	var canSelect:Bool = true;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(canSelect)
		{
			if(Controls.justPressed("BACK"))
			{
				canSelect = false;
				FlxG.sound.play(Paths.sound('menu/cancelMenu'));
				Main.switchState(new MainMenuState());
			}
			
			if(Controls.justPressed("ACCEPT"))
			{
				canSelect = false;
				FlxG.sound.play(Paths.sound('menu/confirmMenu'));
				grpChars.members[1].playAnim("select");
				
				// FLICK FLICK
				var colorCount:Float = 0;
				var weekSpr = grpWeeks.members[curWeek];
				weekSpr._update = function(elapsed:Float)
				{
					colorCount += elapsed;
					if(colorCount >= 0.05)
					{
						colorCount = 0;
						if(weekSpr.color == 0xFF00FFFF)
							weekSpr.color = 0xFFFFFFFF;
						else
							weekSpr.color = 0xFF00FFFF;
					}
				}
				
				new FlxTimer().start(1.9, function(tmr:FlxTimer)
				{
					//Main.switchState(new states.MenuState());
					var daWeek = weekList[curWeek];
					
					PlayState.curWeek = daWeek.fileName;
					PlayState.songDiff = curDiff;
					PlayState.isStoryMode = true;
					PlayState.weekScore = 0;
					
					PlayState.SONG = SongData.loadFromJson(daWeek.songList[0], curDiff);
					PlayState.playList = daWeek.songList;
					PlayState.playList.remove(daWeek.songList[0]);
					
					//CoolUtil.playMusic();
					//Main.switchState(new PlayState());
					Main.switchState(new LoadSongState());
				});
			}
			
			if(Controls.justPressed("UI_UP"))
				changeWeek(-1);
			if(Controls.justPressed("UI_DOWN"))
				changeWeek(1);
			if(Controls.justPressed("UI_LEFT"))
				changeDiff(-1);
			if(Controls.justPressed("UI_RIGHT"))
				changeDiff(1);
			
			if(Controls.justPressed("RESET"))
			{
				var displayName:String = weekList[curWeek].fileName;
				openSubState(new DeleteScoreSubState('week-' + displayName, curDiff, displayName));
			}
			
			var animL:String = "idle";
			if(Controls.pressed("UI_LEFT"))
				animL = "push";
			
			var animR:String = "idle";
			if(Controls.pressed("UI_RIGHT"))
				animR = "push";
			
			diffSelector.arrowL.animation.play(animL);
			diffSelector.arrowR.animation.play(animR);
		}
		updateWeekPos(elapsed * 12);

		if(DeleteScoreSubState.deletedScore)
		{
			DeleteScoreSubState.deletedScore = false;
			changeWeek();
		}
		
		scoreCount[1] = FlxMath.lerp(scoreCount[1], scoreCount[0], elapsed * 16);
		if(Math.abs(scoreCount[1] - scoreCount[0]) <= 0.4)
			scoreCount[1] = scoreCount[0];
		
		weekScoreTxt.text = "WEEK SCORE: " + Math.floor(scoreCount[1]);
	}
	
	public function updateWeekPos(lerp:Float = 0)
	{
		for(week in grpWeeks.members)
		{
			week.y = FlxMath.lerp(week.y, 402 + 60 + (week.ID - curWeek) * 120, lerp);
		}
	}
	
	public function changeWeek(change:Int = 0)
	{
		if(change != 0)
			FlxG.sound.play(Paths.sound('menu/scrollMenu'));
	
		curWeek += change;
		curWeek = FlxMath.wrap(curWeek, 0, weekList.length - 1);
		
		for(week in grpWeeks.members)
		{
			week.alpha = 0.4;
			if(week.ID == curWeek)
				week.alpha = 1;
		}
		
		var daWeek = weekList[curWeek];
		for(char in grpChars.members)
		{
			char.visible = true;
			if(char.ID == 0)
			{
				if(daWeek.dad == "")
					char.visible = false;
				else if(daWeek.dad != char.curChar)
					char.reloadChar(daWeek.dad, "dad");
			}
			if(char.ID == 1)
			{
				if(daWeek.bf == "")
					char.visible = false;
				else if(daWeek.bf != char.curChar)
					char.reloadChar(daWeek.bf, "bf");
			}
			if(char.ID == 2)
			{
				if(daWeek.gf == "")
					char.visible = false;
				else if(daWeek.gf != char.curChar)
					char.reloadChar(daWeek.gf, "gf");
			}
		}
		
		trackTxt.text = "";
		for(song in daWeek.songList)
			trackTxt.text += song.toUpperCase() + '\n';
		trackTxt.x = 200 - (trackTxt.width / 2);
		
		weekNameTxt.text = weekList[curWeek].weekName.toUpperCase();
		weekNameTxt.x = FlxG.width - weekNameTxt.width - 8;
		changeDiff();
	}
	public function changeDiff(change:Int = 0)
	{
		if(change != 0)
			FlxG.sound.play(Paths.sound('menu/scrollMenu'));
		
		diffInt += change;
		diffInt = FlxMath.wrap(diffInt, 0, 2);
		
		curDiff = CoolUtil.getDiffs()[diffInt];
		
		// scoreCount[0] += FlxG.random.int(0, 2546688);
		// updates the score
		scoreCount[0] = Highscore.getScore('week-' + weekList[curWeek].fileName + '-' + curDiff).score;
		
		diffSelector.changeDiff(curDiff);
	}
	
	public function preloadAssets()
	{
		function doShit(daFile:String)
		{
			var path:String = 'menu/story/$daFile/';
			for(item in Paths.readDir('images/' + path,  ".png"))
				Paths.preloadGraphic(path + item);
		}
		
		// every folder of assets it should preload
		doShit("diff");
		doShit("chars");
	}
}
// i want to kms after this
class StoryChar extends FlxSprite
{
	public function new()
	{
		super();
	}
	
	public var curChar:String = "";
	
	public var globalOffset:FlxPoint = new FlxPoint();
	private var scaleOffset:FlxPoint = new FlxPoint();
	
	public function reloadChar(char:String, pos:String):StoryChar
	{
		curChar = char;
		frames = Paths.getSparrowAtlas("menu/story/chars/" + char);
		
		globalOffset.set();
		scaleOffset.set();
		scale.set(1,1);
		flipX = false;
		animOffsets = [];
		
		switch(char)
		{
			case "senpai":
				animation.addByPrefix("idle", "idle", 24, true);
				globalOffset.x -= 35;
				
			case "dad":
				animation.addByPrefix("idle", "idle", 24, true);
				scale.set(0.45,0.45);
				globalOffset.x += 45;
			
			case "gf":
				animation.addByPrefix("idle", "dance", 24, true);
				scale.set(0.48,0.48);
				globalOffset.y -= 20;
			
			case "bf":
				animation.addByPrefix("idle", "idle", 24, true);
				animation.addByPrefix("select", "hey", 24, false);
				scale.set(0.8,0.8);
				flipX = true;
				
				addOffset("select", 1, 5);
			
			default:
				return reloadChar("bf", pos);
		}
		updateHitbox();
		scaleOffset.set(offset.x, offset.y);
		playAnim("idle");
		
		y = 420 - height;
		
		switch(pos.toLowerCase())
		{
			case "dad":
				x = 100;
			case "gf":
				x = FlxG.width - width - 100;
			default:
				x = FlxG.width / 2 - width / 2;
		}
		// 0.8 bf
		// 0.48 others
		if(pos == "bf")
			flipX = !flipX;
		
		x += globalOffset.x;
		y += globalOffset.y;
		
		return this;
	}
	
	// animation handler
	public var animOffsets:Map<String, Array<Float>> = [];

	public function addOffset(animName:String, offX:Float = 0, offY:Float = 0):Void
		return animOffsets.set(animName, [offX, offY]);

	public function playAnim(animName:String)
	{
		animation.play(animName, true, false, 0);

		try
		{
			var daOffset = animOffsets.get(animName);
			offset.set(daOffset[0] * scale.x, daOffset[1] * scale.y);
		}
		catch(e)
			offset.set(0,0);

		offset.x += scaleOffset.x;
		offset.y += scaleOffset.y;
	}
}
// nvm i was just sleepy
class DiffSelector extends FlxGroup
{
	public var arrowL:FlxSprite;
	public var diffSpr:FlxSprite;
	public var arrowR:FlxSprite;
	
	public var diffPos:FlxPoint = new FlxPoint();
	
	public function new()
	{
		super();
		arrowL = new FlxSprite();
		arrowL.frames = Paths.getSparrowAtlas("menu/menuArrows");
		arrowL.animation.addByPrefix("idle", "arrow left", 0, false);
		arrowL.animation.addByPrefix("push", "arrow push left", 0, false);
		arrowL.scale.set(0.8,0.8); arrowL.updateHitbox();
		arrowL.animation.play("idle");

		arrowR = new FlxSprite();
		arrowR.frames = Paths.getSparrowAtlas("menu/menuArrows");
		arrowR.animation.addByPrefix("idle", "arrow right", 0, false);
		arrowR.animation.addByPrefix("push", "arrow push right", 0, false);
		arrowR.scale.set(0.8,0.8); arrowR.updateHitbox();
		arrowR.animation.play("idle");
		
		add(arrowL);
		add(arrowR);
		
		diffSpr = new FlxSprite();
		add(diffSpr);
		
		changeDiff();
	}
	
	public var curDiff:String = "";
	var tweenShit:FlxTween;
	
	public function changeDiff(diff:String = "")
	{
		if(curDiff == diff) return;
		curDiff = diff;
		
		remove(diffSpr);
		
		diffSpr.loadGraphic(Paths.image("menu/story/diff/" + diff.toLowerCase()));
		
		add(diffSpr);
		updateHitbox();
		
		if(tweenShit != null) tweenShit.cancel();
		
		// lol
		diffSpr.y -= 20;
		diffSpr.alpha = 0;
		tweenShit = FlxTween.tween(diffSpr, {y: diffSpr.y + 20, alpha: 1}, 0.25, {ease: FlxEase.cubeOut});
	}
	
	public function updateHitbox()
	{
		diffSpr.y = diffPos.y;
		diffSpr.x = (diffPos.x - (diffSpr.width / 2));
		arrowL.x = diffSpr.x - arrowL.width  - 2;
		arrowR.x = diffSpr.x + diffSpr.width + 2;
		
		// align it
		arrowL.y = (diffSpr.y + diffSpr.height / 2 - arrowL.height / 2);
		arrowR.y = arrowL.y;
	}
}