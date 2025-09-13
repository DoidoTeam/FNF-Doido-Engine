package states;

import backend.song.Conductor;
import backend.song.SongData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import objects.menu.Alphabet;
import states.menu.MainMenuState;

using StringTools;

class TitleState extends MusicBeatState
{
	var textGroup:FlxTypedGroup<Alphabet>;
	var curWacky:Array<String> = ['',''];
	var ngSpr:FlxSprite;
	
	var blackScreen:FlxSprite;
	var gf:FlxSprite;
	var logoBump:FlxSprite;
	
	var enterTxt:FlxSprite;
	
	static var introEnded:Bool = false;

	override function create()
	{
		super.create();
		if(!introEnded)
		{
			new FlxTimer().start(0.5, function(tmr:FlxTimer) {
				CoolUtil.playMusic("freakyMenu");
			});
			
			var allTexts:Array<String> = CoolUtil.parseTxt('introText');
			curWacky = allTexts[FlxG.random.int(0, allTexts.length - 1)].split('--');
		}
		
		DiscordIO.changePresence("In Title Screen");
		FlxG.mouse.visible = false;
		
		persistentUpdate = true;
		Conductor.setBPM(102);
		
		gf = new FlxSprite();
		gf.frames = Paths.getSparrowAtlas('menu/title/gfDanceTitle');
		gf.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gf.animation.addByIndices('danceRight','gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gf.x = FlxG.width - gf.width - 20;
		gf.screenCenter(Y);
		add(gf);
		gf.animation.play('danceLeft');
		
		logoBump = new FlxSprite(-100, -80);
		logoBump.frames = Paths.getSparrowAtlas('menu/title/logoBumpin');
		logoBump.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBump.animation.play('bump');
		add(logoBump);
		
		enterTxt = new FlxSprite(500 / 4);
		enterTxt.frames = Paths.getSparrowAtlas('menu/title/titleEnter');
		enterTxt.animation.addByPrefix('idle', 'Press Enter to Begin', 24, true);
		enterTxt.animation.addByPrefix('pressed', 'ENTER PRESSED', 24, true);
		enterTxt.animation.play('idle');
		enterTxt.y = FlxG.height - enterTxt.height - 60;
		add(enterTxt);
		
		blackScreen = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
		blackScreen.screenCenter();
		add(blackScreen);
		
		textGroup = new FlxTypedGroup<Alphabet>();
		add(textGroup);
		
		ngSpr = new FlxSprite().loadGraphic(Paths.image('menu/title/newgrounds_logo'));
		ngSpr.screenCenter();
		ngSpr.y = FlxG.height - ngSpr.height - 40;
		ngSpr.visible = false;
		add(ngSpr);

		addText([]);
		
		if(introEnded)
			skipIntro(true);
	}
	
	var pressedEnter:Bool = false;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(FlxG.sound.music != null)
			if(FlxG.sound.music.playing)
				Conductor.songPos = FlxG.sound.music.time;
		
		if(Controls.justPressed(ACCEPT))
		{
			if(introEnded)
			{
				if(!pressedEnter)
				{
					pressedEnter = true;
					enterTxt.animation.play('pressed');
					FlxG.sound.play(Paths.sound('menu/confirmMenu'));
					CoolUtil.flash(FlxG.camera, 1, 0xFFFFFFFF);
					new FlxTimer().start(2.0, function(tmr:FlxTimer)
					{
						Main.switchState(new MainMenuState());
					});
				}
			}
			else
				skipIntro();
		}
	}
	
	override function beatHit()
	{
		super.beatHit();
		if(!introEnded)
		{
			switch(curBeat)
			{
				case 1:
					addText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er'], true);
				case 3:
					addText(['present'], false);
				case 4:
					addText([]);
					
				case 5:
					addText(['Not associated', 'with']);
				case 7:
					addText(['newgrounds'], false);
					ngSpr.visible = true;
				case 8:
					addText([]);
					ngSpr.visible = false;
					
				case 9:
					addText([curWacky[0]]);
				case 11:
					addText([curWacky[1]], false);
				case 12:
					addText([]);
					addText(['Friday']);
				case 13:
					addText(['Night'], false);
				case 14:
					addText(['Funkin'], false);
				case 15:
					addText(['Doido Engine'], false);
				case 16:
					skipIntro();
			}
		}
		
		logoBump.animation.play('bump', true);
		
		if(gf.animation.curAnim.name == 'danceLeft')
			gf.animation.play('danceRight');
		else
			gf.animation.play('danceLeft');
	}
	
	public function skipIntro(force:Bool = false)
	{
		if(introEnded && !force) return;
		introEnded = true;
		
		if(FlxG.sound.music != null)
			FlxG.sound.music.time = (Conductor.crochet * 16);
		
		addText([]);
		ngSpr.visible = false;
		CoolUtil.flash(FlxG.camera, Conductor.crochet * 4 / 1000, 0xFFFFFFFF);
		remove(blackScreen);
	}
	
	public function addText(newText:Array<String>, clearTxt:Bool = true, mainY:Int = 130)
	{
		if(clearTxt) textGroup.clear();
		
		for(i in newText)
		{
			var item = new Alphabet(0, 0, i.toUpperCase(), true);
			item.align = CENTER;
			item.x = FlxG.width / 2;
			item.y = mainY + item.boxHeight * textGroup.members.length;
			item.updateHitbox();
			textGroup.add(item);
		}
	}
}
